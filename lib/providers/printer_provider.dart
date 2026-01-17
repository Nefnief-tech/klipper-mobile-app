import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:home_widget/home_widget.dart';
import '../models/printer.dart';
import '../services/database_helper.dart';
import '../services/notification_service.dart';

class PrinterProvider with ChangeNotifier {
  List<Printer> _printers = [];
  List<Printer> get printers {
    final List<Printer> sorted = List.from(_printers);
    final score = {'error': 0, 'printing': 1, 'paused': 2, 'idle': 3, 'offline': 4};
    sorted.sort((a, b) => (score[a.status] ?? 5).compareTo(score[b.status] ?? 5));
    return sorted;
  }
  
  final Map<String, WebSocketChannel> _channels = {};
  final Map<String, StreamSubscription> _subscriptions = {};
  final Map<String, DateTime> _lastNotificationUpdate = {};
  Timer? _pollingTimer;
  bool _isPaused = false;
  String? _spoolmanUrl;
  String? get spoolmanUrl => _spoolmanUrl;
  String _themeMode = 'dark';
  String get themeMode => _themeMode;

  String _baseUrl(String ip) {
    String url = ip.trim();
    if (!url.startsWith('http')) url = 'http://$url';
    if (url.endsWith('/')) url = url.substring(0, url.length - 1);
    return url;
  }

  Future<void> init() async {
    disconnectAll();

    _spoolmanUrl = await DatabaseHelper.instance.getSetting('spoolman_url');
    _themeMode = await DatabaseHelper.instance.getSetting('theme_mode') ?? 'dark';
    final saved = await DatabaseHelper.instance.fetchPrinters();
    _printers = saved.map((p) => Printer(id: p['id'], name: p['name'], ip: p['ip'])).toList();
    notifyListeners();
    reconnectAll();
    
    // Start background polling for AFC and status updates every 20 seconds
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 20), (timer) {
      if (!_isPaused) {
        for (var p in _printers) {
          if (p.status != 'offline') refreshPrinter(p.id);
        }
      }
    });
  }

  void disconnectAll() {
    for (var s in _subscriptions.values) { s.cancel(); }
    for (var c in _channels.values) { c.sink.close(); }
    _subscriptions.clear();
    _channels.clear();
    _pollingTimer?.cancel();
  }

  void reconnectAll() {
    if (_isPaused) return;
    for (var p in _printers) { connectWebSocket(p.id); }
    if (_pollingTimer == null || !_pollingTimer!.isActive) init();
  }

  void pause() {
    _isPaused = true;
    disconnectAll();
    debugPrint("App paused: WebSockets disconnected");
  }

  void resume() {
    _isPaused = false;
    debugPrint("App resumed: Reconnecting WebSockets...");
    reconnectAll();
  }

  @override
  void dispose() {
    disconnectAll();
    _pollingTimer?.cancel();
    super.dispose();
  }

  void connectWebSocket(String printerId) {
    if (_isPaused) return;
    final index = _printers.indexWhere((p) => p.id == printerId);
    if (index == -1) return;
    final printer = _printers[index];
    final wsUrl = 'ws://${printer.ip.replaceAll('http://', '').replaceAll('https://', '')}/websocket';
    
    runZonedGuarded(() {
      final channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      
      final sub = channel.stream.listen(
        (msg) => _handleWsMessage(printerId, msg), 
        onDone: () {
          debugPrint("WS Done for $printerId");
          _reconnect(printerId);
        }, 
        onError: (e) {
          debugPrint("WS Error for $printerId: $e");
          _reconnect(printerId);
        },
        cancelOnError: true,
      );

      _channels[printerId] = channel;
      _subscriptions[printerId] = sub;

      _sendSubscription(printerId);
      refreshPrinter(printerId);
    }, (error, stack) {
      if (_isPaused) return;
      debugPrint("Caught Async WS Error for $printerId: $error");
      _reconnect(printerId);
    });
  }

  void _sendSubscription(String printerId) {
    final channel = _channels[printerId];
    if (channel == null) return;

    final printer = _printers.firstWhere((p) => p.id == printerId);
    
    // Start with base objects
    final Map<String, dynamic> objects = {
      "print_stats": null, 
      "display_status": null, 
      "heater_bed": null, 
      "extruder": null, 
      "virtual_sdcard": null, 
      "exclude_object": null,
      "fan": null,
      "spoolman": null,
      "AFC": null
    };

    // Add specifically discovered devices so we get real-time updates for them
    for (var device in printer.devices) {
      if (device.type == 'fan_generic') {
        objects['fan_generic ${device.name}'] = null;
      } else if (device.type == 'output_pin') {
        objects['output_pin ${device.name}'] = null;
      } else if (device.type == 'led') {
        // We check for both common LED types in Klipper
        objects['led ${device.name}'] = null;
        objects['neopixel ${device.name}'] = null;
      }
    }

    final subscribeMsg = {
      "jsonrpc": "2.0", "method": "printer.objects.subscribe",
      "params": {"objects": objects},
      "id": DateTime.now().millisecondsSinceEpoch
    };
    channel.sink.add(jsonEncode(subscribeMsg));
  }

  void _reconnect(String id) {
    if (_channels.containsKey(id) || _isPaused) return; // Already connected, connecting, or paused
    Future.delayed(const Duration(seconds: 10), () {
      if (!_isPaused && _printers.any((p) => p.id == id) && !_channels.containsKey(id)) {
        connectWebSocket(id);
      }
    });
  }

  void _handleWsMessage(String printerId, String message) {
    final data = jsonDecode(message);
    final index = _printers.indexWhere((p) => p.id == printerId);
    if (index == -1) return;
    final printer = _printers[index];
    final oldStatus = printer.status;

    if (data['method'] == 'notify_gcode_response') {
      final log = data['params'][0].toString();
      final newLogs = List<String>.from(printer.terminalLogs)..add(log);
      if (newLogs.length > 100) newLogs.removeAt(0);
      _printers[index] = printer.copyWith(terminalLogs: newLogs);
      notifyListeners();
      return;
    }

    if (data['method'] == 'notify_spoolman_active_spool') {
      final spoolData = data['params']?[0]?['spool'];
      final index = _printers.indexWhere((p) => p.id == printerId);
      if (index != -1) {
        final filament = spoolData?['filament'] ?? {};
        _printers[index] = _printers[index].copyWith(
          currentSpool: spoolData != null ? Spool(
            id: spoolData['id'],
            name: filament['name'] ?? spoolData['name'] ?? 'Unknown',
            material: filament['material'] ?? spoolData['material']?['name'] ?? spoolData['material'] ?? 'Unknown',
            vendor: filament['vendor']?['name'] ?? spoolData['vendor']?['name'] ?? 'Unknown',
            remainingWeight: (spoolData['remaining_weight'] ?? 0).toDouble(),
            color: filament['color_hex'] ?? spoolData['color_hex'],
          ) : null,
        );
        notifyListeners();
      }
      return;
    }

    Map<String, dynamic>? update;
    if (data['method'] == 'notify_status_update') update = data['params'][0];
    else if (data['result'] != null && data['result']['status'] != null) update = data['result']['status'];

    if (update != null) {
      String? status = printer.status;
      if (update['print_stats'] != null && update['print_stats']['state'] != null) {
        final s = update['print_stats']['state'];
        status = (s == 'shutdown' || s == 'disconnected') ? 'error' : s;
        if (status != oldStatus) {
          debugPrint("Printer ${printer.name} status transition: $oldStatus -> $status");
        }
      }

      final currentProgress = ((update['display_status']?['progress'] ?? update['virtual_sdcard']?['progress'] ?? (printer.progress/100)) * 100).round();
      
      double nozzle = update['extruder']?['temperature']?.toDouble() ?? printer.nozzleTemp;
      double bed = update['heater_bed']?['temperature']?.toDouble() ?? printer.bedTemp;

      // Notification Logic
      if (oldStatus != 'printing' && status == 'printing') {
        debugPrint("Triggering START notification for ${printer.name}");
        NotificationService.showNotification(
          id: printer.id.hashCode,
          title: 'Print Started',
          body: '${printer.name}: Now printing ${update['print_stats']?['filename'] ?? printer.currentFile ?? "model"}.',
        );
      } else if (oldStatus == 'printing' && status == 'paused') {
        debugPrint("Triggering PAUSE notification for ${printer.name}");
        NotificationService.showNotification(
          id: printer.id.hashCode,
          title: 'Print Paused',
          body: '${printer.name}: The current print job has been paused.',
        );
      } else if (oldStatus == 'printing' && status == 'complete') {
        debugPrint("Triggering COMPLETE notification for ${printer.name}");
        NotificationService.showNotification(
          id: printer.id.hashCode,
          title: 'Print Complete!',
          body: '${printer.name}: ${printer.currentFile ?? "Your model"} is ready.',
        );
      } else if (oldStatus != 'error' && status == 'error') {
        debugPrint("Triggering ERROR notification for ${printer.name}");
        NotificationService.showNotification(
          id: printer.id.hashCode,
          title: 'Printer Error!',
          body: '${printer.name} has encountered an error or disconnected.',
        );
      } else if (status == 'printing') {
        // Live Progress Update (Throttled to every 5 seconds)
        final now = DateTime.now();
        final lastUpdate = _lastNotificationUpdate[printerId];
        if (lastUpdate == null || now.difference(lastUpdate).inSeconds >= 5) {
          debugPrint("Triggering PROGRESS notification for ${printer.name}: $currentProgress%");
          _lastNotificationUpdate[printerId] = now;
          NotificationService.showNotification(
            id: printer.id.hashCode,
            title: 'Printing: ${printer.name}',
            body: '$currentProgress% - ${update['print_stats']?['filename'] ?? printer.currentFile ?? "Unknown File"}',
            progress: currentProgress,
            maxProgress: 100,
            nozzleTemp: nozzle,
            bedTemp: bed,
          );
        }
      } else if (oldStatus == 'printing' && status != 'printing' && status != 'complete' && status != 'paused') {
        debugPrint("Canceling PROGRESS notification and triggering STOP for ${printer.name} (Status: $status)");
        NotificationService.cancelNotification(printer.id.hashCode);
        NotificationService.showNotification(
          id: printer.id.hashCode + 1, // Different ID so it doesn't get canceled immediately
          title: 'Print Stopped',
          body: '${printer.name}: The print job has been stopped or cancelled.',
        );
      }

      ExcludeObject? ex;
      if (update['exclude_object'] != null) {
        final raw = update['exclude_object'];
        ex = ExcludeObject(
          objects: (raw['objects'] as List?)?.map((o) => o['name'].toString()).toList() ?? printer.excludeObject?.objects ?? [],
          excluded: (raw['excluded_objects'] as List?)?.map((o) => o.toString()).toList() ?? printer.excludeObject?.excluded ?? [],
          current: raw['current_object'] ?? printer.excludeObject?.current,
        );
      }

      List<TempPoint> history = List.from(printer.history);
      if (update['extruder'] != null || update['heater_bed'] != null) {
        history.add(TempPoint(time: DateTime.now(), nozzle: nozzle, bed: bed));
        if (history.length > 60) history.removeAt(0);
      }

      _printers[index] = printer.copyWith(
        status: status,
        progress: currentProgress,
        nozzleTemp: nozzle,
        targetNozzle: update['extruder']?['target']?.toDouble() ?? printer.targetNozzle,
        bedTemp: bed,
        targetBed: update['heater_bed']?['target']?.toDouble() ?? printer.targetBed,
        currentFile: (update['print_stats'] != null && update['print_stats']['filename'] != null) 
            ? update['print_stats']['filename'] 
            : printer.currentFile,
        excludeObject: ex,
        history: history,
        devices: _parseDevices(update, printer.devices),
        afc: _parseAfc(update, printer.afc),
      );
      _updateWidget();
      notifyListeners();
    }
  }

  void _updateWidget() {
    try {
      final printing = _printers.where((p) => p.status == 'printing').length;
      final idle = _printers.where((p) => p.status == 'idle').length;

      HomeWidget.saveWidgetData<int>('printing_count', printing);
      HomeWidget.saveWidgetData<int>('idle_count', idle);
      HomeWidget.updateWidget(
        androidName: 'StatusWidgetProvider',
      );
    } catch (_) {}
  }

  AFC? _parseAfc(Map<String, dynamic> update, AFC? current) {
    final rawAfc = update['afc'] ?? update['AFC'];
    if (rawAfc == null || rawAfc is! Map) return current;

    debugPrint("[AFC] raw: ${jsonEncode(rawAfc)}");

    List<AFCLane> lanes = [];
    String? activeLaneName;
    String overallStatus = current?.status ?? 'Unknown';

    // 1. Attempt to find active lane info (often at root or in system)
    if (rawAfc['system'] is Map) {
      final systemData = rawAfc['system'];
      activeLaneName = systemData['current_load'] as String?;
      if (systemData['buffers'] is Map && systemData['buffers'].isNotEmpty) {
        final firstBufferKey = systemData['buffers'].keys.first;
        final firstBuffer = systemData['buffers'][firstBufferKey];
        if (firstBuffer is Map && firstBuffer['state'] != null) {
          overallStatus = firstBuffer['state'].toString();
        }
      }
    }
    if (activeLaneName == null && rawAfc.containsKey('current_load')) {
       activeLaneName = rawAfc['current_load']?.toString();
    }
    
    // 2. Identify the container having the lanes data
    Map<String, dynamic> dataContainer = Map<String, dynamic>.from(rawAfc);
    if (rawAfc.containsKey('status:') && rawAfc['status:'] is Map) {
         final statusMap = rawAfc['status:'] as Map<String, dynamic>;
         if (statusMap.containsKey('AFC') && statusMap['AFC'] is Map) {
             dataContainer = statusMap['AFC'];
         }
    } else if (rawAfc.containsKey('AFC') && rawAfc['AFC'] is Map) {
         dataContainer = rawAfc['AFC'];
    }

    // 3. Find the unit (e.g., "Turtle_1") that contains the lanes.
    String? unitKey;
    for (final key in dataContainer.keys) {
      if (dataContainer[key] is Map && (dataContainer[key] as Map).containsKey('lane1')) {
        unitKey = key;
        break;
      }
    }

    if (unitKey != null) {
      final unitData = dataContainer[unitKey] as Map<String, dynamic>;
      // Iterate through the keys of the unit to find lanes
      unitData.forEach((key, value) {
        if (key.startsWith('lane') && value is Map && value.containsKey('lane')) {
          lanes.add(AFCLane(
            id: (value['lane'] is int) ? value['lane'] : int.tryParse(value['lane'].toString()) ?? -1,
            status: value['status']?.toString() ?? 'unknown',
            material: value['material']?.toString(),
            color: value['color']?.toString(),
            name: value['name']?.toString() ?? key,
          ));
        }
      });
    } else {
       // Fallback: Check if lanes are at the root level of dataContainer
       dataContainer.forEach((key, value) {
        if (key.startsWith('lane') && value is Map && value.containsKey('lane')) {
          lanes.add(AFCLane(
            id: (value['lane'] is int) ? value['lane'] : int.tryParse(value['lane'].toString()) ?? -1,
            status: value['status']?.toString() ?? 'unknown',
            material: value['material']?.toString(),
            color: value['color']?.toString(),
            name: value['name']?.toString() ?? key,
          ));
        }
      });
    }

    // Convert active lane name to ID
    int? activeLaneId;
    if (activeLaneName != null) {
      // The sample output is "lane4", so we search by name.
      final matchingLane = lanes.firstWhere((l) => l.name == activeLaneName, orElse: () => AFCLane(id: -1, status: ''));
      if (matchingLane.id != -1) {
        activeLaneId = matchingLane.id;
      }
    }

    // Sort lanes by ID for consistent UI
    if (lanes.isNotEmpty) {
      lanes.sort((a, b) => a.id.compareTo(b.id));
    } else if (current != null) {
      lanes = List.from(current.lanes);
    }

    if (activeLaneId == null && current != null) {
      activeLaneId = current.activeLane;
    }

    return AFC(
      lanes: lanes,
      activeLane: activeLaneId,
      status: overallStatus,
    );
  }

  List<KlipperDevice> _parseDevices(Map<String, dynamic> update, List<KlipperDevice> current) {
    final List<KlipperDevice> next = List.from(current);
    
    update.forEach((key, val) {
      if (val is! Map) return;
      String? type;
      if (key == 'fan') type = 'fan';
      else if (key.startsWith('fan_generic ')) type = 'fan_generic';
      else if (key.startsWith('output_pin ')) type = 'output_pin';
      else if (key.startsWith('led ')) type = 'led';
      else if (key.startsWith('neopixel ')) type = 'led';

      if (type != null) {
        final name = key.contains(' ') ? key.split(' ')[1] : key;
        final idx = next.indexWhere((d) => d.name == name);
        
        // Klipper uses 'value' for output_pin and 'speed' for fans/leds
        // For neopixels, we check color_data
        double? speed;
        if (val['speed'] != null) speed = val['speed'].toDouble();
        else if (val['value'] != null) speed = val['value'].toDouble();
        else if (val['color_data'] != null && val['color_data'] is List) {
          // Average of RGB for the first pixel as a proxy for brightness
          final colors = val['color_data'][0] as List;
          speed = (colors[0] + colors[1] + colors[2]) / 3.0;
        }
        
        if (idx != -1) {
          next[idx] = KlipperDevice(
            name: name, 
            type: type, 
            value: speed ?? next[idx].value
          );
        } else if (speed != null) {
          next.add(KlipperDevice(name: name, type: type, value: speed));
        }
      }
    });
    return next;
  }

  Future<void> refreshPrinter(String id) async {
    final i = _printers.indexWhere((p) => p.id == id);
    if (i == -1) return;
    final printer = _printers[i];
    final baseUrl = _baseUrl(printer.ip);
    try {
      final results = await Future.wait([
        http.get(Uri.parse('$baseUrl/printer/objects/query?print_stats&display_status&heater_bed&extruder&virtual_sdcard&exclude_object&AFC')),
        http.get(Uri.parse('$baseUrl/server/files/list?root=gcodes')),
        http.get(Uri.parse('$baseUrl/printer/objects/list')),
        http.get(Uri.parse('$baseUrl/server/spoolman/active_spool')).timeout(const Duration(seconds: 5), onTimeout: () => http.Response('{"error": "timeout"}', 408)),
        http.get(Uri.parse('$baseUrl/printer/afc/status')).timeout(const Duration(seconds: 5), onTimeout: () => http.Response('{"error": "timeout"}', 408)),
      ]);

      if (results[0].statusCode == 200) {
        final data = jsonDecode(results[0].body)['result']['status'];
        final stats = data['print_stats'];
        final exRaw = data['exclude_object'];
        
        // Process AFC from dedicated endpoint if available
        if (results[4].statusCode == 200) {
          try {
            final afcRes = jsonDecode(results[4].body);
            if (afcRes['result'] != null) {
              // Merge status data into object data to preserve lane details
              if (data['AFC'] != null && data['AFC'] is Map) {
                (data['AFC'] as Map).addAll(afcRes['result']);
              } else {
                data['AFC'] = afcRes['result'];
              }
            }
          } catch (_) {}
        }
        
        // Process Spoolman
        Spool? activeSpool;
        if (results[3].statusCode == 200) {
          try {
            final spoolData = jsonDecode(results[3].body)['result']['spool'];
            if (spoolData != null) {
              activeSpool = Spool(
                id: spoolData['id'],
                name: spoolData['name'] ?? 'Unknown',
                material: spoolData['material'] ?? 'Unknown',
                vendor: spoolData['vendor']?['name'] ?? 'Unknown',
                remainingWeight: (spoolData['remaining_weight'] ?? 0).toDouble(),
                color: spoolData['color_hex'],
              );
            }
          } catch (_) {}
        }

        // Process Macros and find device names
        List<String> macros = [];
        Map<String, dynamic> fullObjectStates = Map.from(data);

        if (results[2].statusCode == 200) {
          final allObjects = jsonDecode(results[2].body)['result']['objects'] as List;
          
          macros = allObjects
              .where((obj) => obj.toString().startsWith('gcode_macro '))
              .map((obj) => obj.toString().replaceFirst('gcode_macro ', ''))
              .toList();

          // We need to specifically query the state of all discovered device objects
          final deviceObjects = allObjects.where((obj) {
            final s = obj.toString();
            return s.startsWith('fan_generic ') || s.startsWith('output_pin ') || s.startsWith('led ') || s.startsWith('neopixel ') || s == 'fan';
          }).toList();

          if (deviceObjects.isNotEmpty) {
            final queryUrl = '$baseUrl/printer/objects/query?${deviceObjects.join('&')}';
            final deviceRes = await http.get(Uri.parse(queryUrl));
            if (deviceRes.statusCode == 200) {
              final deviceData = jsonDecode(deviceRes.body)['result']['status'];
              fullObjectStates.addAll(deviceData);
            }
          }
        }

        // Process Files
        List<GCodeFile> files = [];
        if (results[1].statusCode == 200) {
          final filesData = jsonDecode(results[1].body)['result'] as List;
          final rawFiles = filesData.map((f) => {
            'name': f['path'], 
            'size': f['size'],
            'modified': (f['modified'] as num).toDouble(),
          }).toList()..sort((a, b) => (b['modified'] as double).compareTo(a['modified'] as double));

          // Fetch thumbnails for top 15 files
          final topFiles = rawFiles.take(15).toList();
          for (var f in topFiles) {
            String? fileThumb;
            try {
              final mRes = await http.get(Uri.parse('$baseUrl/server/files/metadata?filename=${Uri.encodeComponent(f['name'] as String)}')).timeout(const Duration(milliseconds: 500));
              if (mRes.statusCode == 200) {
                final mData = jsonDecode(mRes.body)['result'];
                if (mData['thumbnails'] != null && (mData['thumbnails'] as List).isNotEmpty) {
                  fileThumb = '$baseUrl/server/files/gcodes/${mData['thumbnails'].last['relative_path']}';
                }
              }
            } catch (_) {}
            files.add(GCodeFile(
              name: f['name'] as String,
              size: f['size'] as int,
              modified: f['modified'] as double,
              thumbnailUrl: fileThumb,
            ));
          }
          // Add remaining files without thumbs to avoid overhead
          if (rawFiles.length > 15) {
            files.addAll(rawFiles.skip(15).map((f) => GCodeFile(
              name: f['name'] as String,
              size: f['size'] as int,
              modified: f['modified'] as double,
            )));
          }
        }

        // Fetch thumbnail if printing
        String? currentFile = stats['filename'];
        String? thumb;
        if (currentFile != null && currentFile.isNotEmpty) {
           final metaRes = await http.get(Uri.parse('$baseUrl/server/files/metadata?filename=${Uri.encodeComponent(currentFile)}'));
           if (metaRes.statusCode == 200) {
              final meta = jsonDecode(metaRes.body)['result'];
              if (meta['thumbnails'] != null && (meta['thumbnails'] as List).isNotEmpty) {
                thumb = '$baseUrl/server/files/gcodes/${meta['thumbnails'].last['relative_path']}';
              }
           }
        }
        
        _printers[i] = printer.copyWith(
          status: (stats['state'] == 'shutdown' || stats['state'] == 'disconnected') ? 'error' : stats['state'],
          progress: ((data['display_status']?['progress'] ?? data['virtual_sdcard']?['progress'] ?? 0) * 100).round(),
          nozzleTemp: (data['extruder']?['temperature'] ?? 0).toDouble(),
          targetNozzle: (data['extruder']?['target'] ?? 0).toDouble(),
          bedTemp: (data['heater_bed']?['temperature'] ?? 0).toDouble(),
          targetBed: (data['heater_bed']?['target'] ?? 0).toDouble(),
          currentFile: currentFile,
          thumbnailUrl: thumb,
          files: files,
          macros: macros,
          excludeObject: ExcludeObject(
            objects: (exRaw['objects'] as List).map((o) => o['name'].toString()).toList(),
            excluded: (exRaw['excluded_objects'] as List).map((o) => o.toString()).toList(),
            current: exRaw['current_object']
          ),
          devices: _parseDevices(fullObjectStates, printer.devices),
          currentSpool: activeSpool,
          afc: _parseAfc(data, null),
        );
        
        // If we found new devices, update the subscription
        _sendSubscription(id);
        _updateWidget();
        
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> addPrinter(String name, String ip) async {
    await DatabaseHelper.instance.createPrinter(name, ip);
    await init();
  }

  Future<void> updateSpoolmanUrl(String? url) async {
    _spoolmanUrl = url;
    if (url != null) {
      await DatabaseHelper.instance.saveSetting('spoolman_url', url);
    }
    notifyListeners();
  }

  Future<void> updateThemeMode(String mode) async {
    _themeMode = mode;
    await DatabaseHelper.instance.saveSetting('theme_mode', mode);
    notifyListeners();
  }

  Future<List<Spool>> fetchAllSpools() async {
    // If a global URL is set, use it. Otherwise try printers.
    if (_spoolmanUrl != null && _spoolmanUrl!.isNotEmpty) {
      String base = _spoolmanUrl!.trim();
      if (!base.startsWith('http')) base = 'http://$base';
      if (base.endsWith('/')) base = base.substring(0, base.length - 1);
      
      final paths = [
        '$base/api/v1/spool',
        '$base/api/spool', 
        '$base/spool',
      ];
      
      for (var path in paths) {
        try {
          final url = Uri.parse(path);
          debugPrint("Attempting Spoolman fetch: $url");
          
          final res = await http.get(
            url,
            headers: {'Accept': 'application/json'},
          ).timeout(const Duration(seconds: 10));
          
          if (res.statusCode == 200) {
            // Check if response is actually JSON and not an HTML error page
            if (res.body.trim().toLowerCase().startsWith('<!doctype html') || 
                res.body.trim().toLowerCase().startsWith('<html')) {
              debugPrint("Path $path returned HTML instead of JSON. Skipping.");
              continue;
            }

            final dynamic data = jsonDecode(res.body);
            final List spoolsData = (data is List) ? data : (data['spools'] ?? []);
            
            if (spoolsData.isEmpty && !res.body.startsWith('[')) {
               continue;
            }

            return spoolsData.map((s) {
              // Handle the nested 'filament' object from your JSON
              final filament = s['filament'] ?? {};
              return Spool(
                id: s['id'],
                name: filament['name'] ?? s['name'] ?? 'Unknown',
                material: filament['material'] ?? s['material']?['name'] ?? s['material'] ?? 'Unknown',
                vendor: filament['vendor']?['name'] ?? s['vendor']?['name'] ?? 'Unknown',
                remainingWeight: (s['remaining_weight'] ?? 0).toDouble(),
                color: filament['color_hex'] ?? s['color_hex'],
              );
            }).toList();
          } else {
            debugPrint("Path $path failed: ${res.statusCode}");
          }
        } catch (e) {
          debugPrint("Path $path error: $e");
        }
      }
    }

    if (_printers.isEmpty) return [];
    
    // Fallback: Try to fetch from the first online printer that has Spoolman proxied
    for (var printer in _printers) {
      if (printer.status == 'offline') continue;
      final baseUrl = _baseUrl(printer.ip);
      try {
        final response = await http.get(Uri.parse('$baseUrl/server/spoolman/spools')).timeout(const Duration(seconds: 5));
        if (response.statusCode == 200) {
          final List spoolsData = jsonDecode(response.body)['result']['spools'];
          return spoolsData.map((s) => Spool(
            id: s['id'],
            name: s['name'] ?? 'Unknown',
            material: s['material'] ?? 'Unknown',
            vendor: s['vendor']?['name'] ?? 'Unknown',
            remainingWeight: (s['remaining_weight'] ?? 0).toDouble(),
            color: s['color_hex'],
          )).toList();
        }
      } catch (_) {}
    }
    return [];
  }

  Future<void> setPrinterSpool(String printerId, int? spoolId) async {
    final printer = _printers.firstWhere((p) => p.id == printerId);
    final baseUrl = _baseUrl(printer.ip);
    
    try {
      debugPrint("Setting printer $printerId active spool to $spoolId at $baseUrl");
      final res = await http.post(
        Uri.parse('$baseUrl/server/spoolman/active_spool'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'spool_id': spoolId}),
      ).timeout(const Duration(seconds: 5));
      
      if (res.statusCode == 200) {
        debugPrint("Spool assignment successful");
        await Future.delayed(const Duration(milliseconds: 500));
        refreshPrinter(printerId);
      } else if (res.statusCode == 404) {
        throw Exception("Moonraker Spoolman integration not enabled. Check [spoolman] section in moonraker.conf (ensure 'server' is set) and restart Moonraker.");
      } else {
        throw Exception("Server Error: ${res.statusCode} - ${res.body}");
      }
    } catch (e) {
      debugPrint("Set Spool Error: $e");
      rethrow;
    }
  }

  Future<void> updateAfcLane(String printerId, int laneId, String material, String color, {int? spoolId}) async {
    final String laneName = 'lane$laneId';
    List<String> commands = [];

    if (spoolId != null) {
      commands.add('SET_SPOOL_ID LANE=$laneName SPOOL_ID=$spoolId');
    } else {
      // Manual updates if no Spoolman ID is used
      if (material.isNotEmpty) {
        commands.add('SET_MATERIAL LANE=$laneName MATERIAL=$material');
      }
      if (color.isNotEmpty) {
        // Ensure color is just the hex code without #
        final cleanColor = color.replaceAll('#', '');
        commands.add('SET_COLOR LANE=$laneName COLOR=$cleanColor');
      }
    }

    for (var cmd in commands) {
      await sendCommand(printerId, '/printer/gcode/script?script=${Uri.encodeComponent(cmd)}');
    }
  }

  Future<void> afcAction(String printerId, String action, {int? laneId}) async {
    String cmd;
    final String laneName = laneId != null ? 'lane$laneId' : '';
    
    switch (action.toLowerCase()) {
      case 'load':
        cmd = 'AFC_LOAD LANE=$laneName';
        break;
      case 'unload':
        cmd = 'AFC_UNLOAD'; // Usually unloads current active lane
        break;
      case 'eject':
        cmd = 'AFC_EJECT';
        break;
      default:
        return;
    }
    
    await sendCommand(printerId, '/printer/gcode/script?script=${Uri.encodeComponent(cmd)}');
  }

  Future<void> deletePrinter(String id) async {
    _subscriptions[id]?.cancel(); _channels[id]?.sink.close();
    await DatabaseHelper.instance.deletePrinter(id);
    _printers.removeWhere((p) => p.id == id);
    notifyListeners();
  }

  Future<void> sendCommand(String printerId, String endpoint, {Map<String, dynamic>? body}) async {
    final isEmergency = endpoint.contains('emergency_stop') || (endpoint.contains('script') && endpoint.contains('M112'));
    final isRestart = endpoint.contains('firmware_restart') || endpoint.contains('/machine/services/restart');
    
    try {
      final index = _printers.indexWhere((p) => p.id == printerId);
      if (index != -1) {
        if (isEmergency) {
          _printers[index] = _printers[index].copyWith(status: 'error');
          notifyListeners();
        } else if (isRestart) {
          _printers[index] = _printers[index].copyWith(status: 'offline');
          notifyListeners();
        }
      }

      final printer = _printers.firstWhere((p) => p.id == printerId);
      final baseUrl = _baseUrl(printer.ip);
      
      // If it's a critical command, we preemptively close the WS as it will likely break anyway
      if (isEmergency || isRestart) {
        _subscriptions[printerId]?.cancel();
        _channels[printerId]?.sink.close();
        _subscriptions.remove(printerId);
        _channels.remove(printerId);
      }

      await http.post(
        Uri.parse('$baseUrl$endpoint'), 
        headers: {'Content-Type': 'application/json'}, 
        body: body != null ? jsonEncode(body) : null
      ).timeout(Duration(seconds: isEmergency ? 2 : 5));

      // After a restart/emergency stop, trigger a rapid reconnection attempt
      if (isEmergency || isRestart) {
        Future.delayed(const Duration(seconds: 2), () => connectWebSocket(printerId));
      }
    } catch (e) {
      debugPrint("Command Error ($endpoint): $e");
      if (isEmergency || isRestart) {
        Future.delayed(const Duration(seconds: 5), () => connectWebSocket(printerId));
      }
    }
  }
}