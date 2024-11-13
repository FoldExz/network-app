import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../utils/network_check.dart';
import 'dart:math';

class SpeedTestPage extends StatefulWidget {
  const SpeedTestPage({super.key});

  @override
  _SpeedTestPageState createState() => _SpeedTestPageState();
}

class _SpeedTestPageState extends State<SpeedTestPage> {
  bool isConnected = true;
  double? downloadSpeed;
  double? uploadSpeed;
  StreamSubscription<bool>? _internetSubscription;
  bool isTesting = false;

  // URL untuk pengujian download dan upload
  final String downloadUrl =
      'https://hel1-speed.hetzner.com/100MB.bin'; // URL download baru
  final String uploadUrl =
      'http://192.168.100.11:3000/upload'; // URL upload server lokal

  @override
  void initState() {
    super.initState();
    _internetSubscription = NetworkCheck.internetStatusStream.listen((status) {
      setState(() {
        isConnected = status;
      });
    });
  }

  @override
  void dispose() {
    _internetSubscription?.cancel();
    super.dispose();
  }

  Future<void> _startSpeedTest() async {
    print("Speed test started");

    setState(() {
      isTesting = true;
      downloadSpeed = null;
      uploadSpeed = null;
    });

    // Menjalankan pengujian download dan upload secara paralel
    var downloadFuture = _testDownloadSpeed();
    var uploadFuture = _testUploadSpeed();

    var results = await Future.wait([downloadFuture, uploadFuture]);

    // Mendapatkan hasil pengujian download dan upload
    double? download = results[0];
    double? upload = results[1];

    print(
        "Speed test finished. Download: $download Mbps, Upload: $upload Mbps");

    if (mounted) {
      setState(() {
        downloadSpeed = download;
        uploadSpeed = upload ?? -1.0; // Menandakan upload gagal jika null
        isTesting = false;
      });
    }
  }

  // Fungsi untuk mengonversi ukuran byte ke format yang lebih mudah dibaca (B, KB, MB, GB)
  String convertSize(int sizeBytes) {
    if (sizeBytes == 0) {
      return "0B";
    }
    List<String> sizeName = [
      "B",
      "KB",
      "MB",
      "GB",
      "TB",
      "PB",
      "EB",
      "ZB",
      "YB"
    ];
    int i = (log(sizeBytes) / log(1024)).floor();
    num p = pow(1024, i);
    double s = (sizeBytes / p).roundToDouble();
    return "${s.toString()}${sizeName[i]}";
  }

  Future<double?> _testDownloadSpeed() async {
    print("Starting download speed test...");
    try {
      final stopwatch = Stopwatch()..start();
      final response = await http.get(Uri.parse(downloadUrl));

      if (response.statusCode == 200) {
        stopwatch.stop();
        // Jika tidak ada response.contentLength, gunakan bodyBytes.length
        int bytes = response.contentLength ?? response.bodyBytes.length;
        double seconds = stopwatch.elapsedMilliseconds / 1000;

        // Pastikan pembagian waktu dalam detik dan ukuran dalam byte yang tepat
        double speedMbps =
            (bytes * 8) / (seconds * 1024 * 1024); // Kecepatan dalam Mbps

        String fileSize = convertSize(bytes);
        print(
            "Download speed test successful: $speedMbps Mbps, File Size: $fileSize");

        return speedMbps;
      } else {
        print("Failed to download. Status Code: ${response.statusCode}");
      }
    } catch (e) {
      print("Download speed test failed: $e");
    }
    return null;
  }

  Future<double?> _testUploadSpeed() async {
    try {
      final stopwatch = Stopwatch()..start();

      // Menggunakan MultipartRequest untuk memastikan bahwa file di-upload dengan benar
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(uploadUrl),
      );

      // Menyiapkan file untuk di-upload
      var file = http.MultipartFile.fromBytes(
        'file', // field name sesuai yang digunakan di server ('file')
        List<int>.generate(
            104857600, (index) => index % 256), // Dummy 100MB data
        filename: 'filedummy.txt', // Nama file
      );

      // Menambahkan file ke body request
      request.files.add(file);

      // Kirim request
      var response = await request.send();
      stopwatch.stop();

      // Menghitung kecepatan upload berdasarkan data yang dikirim
      int bytesSent = file.length;
      double seconds = stopwatch.elapsedMilliseconds / 1000;
      double speedMbps = (bytesSent / seconds) / (1024 * 1024) * 8;

      // Mengecek respons
      if (response.statusCode == 200) {
        print("Upload speed: $speedMbps Mbps, Data Size: 100MB");
        return speedMbps;
      } else {
        print("Failed to upload data. Status Code: ${response.statusCode}");
      }
    } catch (e) {
      print("Upload speed test failed: $e");
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    var mediaQuery = MediaQuery.of(context);
    double screenWidth = mediaQuery.size.width;
    double screenHeight = mediaQuery.size.height;
    double circleSize =
        (screenWidth < screenHeight ? screenWidth : screenHeight) * 0.5;
    double borderWidth = circleSize * 0.025;
    double startTextSize = circleSize * 0.22;
    double statusTextSize = (screenWidth * 0.05).clamp(24, 50);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: isTesting ? null : _startSpeedTest,
            child: Container(
              width: circleSize,
              height: circleSize,
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
                  width: borderWidth,
                  color: Colors.transparent,
                ),
              ),
              child: Center(
                child: Container(
                  width: circleSize - (2 * borderWidth),
                  height: circleSize - (2 * borderWidth),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black,
                  ),
                  child: Center(
                    child: Text(
                      isTesting ? 'Testing...' : 'START',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        fontSize: startTextSize,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: screenHeight * 0.03),
          Text(
            isTesting
                ? 'Testing in progress...'
                : downloadSpeed != null
                    ? 'Download Speed: ${downloadSpeed!.toStringAsFixed(2)} Mbps\nUpload Speed: ${uploadSpeed == null ? 'failed' : uploadSpeed!.toStringAsFixed(2)} Mbps'
                    : isConnected
                        ? 'Connected to the internet'
                        : 'Check connection, \ninternet not connected',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w300,
              fontSize: statusTextSize,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
