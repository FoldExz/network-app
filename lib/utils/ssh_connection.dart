import 'dart:async';
import 'dart:convert';
import 'package:dartssh2/dartssh2.dart';

class SSHConnection {
  SSHClient? _client;
  bool _isConnected = false; // Menyimpan status koneksi

  // Menambahkan getter untuk memeriksa status koneksi
  bool get isConnected => _isConnected;

  Future<void> connect(String host, String username, String password) async {
    try {
      // Cek koneksi ke host
      final socket = await SSHSocket.connect(host, 22);

      // Inisialisasi client SSH dengan autentikasi password
      _client = SSHClient(
        socket,
        username: username,
        onPasswordRequest: () => password,
      );

      // Pastikan client terautentikasi
      await _client!.authenticated;
      _isConnected = true; // Koneksi berhasil
      print("Connected to $host");
    } catch (e) {
      _isConnected = false; // Koneksi gagal
      print("Connection failed: $e");
    }
  }

  Future<String> executeCommand(String command) async {
    if (_client != null) {
      final result = await _client!.run(command);
      return utf8.decode(result);
    } else {
      return "Not connected to SSH server.";
    }
  }

  void close() {
    _client?.close();
    _isConnected = false; // Setel status koneksi menjadi false saat ditutup
  }
}
