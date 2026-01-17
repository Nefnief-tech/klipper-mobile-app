class GCodeFile {
  final String name;
  final int size;
  final double modified;
  final String? thumbnailUrl;

  GCodeFile({required this.name, required this.size, required this.modified, this.thumbnailUrl});
}

class TempPoint {
  final DateTime time;
  final double nozzle;
  final double bed;

  TempPoint({required this.time, required this.nozzle, required this.bed});
}

class ExcludeObject {
  final List<String> objects;
  final List<String> excluded;
  final String? current;

  ExcludeObject({required this.objects, required this.excluded, this.current});
}

class KlipperDevice {
  final String name;
  final String type; // fan, output_pin, led, heater_fan, controller_fan
  final double value; // 0.0 to 1.0 for fans/lights
  final bool? isOn;

  KlipperDevice({required this.name, required this.type, required this.value, this.isOn});
}

class Spool {
  final int id;
  final String name;
  final String material;
  final String vendor;
  final double remainingWeight; // in grams
  final String? color; // Hex color string

  Spool({
    required this.id,
    required this.name,
    required this.material,
    required this.vendor,
    required this.remainingWeight,
    this.color,
  });
}

class AFCLane {
  final int id;
  final String status; // empty, loaded, active
  final String? material;
  final String? color; // Hex color string
  final String? name;


  AFCLane({
    required this.id,
    required this.status,
    this.material,
    this.color,
    this.name,
  });
}

class AFC {
  final List<AFCLane> lanes;
  final int? activeLane;
  final String status;

  AFC({
    required this.lanes,
    this.activeLane,
    required this.status,
  });
}

class Printer {
  final String id;
  final String name;
  final String ip;
  String status;
  int progress;
  double nozzleTemp;
  double targetNozzle;
  double bedTemp;
  double targetBed;
  String? currentFile;
  String? thumbnailUrl;
  List<GCodeFile> files;
  List<String> macros;
  List<String> terminalLogs;
  ExcludeObject? excludeObject;
  List<TempPoint> history;
  List<KlipperDevice> devices;
  Spool? currentSpool;
  AFC? afc;

  Printer({
    required this.id,
    required this.name,
    required this.ip,
    this.status = 'offline',
    this.progress = 0,
    this.nozzleTemp = 0,
    this.targetNozzle = 0,
    this.bedTemp = 0,
    this.targetBed = 0,
    this.currentFile,
    this.thumbnailUrl,
    this.files = const [],
    this.macros = const [],
    this.terminalLogs = const [],
    this.excludeObject,
    this.history = const [],
    this.devices = const [],
    this.currentSpool,
    this.afc,
  });

  Printer copyWith({
    String? status,
    int? progress,
    double? nozzleTemp,
    double? targetNozzle,
    double? bedTemp,
    double? targetBed,
    String? currentFile,
    String? thumbnailUrl,
    List<GCodeFile>? files,
    List<String>? macros,
    List<String>? terminalLogs,
    ExcludeObject? excludeObject,
    List<TempPoint>? history,
    List<KlipperDevice>? devices,
    Spool? currentSpool,
    AFC? afc,
  }) {
    return Printer(
      id: id,
      name: name,
      ip: ip,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      nozzleTemp: nozzleTemp ?? this.nozzleTemp,
      targetNozzle: targetNozzle ?? this.targetNozzle,
      bedTemp: bedTemp ?? this.bedTemp,
      targetBed: targetBed ?? this.targetBed,
      currentFile: currentFile ?? this.currentFile,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      files: files ?? this.files,
      macros: macros ?? this.macros,
      terminalLogs: terminalLogs ?? this.terminalLogs,
      excludeObject: excludeObject ?? this.excludeObject,
      history: history ?? this.history,
      devices: devices ?? this.devices,
      currentSpool: currentSpool ?? this.currentSpool,
      afc: afc ?? this.afc,
    );
  }
}