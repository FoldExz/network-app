import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:dartssh2/dartssh2.dart';

class SSHConnection {
  SSHClient? _client;
  bool _isConnected = false;

  // Menambahkan getter untuk memeriksa status koneksi
  bool get isConnected => _isConnected;

  // Fungsi untuk koneksi SSH
  Future<void> connect(String host, String username, String password) async {
    try {
      final socket = await SSHSocket.connect(host, 22);

      _client = SSHClient(
        socket,
        username: username,
        onPasswordRequest: () => password,
      );

      await _client!.authenticated;
      _isConnected = true;
      print("Connected to $host");
    } catch (e) {
      _isConnected = false;
      print("Connection failed: $e");
    }
  }

  // Menutup koneksi
  void close() {
    _client?.close();
    _isConnected = false;
  }

  // Menjalankan perintah SSH
  Future<String> executeCommand(String command) async {
    if (_client != null) {
      final result = await _client!.run(command);
      return utf8.decode(result);
    } else {
      return "Not connected to SSH server.";
    }
  }

  // Fungsi-fungsi SFTP

  // 1. List Directory
  Future<List<SftpName>> listDirectory(String path) async {
    if (_client != null) {
      final sftp = await _client!.sftp();
      final items = await sftp.listdir(path);
      return items;
    } else {
      throw Exception("Not connected to SSH server.");
    }
  }

  // 2. Read Remote File
  Future<String> readFile(String filePath) async {
    if (_client != null) {
      final sftp = await _client!.sftp();
      final file = await sftp.open(filePath);
      final content = await file.readBytes();
      return latin1.decode(content); // Mengubah byte ke teks
    } else {
      throw Exception("Not connected to SSH server.");
    }
  }

  // 3. Write Remote File
  Future<void> writeFile(String filePath, String content) async {
    if (_client != null) {
      final sftp = await _client!.sftp();
      final file = await sftp.open(filePath, mode: SftpFileOpenMode.write);
      await file.writeBytes(utf8.encode(content));
    } else {
      throw Exception("Not connected to SSH server.");
    }
  }

  // 4. File Upload
  Future<void> uploadFile(String remotePath, File localFile) async {
    if (_client != null) {
      final sftp = await _client!.sftp();
      final file = await sftp.open(remotePath,
          mode: SftpFileOpenMode.create | SftpFileOpenMode.write);
      await file.write(localFile.openRead().cast());
    } else {
      throw Exception("Not connected to SSH server.");
    }
  }

  // 5. Directory Operations
  Future<void> createDirectory(String path) async {
    if (_client != null) {
      final sftp = await _client!.sftp();
      await sftp.mkdir(path);
    } else {
      throw Exception("Not connected to SSH server.");
    }
  }

  Future<void> removeDirectory(String path) async {
    if (_client != null) {
      final sftp = await _client!.sftp();
      await sftp.rmdir(path);
    } else {
      throw Exception("Not connected to SSH server.");
    }
  }

  // 6. Get/Set Attributes
  Future<SftpFileAttrs> getFileAttributes(String path) async {
    if (_client != null) {
      final sftp = await _client!.sftp();
      return await sftp.stat(path);
    } else {
      throw Exception("Not connected to SSH server.");
    }
  }

  Future<void> setFileAttributes(String path, SftpFileAttrs attrs) async {
    if (_client != null) {
      final sftp = await _client!.sftp();
      await sftp.setStat(path, attrs);
    } else {
      throw Exception("Not connected to SSH server.");
    }
  }

  // 7. Check Free Space
  Future<Map<String, int>> checkFreeSpace(String path) async {
    if (_client != null) {
      final sftp = await _client!.sftp();
      final statvfs = await sftp.statvfs(path);
      final total = statvfs.blockSize * statvfs.totalBlocks;
      final free = statvfs.blockSize * statvfs.freeBlocks;
      return {'total': total, 'free': free};
    } else {
      throw Exception("Not connected to SSH server.");
    }
  }
}
