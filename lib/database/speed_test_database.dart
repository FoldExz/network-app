import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class SpeedTestDatabase {
  static final SpeedTestDatabase _instance = SpeedTestDatabase._internal();
  static Database? _database;

  SpeedTestDatabase._internal();

  factory SpeedTestDatabase() {
    return _instance;
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'speed_tests.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE speed_tests(id INTEGER PRIMARY KEY AUTOINCREMENT, downloadSpeed REAL, uploadSpeed REAL, ping INTEGER, timestamp TEXT)',
        );
      },
    );
  }

  Future<void> addSpeedTest(
      double downloadSpeed, double uploadSpeed, int ping) async {
    final db = await database;
    await db.insert(
      'speed_tests',
      {
        'downloadSpeed': downloadSpeed,
        'uploadSpeed': uploadSpeed,
        'ping': ping,
        'timestamp': DateTime.now().toString(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getSpeedTests() async {
    final db = await database;
    return await db.query('speed_tests');
  }

  Future<void> deleteSpeedTest(String timestamp) async {
    final db = await database;
    await db.delete(
      'speed_tests',
      where: 'timestamp = ?',
      whereArgs: [timestamp],
    );
  }
}
