import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/printer.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('farm.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 2, onCreate: _createDB, onUpgrade: _onUpgrade);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE printers (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        ip TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE settings (
          key TEXT PRIMARY KEY,
          value TEXT
        )
      ''');
    }
  }

  Future<void> saveSetting(String key, String value) async {
    final db = await instance.database;
    await db.insert('settings', {'key': key, 'value': value}, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<String?> getSetting(String key) async {
    final db = await instance.database;
    final results = await db.query('settings', where: 'key = ?', whereArgs: [key]);
    if (results.isNotEmpty) return results.first['value'] as String?;
    return null;
  }

  Future<List<Map<String, dynamic>>> fetchPrinters() async {
    final db = await instance.database;
    return await db.query('printers');
  }

  Future createPrinter(String name, String ip) async {
    final db = await instance.database;
    await db.insert('printers', {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'name': name,
      'ip': ip,
    });
  }

  Future deletePrinter(String id) async {
    final db = await instance.database;
    await db.delete('printers', where: 'id = ?', whereArgs: [id]);
  }
}
