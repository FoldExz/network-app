import 'package:flutter/material.dart';

class SpeedTestPage extends StatelessWidget {
  const SpeedTestPage({super.key});

  @override
  Widget build(BuildContext context) {
    bool isConnected =
        true; // Ubah ini menjadi false untuk mode "internet not connected"

    // Mengambil ukuran layar yang tersedia
    var mediaQuery = MediaQuery.of(context);
    double screenWidth = mediaQuery.size.width;
    double screenHeight = mediaQuery.size.height;

    // Membuat ukuran lingkaran proporsional baik berdasarkan lebar maupun tinggi
    double circleSize =
        (screenWidth < screenHeight ? screenWidth : screenHeight) *
            0.5; // 50% dari lebar atau tinggi, mana yang lebih kecil
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
                  // ignore: dead_code
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
              child: Container(
                width: circleSize - (2 * borderWidth), // Ukuran lingkaran dalam
                height:
                    circleSize - (2 * borderWidth), // Ukuran lingkaran dalam
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black, // Latar belakang hitam
                ),
                child: Center(
                  child: Text(
                    'START',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600, // Semi Bold
                      fontSize: startTextSize, // Ukuran font "START" responsif
                      color: Colors.white,
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
                // ignore: dead_code
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
