import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  // Singleton instance
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  static Database? _database;

  // Memastikan database terinisialisasi
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // Inisialisasi database
  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'app_database.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  // Membuat tabel-tabel yang diperlukan
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE speed_test_result (
        idTest INTEGER PRIMARY KEY AUTOINCREMENT,
        download_speed REAL,
        upload_speed REAL,
        ping INTEGER,
        jitter INTEGER,
        packet_loss REAL,
        test_date TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE sniffing_result (
        no INTEGER PRIMARY KEY AUTOINCREMENT,
        time TEXT,
        source TEXT,
        destination TEXT,
        ports TEXT,
        length INTEGER,
        info TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE terminal (
        idSession INTEGER PRIMARY KEY AUTOINCREMENT,
        protocol TEXT,
        user TEXT,
        host TEXT,
        password TEXT,
        port INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE vpn (
        // Struktur tabel VPN bisa ditambahkan di sini
      )
    ''');

    await db.execute('''
      CREATE TABLE host_server (
        idHost INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        hostname TEXT,
        port INTEGER,
        username TEXT,
        password TEXT,
        key TEXT
      )
    ''');
  }

  // Tambahkan fungsi untuk menyimpan data, membaca data, mengupdate, dan menghapus
  Future<int> insertSpeedTestResult(Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert('speed_test_result', data);
  }

  Future<List<Map<String, dynamic>>> getSpeedTestResults() async {
    final db = await database;
    return await db.query('speed_test_result');
  }

  Future<int> insertSniffingResult(Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert('sniffing_result', data);
  }

  Future<List<Map<String, dynamic>>> getSniffingResults() async {
    final db = await database;
    return await db.query('sniffing_result');
  }

  Future<int> insertTerminalSession(Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert('terminal', data);
  }

  Future<List<Map<String, dynamic>>> getTerminalSessions() async {
    final db = await database;
    return await db.query('terminal');
  }

  Future<int> insertHostServer(Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert('host_server', data);
  }

  Future<List<Map<String, dynamic>>> getHostServers() async {
    final db = await database;
    return await db.query('host_server');
  }

  // Tambahkan fungsi lain untuk mengupdate dan menghapus data jika diperlukan
}
