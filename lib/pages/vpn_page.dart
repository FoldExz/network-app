import 'package:flutter/material.dart';

class VPNPage extends StatefulWidget {
  const VPNPage({super.key});

  @override
  _VPNPageState createState() => _VPNPageState();
}

class _VPNPageState extends State<VPNPage> {
  bool isConnected = false;
  bool isConnecting = false;

  // Fungsi untuk mengatur status toggle
  void _toggleVPN() {
    setState(() {
      if (!isConnected && !isConnecting) {
        // Ketika tombol di-klik saat disconnected, akan memulai proses connecting
        isConnecting = true;
        Future.delayed(const Duration(seconds: 3), () {
          setState(() {
            isConnected = true;
            isConnecting = false; // Setelah 3 detik, set to connected
          });
        });
      } else if (isConnected) {
        // Jika sudah terhubung, klik akan memutuskan koneksi
        isConnected = false;
        isConnecting = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Menggunakan ukuran layar untuk membuat responsive
    double screenWidth = MediaQuery.of(context).size.width;
    double toggleWidth = screenWidth * 0.5; // 50% dari lebar layar
    double toggleHeight = toggleWidth * (252 / 444); // Rasio 444x252 px
    double circleSize = toggleHeight * 0.63; // Ukuran lingkaran dalam toggle

    // Ukuran font untuk detail
    double detailFontSize = 18.0; // Ukuran font detail

    return Scaffold(
      backgroundColor: Colors.black, // Latar belakang hitam
      body: Center(
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.start, // Mengatur agar toggle tidak ke tengah
          crossAxisAlignment: CrossAxisAlignment.center, // Rata tengah
          children: [
            const SizedBox(
                height: 260), // Jarak 50 piksel antara atas app dan toggle
            // Toggle Switch
            GestureDetector(
              onTap: _toggleVPN, // Fungsi saat toggle ditekan
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300), // Animasi smooth
                width: toggleWidth,
                height: toggleHeight,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isConnected || isConnecting
                        ? const [
                            Color(0xFFFF69B4),
                            Color(0xFFFF74B6),
                            Color(0xFFFFB6C1),
                          ]
                        : const [
                            Color(0xFF888888),
                            Color(0xFF575757),
                            Color(0xFF373737),
                          ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(
                      120), // Bentuk lonjong sesuai ukuran baru
                ),
                child: Stack(
                  children: [
                    // Lingkaran putih di dalam toggle
                    AnimatedAlign(
                      duration: const Duration(milliseconds: 300),
                      alignment: isConnected || isConnecting
                          ? Alignment.centerRight
                          : Alignment.centerLeft, // Posisi lingkaran
                      child: Container(
                        width: circleSize,
                        height: circleSize,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20), // Jarak antara toggle dan teks
            // Teks status berdasarkan koneksi
            Text(
              isConnecting
                  ? 'Connecting...'
                  : isConnected
                      ? 'Connected'
                      : 'Disconnected',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: screenWidth *
                    0.07, // Ukuran teks status (10% dari lebar layar)
                fontWeight: FontWeight.normal, // Regular
                color: Colors.white,
              ),
            ),
            // Jika statusnya "Connected", tampilkan detail di bawahnya
            if (isConnected) ...[
              const SizedBox(height: 30), // Jarak antar teks lebih kecil
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow(
                        'DNS protocol status', 'DoH', detailFontSize),
                    const SizedBox(height: 10),
                    _buildDetailRow(
                        'Colocation center', 'New York', detailFontSize),
                    const SizedBox(height: 10),
                    _buildDetailRow('Connection type', 'Wi-Fi', detailFontSize),
                    const SizedBox(height: 10),
                    _buildDetailRow('Public IP', '23.45.67.89', detailFontSize,
                        isBold: true),
                    const SizedBox(height: 10),
                    _buildDetailRow(
                        'Device info', 'Infinix Zero 5G 2023', detailFontSize,
                        isBold: true),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Fungsi untuk membangun baris detail dengan label dan hasil
  Widget _buildDetailRow(String label, String value, double fontSize,
      {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start, // Rata kiri
      children: [
        // Label
        Expanded(
          flex: 5,
          child: Text(
            '$label: ',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: fontSize, // Ukuran font yang diatur
              fontWeight: FontWeight.w200, // ExtraLight
              color: Colors.white,
            ),
          ),
        ),
        // Hasil
        Expanded(
          flex: 4,
          child: Text(
            value,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: fontSize, // Ukuran font yang diatur
              fontWeight: isBold
                  ? FontWeight.w600
                  : FontWeight.w300, // Semibold atau Light
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
