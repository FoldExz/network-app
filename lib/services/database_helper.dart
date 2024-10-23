import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database; // Variabel nullable

  factory DatabaseHelper() {
    return _instance; // Mengembalikan instance tunggal
  }

  DatabaseHelper._internal();

  // Getter untuk mendapatkan database yang sudah diinisialisasi
  Future<Database> get database async {
    if (_database != null) return _database!; // Akses dengan tanda '!'
    _database = await _initDatabase(); // Inisialisasi jika null
    return _database!;
  }

  // Fungsi untuk menginisialisasi database
  Future<Database> _initDatabase() async {
    String path =
        join(await getDatabasesPath(), 'myapp.db'); // Mengatur path database
    return await openDatabase(path,
        version: 1, onCreate: _onCreate); // Membuka database
  }

  // Fungsi untuk membuat tabel di database
  Future<void> _onCreate(Database db, int version) async {
    // Tabel untuk hasil speed test
    await db.execute('''
      CREATE TABLE speed_test_results(
        idTest INTEGER PRIMARY KEY AUTOINCREMENT,
        download_speed REAL,
        upload_speed REAL,
        ping INTEGER,
        jitter REAL,
        packet_loss REAL,
        test_date TEXT
      );
    ''');

    // Tabel untuk host server
    await db.execute('''
      CREATE TABLE host_servers(
        idHost INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        hostname TEXT,
        port TEXT,
        username TEXT,
        password TEXT,
        key TEXT
      );
    ''');

    // Tabel untuk hasil sniffing
    await db.execute('''
      CREATE TABLE sniffing_results(
        no INTEGER PRIMARY KEY AUTOINCREMENT,
        time TEXT,
        source TEXT,
        destination TEXT,
        ports TEXT,
        length INTEGER,
        info TEXT
      );
    ''');

    // Tabel untuk history session terminal
    await db.execute('''
      CREATE TABLE terminal_sessions(
        idSession INTEGER PRIMARY KEY AUTOINCREMENT,
        protocol TEXT,
        user TEXT,
        host TEXT,
        password TEXT,
        port TEXT
      );
    ''');

    // Tabel placeholder untuk VPN (coming soon)
    await db.execute('''
      CREATE TABLE vpn(
        idVPN INTEGER PRIMARY KEY AUTOINCREMENT
        -- Placeholder, kolom lainnya akan ditambahkan sesuai fitur VPN di masa depan
      );
    ''');
  }

  // Fungsi untuk menyimpan hasil speed test
  Future<int> insertSpeedTestResult(Map<String, dynamic> result) async {
    Database db = await database; // Mendapatkan database
    return await db.insert(
        'speed_test_results', result); // Menyimpan hasil ke tabel
  }

  // Fungsi untuk mendapatkan semua hasil speed test
  Future<List<Map<String, dynamic>>> getSpeedTestResults() async {
    Database db = await database; // Mendapatkan database
    return await db.query('speed_test_results'); // Mengambil semua hasil
  }

  // Fungsi untuk menyimpan host server
  Future<int> insertHostServer(Map<String, dynamic> host) async {
    Database db = await database; // Mendapatkan database
    return await db.insert('host_servers', host); // Menyimpan host ke tabel
  }

  // Fungsi untuk mengambil semua host server
  Future<List<Map<String, dynamic>>> getHostServers() async {
    Database db = await database; // Mendapatkan database
    return await db.query('host_servers'); // Mengambil semua host
  }

  // Fungsi untuk menyimpan hasil sniffing
  Future<int> insertSniffingResult(Map<String, dynamic> sniffingResult) async {
    Database db = await database; // Mendapatkan database
    return await db.insert(
        'sniffing_results', sniffingResult); // Menyimpan hasil sniffing
  }

  // Fungsi untuk mengambil semua hasil sniffing
  Future<List<Map<String, dynamic>>> getSniffingResults() async {
    Database db = await database; // Mendapatkan database
    return await db.query('sniffing_results'); // Mengambil semua hasil sniffing
  }

  // Fungsi untuk menyimpan sesi terminal
  Future<int> insertTerminalSession(Map<String, dynamic> session) async {
    Database db = await database; // Mendapatkan database
    return await db.insert(
        'terminal_sessions', session); // Menyimpan sesi terminal
  }

  // Fungsi untuk mendapatkan semua sesi terminal
  Future<List<Map<String, dynamic>>> getTerminalSessions() async {
    Database db = await database; // Mendapatkan database
    return await db.query('terminal_sessions'); // Mengambil semua sesi
  }

  // Fungsi placeholder untuk VPN (Coming Soon)
  Future<int> insertVPN(Map<String, dynamic> vpn) async {
    Database db = await database; // Mendapatkan database
    return await db.insert('vpn', vpn); // Menyimpan data VPN (placeholder)
  }

  // Fungsi placeholder untuk mengambil semua data VPN (Coming Soon)
  Future<List<Map<String, dynamic>>> getVPNs() async {
    Database db = await database; // Mendapatkan database
    return await db.query('vpn'); // Mengambil semua data VPN (placeholder)
  }
}
