import 'dart:async';
import 'dart:convert';
import 'package:dartssh2/dartssh2.dart';

class SSHConnection {
  SSHClient? _client;

  Future<void> connect(String host, String username, String password) async {
    try {
      // Koneksikan ke server SSH
      final socket = await SSHSocket.connect(host, 22);

      // Inisialisasi client SSH dengan autentikasi password
      _client = SSHClient(
        socket,
        username: username,
        onPasswordRequest: () => password,
      );

      // Pastikan client terautentikasi
      await _client!.authenticated;
      print("Connected to $host");
    } catch (e) {
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
  }
}
