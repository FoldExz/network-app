import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;

  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    // Mengatur lokasi database
    String path = join(await getDatabasesPath(), 'app_database.db');

    // Membuat database dan tabel
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE speed_test_result (
            idTest INTEGER PRIMARY KEY AUTOINCREMENT,
            download_speed REAL,
            upload_speed REAL,
            ping REAL,
            jitter REAL,
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
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            status TEXT,
            protocol TEXT,
            connectionType TEXT
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
      },
    );
  }

  // Method untuk menambahkan hasil SpeedTest
  Future<int> insertSpeedTestResult(Map<String, dynamic> row) async {
    final db = await database;
    return await db.insert('speed_test_result', row);
  }

  // Method untuk mengambil semua hasil SpeedTest
  Future<List<Map<String, dynamic>>> getAllSpeedTestResults() async {
    final db = await database;
    return await db.query('speed_test_result');
  }

  // Method untuk menambahkan hasil Sniffing
  Future<int> insertSniffingResult(Map<String, dynamic> row) async {
    final db = await database;
    return await db.insert('sniffing_result', row);
  }

  // Method untuk mengambil semua hasil Sniffing
  Future<List<Map<String, dynamic>>> getAllSniffingResults() async {
    final db = await database;
    return await db.query('sniffing_result');
  }

  // Method untuk menambahkan session Terminal
  Future<int> insertTerminalSession(Map<String, dynamic> row) async {
    final db = await database;
    return await db.insert('terminal', row);
  }

  // Method untuk mengambil semua session Terminal
  Future<List<Map<String, dynamic>>> getAllTerminalSessions() async {
    final db = await database;
    return await db.query('terminal');
  }

  // Method untuk menambahkan host server
  Future<int> insertHostServer(Map<String, dynamic> row) async {
    final db = await database;
    return await db.insert('host_server', row);
  }

  // Method untuk mengambil semua host server
  Future<List<Map<String, dynamic>>> getAllHostServers() async {
    final db = await database;
    return await db.query('host_server');
  }
}
