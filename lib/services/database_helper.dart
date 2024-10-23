import 'dart:async';
import 'package:path/path.dart'; // Pastikan ini benar
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database; // Variabel nullable

  factory DatabaseHelper() {
    return _instance;
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
    String path = join(await getDatabasesPath(), 'myapp.db');
    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  // Fungsi untuk membuat tabel di database
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE speed_test_results(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        download_speed REAL,
        upload_speed REAL,
        ping INTEGER,
        jitter REAL,
        packet_loss REAL,
        test_date TEXT
      );
    ''');

    // Tambahkan tabel lain jika diperlukan
  }

  // Fungsi untuk menyimpan hasil speed test
  Future<int> insertSpeedTestResult(Map<String, dynamic> result) async {
    Database db = await database;
    return await db.insert('speed_test_results', result);
  }

  // Fungsi untuk mendapatkan semua hasil speed test
  Future<List<Map<String, dynamic>>> getSpeedTestResults() async {
    Database db = await database;
    return await db.query('speed_test_results');
  }
}
