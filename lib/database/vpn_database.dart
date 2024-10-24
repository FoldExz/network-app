import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class VPNDatabase {
  static final VPNDatabase _instance = VPNDatabase._internal();
  static Database? _database;

  VPNDatabase._internal();

  factory VPNDatabase() {
    return _instance;
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'vpn_connections.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE vpn_connections(id INTEGER PRIMARY KEY AUTOINCREMENT, vpnID TEXT, publicIP TEXT, timestamp TEXT)',
        );
      },
    );
  }

  Future<void> addConnection(String vpnID, String publicIP) async {
    final db = await database;
    await db.insert(
      'vpn_connections',
      {
        'vpnID': vpnID,
        'publicIP': publicIP,
        'timestamp': DateTime.now().toString(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getVPNConnections() async {
    final db = await database;
    return await db.query('vpn_connections');
  }

  Future<void> deleteConnection(String timestamp) async {
    final db = await database;
    await db.delete(
      'vpn_connections',
      where: 'timestamp = ?',
      whereArgs: [timestamp],
    );
  }
}
