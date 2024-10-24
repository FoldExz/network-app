import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class PacketSniffingDatabase {
  static final PacketSniffingDatabase _instance =
      PacketSniffingDatabase._internal();
  static Database? _database;

  PacketSniffingDatabase._internal();

  factory PacketSniffingDatabase() {
    return _instance;
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'packets.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE packets(id INTEGER PRIMARY KEY AUTOINCREMENT, sourceIP TEXT, destinationIP TEXT, protocol TEXT, timestamp TEXT)',
        );
      },
    );
  }

  Future<void> addPacket(
      String sourceIP, String destinationIP, String protocol) async {
    final db = await database;
    await db.insert(
      'packets',
      {
        'sourceIP': sourceIP,
        'destinationIP': destinationIP,
        'protocol': protocol,
        'timestamp': DateTime.now().toString(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getPackets() async {
    final db = await database;
    return await db.query('packets');
  }

  Future<void> clearPackets() async {
    final db = await database;
    await db.delete('packets');
  }
}
