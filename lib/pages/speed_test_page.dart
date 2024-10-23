import 'package:flutter/material.dart';
import 'package:speed_test_dart/classes/classes.dart';
import 'package:speed_test_dart/speed_test_dart.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';
import 'dart:math' as math;

class SpeedTestPage extends StatefulWidget {
  const SpeedTestPage({super.key});

  @override
  _SpeedTestPageState createState() => _SpeedTestPageState();
}

class _SpeedTestPageState extends State<SpeedTestPage>
    with SingleTickerProviderStateMixin {
  SpeedTestDart tester = SpeedTestDart();
  List<Server> bestServersList = [];
  double downloadSpeed = 0.0;
  double uploadSpeed = 0.0;
  bool isTesting = false;
  bool isConnected =
      false; // Ubah ini menjadi false untuk mode "internet not connected"
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    // setBestServers();
    _checkConnection();
    Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> results) {
      setState(() {
        isConnected = results.contains(ConnectivityResult.mobile) ||
            results.contains(ConnectivityResult.wifi);
      });
    });
    _rotationController = AnimationController(
      duration:
          const Duration(seconds: 5), // Durasi 2 detik untuk satu rotasi penuh
      vsync: this,
    );
  }

  Future<void> setBestServers() async {
    final settings = await tester.getSettings();
    final servers = settings.servers;

    final BestServersList = await tester.getBestServers(
      servers: servers,
    );

    setState(() {
      bestServersList = BestServersList;
    });
  }

  void _startSpeedTest() async {
    setState(() {
      isTesting = true; // Menandai pengujian sedang berlangsung
      _rotationController.repeat(); // Mulai animasi berputar
    });

    if (bestServersList.isNotEmpty) {
      downloadSpeed = await tester.testDownloadSpeed(servers: bestServersList);
      uploadSpeed = await tester.testUploadSpeed(servers: bestServersList);
    }

    setState(() {
      isTesting = false; // Menandai pengujian selesai
      _rotationController.stop(); // Hentikan animasi berputar
    });
  }

  void _checkConnection() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    print("Connectivity result: $connectivityResult"); // Menambahkan logging

    setState(() {
      // Update isConnected berdasarkan hasil pemeriksaan koneksi
      isConnected = connectivityResult == ConnectivityResult.mobile ||
          connectivityResult == ConnectivityResult.wifi;
    });
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
          GestureDetector(
            onTap: _startSpeedTest,
            child: Stack(
              alignment: Alignment.center, // Menjaga teks tetap di tengah
              children: [
                // Lingkaran luar
                AnimatedBuilder(
                  animation: _rotationController,
                  builder: (context, child) {
                    return Transform.rotate(
                        angle: _rotationController.value *
                            2 *
                            math.pi, // Lingkaran berputar
                        child: Container(
                          width: circleSize, // Ukuran lingkaran responsif
                          height: circleSize, // Ukuran lingkaran responsif
                          decoration: BoxDecoration(
                            gradient: isConnected
                                ? const LinearGradient(
                                    colors: [
                                      Color.fromARGB(255, 1, 67, 65),
                                      Color.fromARGB(255, 27, 173, 146),
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
                          ),
                        ));
                  },
                ),
                // Teks START di tengah lingkaran
                Container(
                  width:
                      circleSize - (2 * borderWidth), // Ukuran lingkaran dalam
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
                        fontSize:
                            startTextSize, // Ukuran font "START" responsif
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(
              height: screenHeight *
                  0.03), // Jarak antara lingkaran dan teks di bawahnya
          Text(
            isConnected
                ? 'Connected to the internet'
                // ignore: dead_code
                : 'internet not connected', // Mengubah teks berdasarkan status koneksi
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w300, // Light
              fontSize: statusTextSize, // Ukuran teks status responsif
              color: Colors.white,
            ),
          ),
          if (isTesting == true) ...[
            SizedBox(
                height: screenHeight * 0.03), // Jarak tambahan saat testing
            Text(
              'Download Speed: ${downloadSpeed.toStringAsFixed(2)} Mbps',
              style: const TextStyle(color: Colors.white, fontSize: 20),
            ),
            Text(
              'Upload Speed: ${uploadSpeed.toStringAsFixed(2)} Mbps',
              style: const TextStyle(color: Colors.white, fontSize: 20),
            ),
          ],
        ],
      ),
    );
  }
}
