import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class SSHSessionDatabase {
  static final SSHSessionDatabase _instance = SSHSessionDatabase._internal();
  static Database? _database;

  SSHSessionDatabase._internal();

  factory SSHSessionDatabase() {
    return _instance;
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'ssh_sessions.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE ssh_sessions(id INTEGER PRIMARY KEY AUTOINCREMENT, serverAddress TEXT, commandExecuted TEXT, timestamp TEXT)',
        );
      },
    );
  }

  Future<void> addSession(String serverAddress, String commandExecuted) async {
    final db = await database;
    await db.insert(
      'ssh_sessions',
      {
        'serverAddress': serverAddress,
        'commandExecuted': commandExecuted,
        'timestamp': DateTime.now().toString(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getSSHSessions() async {
    final db = await database;
    return await db.query('ssh_sessions');
  }

  Future<void> deleteSession(String timestamp) async {
    final db = await database;
    await db.delete(
      'ssh_sessions',
      where: 'timestamp = ?',
      whereArgs: [timestamp],
    );
  }
}
