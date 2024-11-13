import 'package:dartssh2/dartssh2.dart';

Future<void> connectToSftpServer() async {
  const String hostname = '192.168.100.10';
  const String username = 'sftpusr1';
  const String password = '123'; // Ganti dengan password yang benar

  try {
    // Inisialisasi socket SSH
    final socket = await SSHSocket.connect(hostname, 22);
    // Buat instance SSHClient
    final client = SSHClient(socket,
        username: username, onPasswordRequest: () => password);

    print('Koneksi berhasil!');

    // Lakukan operasi SSH lainnya di sini
    // Misalnya, list direktori atau upload/download file

    client.close(); // Tutup koneksi setelah selesai
  } catch (e) {
    print('Gagal terhubung ke server: $e');
  }
}
