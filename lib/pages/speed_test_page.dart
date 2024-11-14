import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../utils/network_check.dart';

class SpeedTestPage extends StatefulWidget {
  const SpeedTestPage({super.key});

  @override
  _SpeedTestPageState createState() => _SpeedTestPageState();
}

class _SpeedTestPageState extends State<SpeedTestPage> {
  bool isConnected = true;
  double? downloadSpeed;
  double? uploadSpeed;
  bool isTesting = false;
  Timer? _progressTimer;
  StreamSubscription<bool>? _internetSubscription;
  int progressPercent = 0; // Untuk menyimpan persen progres

  final String downloadUrl =
      // 'http://192.168.100.11:3000/download/largeFile.bin';
      // 'http://hil.icmp.hetzner.com/100MB.bin';
      // 'http://ash.icmp.hetzner.com/100MB.bin';
      // 'https://fsn1-speed.hetzner.com/100MB.bin';
      'https://hel1-speed.hetzner.com/100MB.bin';
  final String uploadUrl = 'http://192.168.137.79:3000/upload';

  @override
  void initState() {
    super.initState();

    // Mendengarkan status koneksi internet

    _internetSubscription = NetworkCheck.internetStatusStream.listen((status) {
      setState(() {
        isConnected = status;
      });
    });
  }

  @override
  void dispose() {
    _progressTimer?.cancel(); // Batalkan timer jika ada

    _internetSubscription
        ?.cancel(); // Membatalkan subscription ketika widget dibuang

    super.dispose();
  }

  Future<void> _startSpeedTest() async {
    print("Speed test started");

    setState(() {
      isTesting = true;
      downloadSpeed = null;
      uploadSpeed = null;
      progressPercent = 0; // Reset persen progres
    });

    // Mulai animasi progres
    _startProgressAnimation();

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

    // Setelah tes selesai, lanjutkan progres ke 100%
    if (mounted) {
      setState(() {
        progressPercent = 100; // Progres akan jadi 100% jika tes selesai
      });
    }

    _progressTimer?.cancel(); // Menghentikan animasi saat tes selesai
  }

  // Fungsi untuk memulai animasi progres
  void _startProgressAnimation() {
    _progressTimer = Timer.periodic(Duration(milliseconds: 100), (timer) {
      if (isTesting && progressPercent < 98) {
        setState(() {
          progressPercent += 2; // Tambah progres 2% setiap 100ms hingga 89%
        });
      } else if (!isTesting && progressPercent < 100) {
        setState(() {
          progressPercent += 1; // Lanjutkan progres ke 100 setelah tes selesai
        });
      } else {
        _progressTimer?.cancel(); // Berhenti jika sudah 100% atau tes selesai
      }
    });
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
    print("Starting download test...");
    try {
      final stopwatch = Stopwatch()..start();
      final response = await http.get(Uri.parse(downloadUrl));

      if (response.statusCode == 200) {
        stopwatch.stop();
        int bytes = response.contentLength ?? response.bodyBytes.length;
        double seconds = stopwatch.elapsedMilliseconds / 1000;
        double speedMbps = (bytes / seconds) / (1024 * 1024) * 8;

        String fileSize = convertSize(
            bytes); // Mengonversi ukuran file ke format yang lebih mudah dibaca
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
    print("Starting upload test...");
    try {
      final stopwatch = Stopwatch()..start();

      var request = http.MultipartRequest('POST', Uri.parse(uploadUrl));
      var file = http.MultipartFile.fromBytes(
        'file',
        List<int>.generate(104857600, (index) => index % 256),
        filename: 'filedummy.txt',
      );
      request.files.add(file);

      var response = await request.send();
      stopwatch.stop();

      int bytesSent = file.length;
      double seconds = stopwatch.elapsedMilliseconds / 1000;
      double speedMbps = (bytesSent / seconds) / (1024 * 1024) * 8;

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

  String getSpeedCategory(double speed) {
    if (speed >= 50) {
      return "Your internet is very fast!";
    } else if (speed >= 10) {
      return "Your internet is fast!";
    } else {
      return "Your internet is slow!";
    }
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
                      isTesting ? '$progressPercent%' : 'START',
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
          // Tambahkan dua baris jarak
          SizedBox(height: screenHeight * 0.05),
          // Tampilkan kategori kecepatan internet berdasarkan hasil download speed
          if (downloadSpeed != null)
            Text(
              getSpeedCategory(downloadSpeed!),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
                fontSize: statusTextSize,
                color: Colors.white,
              ),
            ),
        ],
      ),
    );
  }
}
