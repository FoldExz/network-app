import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class HostDatabase {
  static final HostDatabase _instance = HostDatabase._internal();
  static Database? _database;

  HostDatabase._internal();

  factory HostDatabase() {
    return _instance;
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'hosts.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE hosts(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, hostname TEXT, port TEXT, username TEXT)',
        );
      },
    );
  }

  Future<void> addHost(
      String name, String hostname, String port, String username) async {
    final db = await database;
    await db.insert(
      'hosts',
      {
        'name': name,
        'hostname': hostname,
        'port': port,
        'username': username,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, String>>> getHosts() async {
    final db = await database;
    return await db.query('hosts');
  }

  Future<void> deleteHost(String name) async {
    final db = await database;
    await db.delete(
      'hosts',
      where: 'name = ?',
      whereArgs: [name],
    );
  }
}
