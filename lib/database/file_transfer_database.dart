import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class FileTransferDatabase {
  static final FileTransferDatabase _instance =
      FileTransferDatabase._internal();
  static Database? _database;

  FileTransferDatabase._internal();

  factory FileTransferDatabase() {
    return _instance;
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'file_transfer.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE file_transfers(id INTEGER PRIMARY KEY AUTOINCREMENT, fileName TEXT, fileSize INTEGER, direction TEXT, timestamp TEXT)',
        );
      },
    );
  }

  Future<void> addFileTransfer(
      String fileName, int fileSize, String direction) async {
    final db = await database;
    await db.insert(
      'file_transfers',
      {
        'fileName': fileName,
        'fileSize': fileSize,
        'direction': direction,
        'timestamp': DateTime.now().toString(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getFileTransfers() async {
    final db = await database;
    return await db.query('file_transfers');
  }

  Future<void> deleteFileTransfer(String fileName) async {
    final db = await database;
    await db.delete(
      'file_transfers',
      where: 'fileName = ?',
      whereArgs: [fileName],
    );
  }
}
