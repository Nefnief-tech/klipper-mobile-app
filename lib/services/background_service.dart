import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'database_helper.dart';
import 'notification_service.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      // Initialize basic services for background execution
      await NotificationService.init();
      final prefs = await SharedPreferences.getInstance();
      final printers = await DatabaseHelper.instance.fetchPrinters();

      for (var p in printers) {
        final String ip = p['ip'];
        final String name = p['name'];
        final String id = p['id'];
        
        String url = ip.trim();
        if (!url.startsWith('http')) url = 'http://$url';
        if (url.endsWith('/')) url = url.substring(0, url.length - 1);

        try {
          final response = await http.get(
            Uri.parse('$url/printer/objects/query?print_stats&display_status&virtual_sdcard&extruder&heater_bed'),
          ).timeout(const Duration(seconds: 10));

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body)['result']['status'];
            final stats = data['print_stats'];
            final String currentState = stats['state'];
            final String? filename = stats['filename'];
            
            // Get previous state
            final String? lastState = prefs.getString('last_state_$id');
            
            // Progress calculation
            final double progress = ((data['display_status']?['progress'] ?? data['virtual_sdcard']?['progress'] ?? 0) * 100);
            final int progressInt = progress.round();
            final int lastProgress = prefs.getInt('last_progress_$id') ?? -1;

            // Save current state
            await prefs.setString('last_state_$id', currentState);
            await prefs.setInt('last_progress_$id', progressInt);

            // Notification Logic (Simplified for background)
            if (lastState != null && lastState != currentState) {
               if (currentState == 'complete') {
                 await NotificationService.showNotification(
                   id: id.hashCode,
                   title: 'Print Complete!',
                   body: '$name: ${filename ?? "Your model"} is ready.',
                 );
               } else if (currentState == 'error' || (currentState == 'shutdown' && lastState != 'shutdown')) {
                 await NotificationService.showNotification(
                   id: id.hashCode,
                   title: 'Printer Issue',
                   body: '$name status changed to $currentState.',
                 );
               } else if (currentState == 'printing' && lastState != 'printing') {
                  await NotificationService.showNotification(
                   id: id.hashCode,
                   title: 'Print Started',
                   body: '$name: Now printing ${filename ?? "model"}.',
                 );
               }
            } else if (currentState == 'printing') {
               // Notify on significant progress change (e.g., every 25% or if it's been a long time since last check)
               // Since background tasks run every 15m+, any progress update is relevant if it's printing.
               // But we don't want to spam if it hasn't moved much? 
               // Actually, 15 mins is a long time, so a progress update is good.
               
               // To avoid spamming 1% updates if the task runs frequently (dev mode), lets check delta
               if (progressInt > lastProgress + 5 || progressInt == 100) {
                  double nozzle = (data['extruder']?['temperature'] ?? 0).toDouble();
                  double bed = (data['heater_bed']?['temperature'] ?? 0).toDouble();
                  
                  await NotificationService.showNotification(
                    id: id.hashCode,
                    title: 'Printing: $name',
                    body: '$progressInt% - ${filename ?? "Unknown File"}',
                    progress: progressInt,
                    maxProgress: 100,
                    nozzleTemp: nozzle,
                    bedTemp: bed,
                  );
               }
            }
          }
        } catch (e) {
          debugPrint("Background check error for $name: $e");
        }
      }
    } catch (e) {
      debugPrint("Background Task Critical Error: $e");
      return Future.value(false);
    }

    return Future.value(true);
  });
}

class BackgroundService {
  static Future<void> init() async {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: false, // Set to true for testing to run immediately/frequently
    );
    
    // Register the periodic task
    await Workmanager().registerPeriodicTask(
      "com.example.farm_manager.printer_check",
      "printerCheck",
      frequency: const Duration(minutes: 15),
      initialDelay: const Duration(minutes: 5),
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
    );
  }
}
