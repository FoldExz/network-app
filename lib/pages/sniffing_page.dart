import 'dart:async';
import 'dart:math';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_network_inspector/models/inspector_result.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../utils/sniffing_helper.dart';
import '../utils/network_check.dart';

class NetworkStatusPopup extends StatelessWidget {
  final double successRate;
  final int avgResponseTime;
  final int totalDataReceived;
  final int blockedPackets; // Keep this declaration
  final int successfulPackets; // Declare this field correctly

  const NetworkStatusPopup({
    super.key,
    required this.successRate,
    required this.avgResponseTime,
    required this.totalDataReceived,
    required this.blockedPackets, // Keep this in the constructor
    required this.successfulPackets, // Add this to the constructor
  });

  @override
  Widget build(BuildContext context) {
    var mediaQuery = MediaQuery.of(context);
    double screenWidth = mediaQuery.size.width;

    String networkStatusText = blockedPackets > 0
        ? 'Terdapat paket yang diblokir: $blockedPackets'
        : 'Semua paket berhasil diterima';

    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 70.0, top: 20.0),
        child: Container(
          width: screenWidth * 0.9,
          decoration: BoxDecoration(
            color: const Color(0xFF15181F).withOpacity(0.9),
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                networkStatusText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Icon(
                    blockedPackets > 0 ? Icons.error : Icons.check_circle,
                    color: blockedPackets > 0 ? Colors.red : Colors.green,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Status Jaringan: ${blockedPackets > 0 ? "Terdapat paket yang diblokir: $blockedPackets" : "Semua paket berhasil diterima"}',
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.show_chart, color: Colors.blue),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Rata-rata waktu respons: $avgResponseTime ms',
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.save_alt, color: Colors.grey),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Total data yang diterima: $totalDataReceived KB',
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.block, color: Colors.red),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Total paket yang diblokir: $blockedPackets',
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Jumlah paket yang berhasil: $successfulPackets',
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SniffingPage extends StatefulWidget {
  const SniffingPage({super.key});

  @override
  _SniffingPageState createState() => _SniffingPageState();
}

class _SniffingPageState extends State<SniffingPage> {
  bool isStarted = false;
  final FNICLient _client = FNICLient();
  final List<InspectorResult> _sniffedData = [];
  Timer? _timer; // Menambahkan Timer

  @override
  void initState() {
    super.initState();
    FNICLient.inspectorNotifierList.addListener(_updateSniffedData);
  }

  @override
  void dispose() {
    FNICLient.inspectorNotifierList.removeListener(_updateSniffedData);
    _timer?.cancel(); // Hentikan timer saat dispose
    _client.close();
    super.dispose();
  }

  void _updateSniffedData() {
    final sniffedData = FNICLient.inspectorNotifierList.value;

    setState(() {
      _sniffedData.clear(); // Kosongkan data sebelumnya
      _sniffedData.addAll(sniffedData); // Menambahkan data yang baru
    });
  }

  void _calculateNetworkMetrics() {
    if (_sniffedData.isEmpty) return;

    // Hitung permintaan yang berhasil
    int successfulRequests = _sniffedData
        .where((result) =>
            result.statusCode != null &&
            result.statusCode! >= 200 &&
            result.statusCode! < 300)
        .length;

    // Hitung permintaan yang "diblokir" atau gagal (kode 400 dan 500)
    int blockedPackets = _sniffedData
        .where((result) =>
            result.statusCode != null &&
            (result.statusCode! >= 400 && result.statusCode! < 600))
        .length;

    // Total semua permintaan yang tercatat
    double successRate = (successfulRequests / _sniffedData.length) * 100;

    int totalResponseTime = 0;
    int totalDataReceived = 0;

    // Kalkulasi waktu respons rata-rata dan total data yang diterima
    for (var result in _sniffedData) {
      if (result.startTime != null && result.endTime != null) {
        int responseTime =
            result.endTime!.difference(result.startTime!).inMilliseconds;
        totalResponseTime += responseTime;
      }
      totalDataReceived += result.responseBodyBytes ?? 0;
    }

    int avgResponseTime = _sniffedData.isNotEmpty
        ? (totalResponseTime / _sniffedData.length).round()
        : 0;

    // Tampilkan hasil metrik di popup
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return NetworkStatusPopup(
          successRate: successRate,
          avgResponseTime: avgResponseTime,
          totalDataReceived:
              (totalDataReceived / 1024).round(), // Konversi ke KB
          blockedPackets: blockedPackets,
          successfulPackets: successfulRequests, // Pass this value
        );
      },
    );
  }

  void _toggleStart() {
    setState(() {
      isStarted = !isStarted;
      _client.setEnableLogging(isStarted);

      if (isStarted) {
        print("Sniffing started: $isStarted");

        // Kosongkan data di _sniffedData dan inspectorNotifierList
        _sniffedData.clear();

        // Atur inspectorNotifierList.value menjadi list kosong, memicu notifyListeners secara otomatis
        FNICLient.inspectorNotifierList.value = [];

        _startRequestLoop();
      } else {
        print("Sniffing stopped: $isStarted");
        _timer?.cancel();
        _calculateNetworkMetrics(); // Hitung dan tampilkan metrik
      }
    });
  }

  void _startRequestLoop() {
    // Mengatur timer untuk mengirimkan permintaan setiap 0.5 detik
    _timer = Timer.periodic(const Duration(milliseconds: 500), (timer) async {
      await _makeRequest();
    });
  }

  Future<void> _makeRequest() async {
    if (!isStarted) return; // Pastikan sniffing aktif

    // Pengecekan koneksi internet menggunakan fungsi checkInternetConnection
    bool hasInternet = await NetworkCheck.isInternetAvailable();
    if (!hasInternet) {
      print("Tidak ada koneksi internet.");

      // Mengatur hasil sniffing untuk koneksi yang buruk
      InspectorResult result = InspectorResult(
        url: Uri.parse("https://jsonplaceholder.typicode.com"),
        startTime: DateTime.now(),
        statusCode: null,
        reasonPhrase: 'No Internet Connection',
        responseBodyBytes: 0,
        endTime: DateTime.now(),
      );

      // Tambahkan hasil ke inspectorNotifierList untuk memicu notifyListeners
      final updatedList =
          List<InspectorResult>.from(FNICLient.inspectorNotifierList.value);
      updatedList.add(result);
      FNICLient.inspectorNotifierList.value = updatedList;

      return;
    }

    try {
      // Daftar endpoint yang bisa dipilih secara acak
      List<String> endpoints = [
        '/posts',
        '/posts/1',
        '/posts/1/comments',
        '/comments?postId=1',
        '/posts', // Untuk POST
        '/posts/1', // Untuk PUT dan PATCH
        '/posts/1', // Untuk DELETE
      ];

      // Pilih endpoint secara acak
      String selectedEndpoint = endpoints[Random().nextInt(endpoints.length)];

      // Tentukan metode HTTP berdasarkan endpoint yang dipilih
      String requestMethod;
      if (selectedEndpoint == '/posts') {
        requestMethod = 'POST';
      } else if (selectedEndpoint == '/posts/1') {
        requestMethod = Random().nextBool() ? 'PUT' : 'PATCH';
      } else if (selectedEndpoint == '/posts/1') {
        requestMethod = 'DELETE';
      } else {
        requestMethod = 'GET';
      }

      print(
          "Sending request to https://jsonplaceholder.typicode.com$selectedEndpoint");

      // Kirim permintaan sesuai metode yang ditentukan
      http.Response response;
      if (requestMethod == 'POST') {
        response = await _client.post(
          Uri.parse('https://jsonplaceholder.typicode.com$selectedEndpoint'),
          body: {'title': 'New Post', 'body': 'This is a new post.'},
        );
      } else if (requestMethod == 'PUT' || requestMethod == 'PATCH') {
        response = await _client.put(
          Uri.parse('https://jsonplaceholder.typicode.com$selectedEndpoint'),
          body: {
            'title': 'Updated Post',
            'body': 'This post has been updated.'
          },
        );
      } else if (requestMethod == 'DELETE') {
        response = await _client.delete(
          Uri.parse('https://jsonplaceholder.typicode.com$selectedEndpoint'),
        );
      } else {
        response = await _client.get(
          Uri.parse('https://jsonplaceholder.typicode.com$selectedEndpoint'),
        );
      }

      if (response.statusCode == 200) {
        print("Response status: ${response.statusCode}");
        print("Response body: ${response.body}");
      } else {
        print("Error: ${response.statusCode} ${response.reasonPhrase}");
      }
    } catch (e) {
      print("Connection error: $e");

      // Mengatur hasil sniffing untuk koneksi yang buruk
      InspectorResult result = InspectorResult(
        url: Uri.parse("https://jsonplaceholder.typicode.com"),
        startTime: DateTime.now(),
        statusCode: null,
        reasonPhrase: 'Connection Error',
        responseBodyBytes: 0,
        endTime: DateTime.now(),
      );

      // Tambahkan hasil ke inspectorNotifierList untuk memicu notifyListeners
      final updatedList =
          List<InspectorResult>.from(FNICLient.inspectorNotifierList.value);
      updatedList.add(result);
      FNICLient.inspectorNotifierList.value = updatedList;
    }
  }

  void _saveSniffedData() async {
    try {
      // Mendapatkan direktori penyimpanan eksternal untuk folder Downloads
      final directory = await getExternalStorageDirectory();
      final downloadDirectory = Directory('${directory?.path}/Download');
      // Membuat folder Download jika belum ada
      if (!await downloadDirectory.exists()) {
        await downloadDirectory.create(recursive: true);
      }

      final filePath = '${downloadDirectory.path}/sniffed_data.txt';

      // Membuat string dari data yang akan disimpan
      final dataToSave = _sniffedData.map((result) {
        return '''
      Start Time: ${formatDateTime(result.startTime)}
      Status Code: ${result.statusCode ?? '-'}
      Protocol: ${result.url?.scheme.toUpperCase() ?? '-'}
      Host: ${result.url?.host ?? '-'}
      Path: ${result.url?.path ?? '-'}
      Response Size: ${(result.responseBodyBytes ?? 0) / 1024} KB
      Message: ${result.reasonPhrase ?? '-'}
      ''';
      }).join('\n---\n');

      // Menyimpan data ke dalam file teks
      final file = File(filePath);
      await file.writeAsString(dataToSave);

      // Menampilkan notifikasi bahwa data berhasil disimpan
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Data berhasil disimpan di $filePath')),
      );
    } catch (e) {
      // Menampilkan notifikasi jika terjadi error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan data: $e')),
      );
    }
  }

  void _shareData() async {
    try {
      // Mendapatkan direktori penyimpanan eksternal untuk folder Downloads
      final directory = await getExternalStorageDirectory();
      final downloadDirectory = Directory('${directory?.path}/Download');
      final filePath = '${downloadDirectory.path}/sniffed_data.txt';

      // Memeriksa apakah file ada
      final file = File(filePath);
      if (await file.exists()) {
        // Create an XFile from the file path
        final xFile = XFile(file.path);

        // Menggunakan Share untuk membagikan file
        await Share.shareXFiles([xFile], text: 'Data hasil sniffing Anda');
      } else {
        // Menampilkan notifikasi jika file tidak ditemukan
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('File tidak ditemukan: $filePath')),
        );
      }
    } catch (e) {
      // Menampilkan notifikasi jika terjadi error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal membagikan data: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    var mediaQuery = MediaQuery.of(context);
    double screenWidth = mediaQuery.size.width;

    double headerHeight = 28;
    double rowHeight = 22;
    double noWidth = screenWidth * 0.09;
    double timeWidth = screenWidth * 0.11;
    double sourceWidth = screenWidth * 0.19;
    double destinationWidth = screenWidth * 0.19;
    double protoWidth = screenWidth * 0.13;
    double lengthWidth = screenWidth * 0.13;
    double infoWidth = screenWidth * 0.15;

    return Scaffold(
      body: Column(
        children: [
          const SizedBox(height: 50),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Packet Capture',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    GestureDetector(
                      onTap: _toggleStart,
                      child: SvgPicture.asset(
                        'assets/icons/start.svg',
                        color: isStarted ? const Color(0xFF666666) : null,
                        height: 24,
                        width: 24,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: isStarted ? _toggleStart : null,
                      child: SvgPicture.asset(
                        'assets/icons/stop.svg',
                        color: isStarted ? null : const Color(0xFF666666),
                        height: 24,
                        width: 24,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _saveSniffedData,
                      child: SvgPicture.asset(
                        'assets/icons/save.svg',
                        height: 24,
                        width: 24,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _shareData,
                      child: SvgPicture.asset(
                        'assets/icons/share.svg',
                        height: 24,
                        width: 24,
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
          Container(
            color: const Color(0xFF14172A),
            height: headerHeight,
            child: Row(
              children: [
                _buildTableHeader('No.', noWidth),
                _buildTableHeader('Time', timeWidth),
                _buildTableHeader('Source', sourceWidth),
                _buildTableHeader('Path', destinationWidth),
                _buildTableHeader('Proto.', protoWidth),
                _buildTableHeader('Length', lengthWidth),
                _buildTableHeader('Info', infoWidth),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: _sniffedData.asMap().entries.map((entry) {
                  int index = entry.key + 1;
                  InspectorResult data = entry.value;

                  // Mendapatkan informasi protokol
                  String protocol = data.url?.scheme.toUpperCase() ?? '-';

                  // Menyusun informasi untuk kolom Info
                  String info =
                      '${data.reasonPhrase} ${data.statusCode ?? '-'}';

                  // Membungkus baris dengan GestureDetector untuk interaksi klik
                  return GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/details',
                        arguments:
                            data, // Mengirimkan objek data ke DetailsScreen
                      );
                    },
                    child: Row(
                      children: [
                        _buildTableCell(index.toString(), noWidth, rowHeight),
                        _buildTableCell(
                            data.startTime?.toIso8601String() ?? '-',
                            timeWidth,
                            rowHeight),
                        _buildTableCell(
                            data.url?.host ?? '-', sourceWidth, rowHeight),
                        _buildTableCell(
                            data.url?.path ?? '-', destinationWidth, rowHeight),
                        _buildTableCell(protocol, protoWidth, rowHeight),
                        _buildTableCell(
                            data.responseBodyBytes?.toString() ?? '-',
                            lengthWidth,
                            rowHeight),
                        _buildTableCell(info, infoWidth, rowHeight),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader(String title, double width) {
    return Container(
      width: width,
      height: 28,
      alignment: Alignment.centerLeft,
      color: const Color(0xFF14172A),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        title,
        style: const TextStyle(
            fontFamily: 'Poppins', fontSize: 10, color: Colors.white),
      ),
    );
  }

  Widget _buildTableCell(String content, double width, double height) {
    return Container(
      width: width,
      height: height,
      alignment: Alignment.centerLeft,
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        content,
        style: const TextStyle(fontFamily: 'Poppins', fontSize: 10),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

String formatDateTime(DateTime? dateTime) {
  if (dateTime == null) return '-';
  return '${dateTime.hour}:${dateTime.minute}:${dateTime.second}';
}
