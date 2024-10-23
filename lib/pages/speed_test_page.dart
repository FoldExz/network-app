import 'package:flutter/material.dart';
import 'dart:async'; // Untuk simulasi delay
import '../services/database_helper.dart';

class SpeedTestPage extends StatefulWidget {
  const SpeedTestPage({super.key});

  @override
  _SpeedTestPageState createState() => _SpeedTestPageState();
}

class _SpeedTestPageState extends State<SpeedTestPage> {
  bool isConnected = true; // Status koneksi
  bool isTesting = false; // Status untuk cek apakah sedang menjalankan tes
  double downloadSpeed = 0.0;
  double uploadSpeed = 0.0;
  int ping = 0;

  // Fungsi untuk simulasi speed test dan menyimpan hasilnya ke database
  Future<void> _startSpeedTest() async {
    setState(() {
      isTesting = true; // Menandai bahwa tes sedang berjalan
    });

    // Simulasi delay untuk tes speed (misalnya 3 detik)
    await Future.delayed(const Duration(seconds: 3));

    // Simulasi hasil speed test
    downloadSpeed = (10 + (100 - 10) * (1 - 0.5)); // Hasil random
    uploadSpeed = (5 + (50 - 5) * (1 - 0.5)); // Hasil random
    ping = 50; // Simulasi ping

    // Simpan hasil ke database
    await _saveSpeedTestResult(downloadSpeed, uploadSpeed, ping);

    setState(() {
      isTesting = false; // Mengakhiri status tes
    });

    // Menampilkan snackbar hasil tes
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'Speed test completed!\nDownload: $downloadSpeed Mbps, Upload: $uploadSpeed Mbps, Ping: $ping ms'),
      ),
    );
  }

  // Fungsi untuk menyimpan hasil speed test ke SQLite
  Future<void> _saveSpeedTestResult(
      double downloadSpeed, double uploadSpeed, int ping) async {
    Map<String, dynamic> result = {
      'download_speed': downloadSpeed,
      'upload_speed': uploadSpeed,
      'ping': ping,
      'jitter': 0.0, // Simulasi
      'packet_loss': 0.0, // Simulasi
      'test_date': DateTime.now().toString(),
    };

    int id = await DatabaseHelper().insertSpeedTestResult(result);
    print('Speed test result saved with ID: $id');
  }

  @override
  Widget build(BuildContext context) {
    // Mengambil ukuran layar yang tersedia
    var mediaQuery = MediaQuery.of(context);
    double screenWidth = mediaQuery.size.width;
    double screenHeight = mediaQuery.size.height;

    // Membuat ukuran lingkaran proporsional baik berdasarkan lebar maupun tinggi
    double circleSize =
        (screenWidth < screenHeight ? screenWidth : screenHeight) *
            0.5; // 50% dari lebar atau tinggi
    double borderWidth =
        circleSize * 0.025; // Border 2.5% dari ukuran lingkaran
    double startTextSize =
        circleSize * 0.22; // Ukuran teks START 22% dari lingkaran
    double statusTextSize = (screenWidth * 0.05)
        .clamp(24, 50); // Ukuran teks status, dibatasi min 24px dan max 50px

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Lingkaran dengan stroke berwarna dan transparan di dalamnya
          Container(
            width: circleSize, // Ukuran lingkaran responsif
            height: circleSize, // Ukuran lingkaran responsif
            decoration: BoxDecoration(
              gradient: isConnected
                  ? const LinearGradient(
                      colors: [
                        Color(0xFF00A19C),
                        Color(0xFF03CAA4),
                        Color(0xFF96F5A9),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    )
                  : const LinearGradient(
                      colors: [
                        Color(0xFF7A1B34),
                        Color(0xFFFF2D6A),
                        Color(0xFFFFA376),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
              shape: BoxShape.circle,
              border: Border.all(
                width: borderWidth, // Lebar border responsif
                color: Colors.transparent, // Border transparan
              ),
            ),
            child: Center(
              child: GestureDetector(
                onTap: isTesting
                    ? null // Tidak bisa ditekan saat tes sedang berlangsung
                    : _startSpeedTest, // Menjalankan tes saat "START" ditekan
                child: Container(
                  width:
                      circleSize - (2 * borderWidth), // Ukuran lingkaran dalam
                  height:
                      circleSize - (2 * borderWidth), // Ukuran lingkaran dalam
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black, // Latar belakang hitam
                  ),
                  child: Center(
                    child: isTesting
                        ? CircularProgressIndicator(
                            // Tampilkan loading saat tes sedang berjalan
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          )
                        : Text(
                            'START',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600, // Semi Bold
                              fontSize:
                                  startTextSize, // Ukuran font "START" responsif
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
              height: screenHeight *
                  0.03), // Jarak antara lingkaran dan teks di bawahnya
          Text(
            isConnected
                ? 'Connected to the internet'
                : 'Check connection, \ninternet not connected', // Mengubah teks berdasarkan status koneksi
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w300, // Light
              fontSize: statusTextSize, // Ukuran teks status responsif
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
