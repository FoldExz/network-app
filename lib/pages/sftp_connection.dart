import 'dart:async';

import 'package:dartssh2/dartssh2.dart';
import 'dart:io';

class SSHConnectionHelper {
  final String hostname;
  final int port;
  final String username;
  final String password;

  SSHConnectionHelper({
    required this.hostname,
    this.port = 22,
    required this.username,
    required this.password,
  });

  // Inisialisasi SSH client
  Future<SSHClient> _createClient() async {
    try {
      final socket = await SSHSocket.connect(hostname, port)
          .timeout(const Duration(seconds: 10)); // Timeout 10 detik
      return SSHClient(
        socket,
        username: username,
        onPasswordRequest: () => password,
      );
    } on TimeoutException {
      throw Exception("Koneksi SSH timeout. Pastikan alamat dan port benar.");
    }
  }

  // Fungsi untuk mengupload file
  Future<void> uploadFile(String localPath, String remotePath) async {
    final client = await _createClient();
    final sftp = await client.sftp();
    final file = await sftp.open(remotePath, mode: SftpFileOpenMode.write);
    await file.write(File(localPath).openRead().cast());
    client.close();
  }

  // Fungsi untuk mendownload file
  Future<void> downloadFile(String remotePath, String localPath) async {
    final client = await _createClient();
    final sftp = await client.sftp();
    final file = await sftp.open(remotePath);
    final content = await file.readBytes();
    await File(localPath).writeAsBytes(content);
    client.close();
  }

  // Fungsi untuk listing direktori
  Future<List<String>> listDirectory(String path) async {
    final client = await _createClient();
    final sftp = await client.sftp();
    final items = await sftp.listdir(path);
    client.close();
    return items.map((item) => item.longname).toList();
  }
}
