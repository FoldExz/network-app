import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_network_inspector/models/inspector_result.dart';
import 'package:http/http.dart' as http;

class NetworkStatusPopup extends StatelessWidget {
  final double successRate;

  final int avgResponseTime;

  final int totalDataReceived;

  const NetworkStatusPopup({
    Key? key,
    required this.successRate,
    required this.avgResponseTime,
    required this.totalDataReceived,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var mediaQuery = MediaQuery.of(context);
    double screenWidth = mediaQuery.size.width;

    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding:
            EdgeInsets.only(bottom: 70.0, top: 20.0), // Ubah nilai padding atas
        child: Container(
          width: screenWidth * 0.9, // Atur lebar menjadi 90% dari lebar layar
          decoration: BoxDecoration(
            color: Color(0xFF15181F).withOpacity(0.9),
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Jaringan anda stabil',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Icon(Icons.check_box, color: Colors.green),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Jaringan stabil dengan ${successRate.toStringAsFixed(1)}% permintaan berhasil',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.show_chart, color: Colors.blue),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Rata-rata waktu respons: ${avgResponseTime} ms',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.save_alt, color: Colors.grey),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Total data yang diterima: ${totalDataReceived} KB',
                      style: TextStyle(color: Colors.white, fontSize: 16),
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
  String _networkAnalysisSummary = ''; // Menyimpan hasil analisis

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

  void _toggleStart() {
    setState(() {
      isStarted = !isStarted;
      _client.setEnableLogging(isStarted); // Mengatur logging

      if (isStarted) {
        print("Sniffing started: $isStarted");
        _sniffedData.clear(); // Kosongkan daftar data saat mulai
        _networkAnalysisSummary = ''; // Hapus analisis lama
        _startRequestLoop(); // Mulai loop permintaan
      } else {
        print("Sniffing stopped: $isStarted");
        _timer?.cancel(); // Hentikan timer saat berhenti
        // Tampilkan NetworkStatusPopup ketika berhenti
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent, // Agar tampak transparan
          builder: (BuildContext context) {
            return NetworkStatusPopup(
              successRate: 98.5, // Ganti dengan data yang sebenarnya
              avgResponseTime: 150, // Ganti dengan data yang sebenarnya
              totalDataReceived: 1024, // Ganti dengan data yang sebenarnya
            );
          },
        );
      }
    });
  }

  void _startRequestLoop() {
    // Mengatur timer untuk mengirimkan permintaan setiap 2 detik
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      await _makeRequest();
    });
  }

  Future<void> _makeRequest() async {
    if (!isStarted) return; // Pastikan sniffing aktif

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
        requestMethod = 'GET';
      } else if (selectedEndpoint == '/posts/1') {
        requestMethod =
            Random().nextBool() ? 'PUT' : 'PATCH'; // 50/50 untuk PUT dan PATCH
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
            body: {'title': 'New Post', 'body': 'This is a new post.'});
      } else if (requestMethod == 'PUT' || requestMethod == 'PATCH') {
        response = await _client.put(
            Uri.parse('https://jsonplaceholder.typicode.com$selectedEndpoint'),
            body: {
              'title': 'Updated Post',
              'body': 'This post has been updated.'
            });
      } else if (requestMethod == 'DELETE') {
        response = await _client.delete(
            Uri.parse('https://jsonplaceholder.typicode.com$selectedEndpoint'));
      } else {
        response = await _client.get(
            Uri.parse('https://jsonplaceholder.typicode.com$selectedEndpoint'));
      }

      if (response.statusCode == 200) {
        print("Response status: ${response.statusCode}");
        print("Response body: ${response.body}");
      } else {
        print("Error: ${response.statusCode} ${response.reasonPhrase}");
      }
    } catch (e) {
      // Menangani kesalahan koneksi
      print("Connection error: $e");
      // Mengatur hasil sniffing untuk koneksi yang buruk
      InspectorResult result = InspectorResult(
        url: Uri.parse("https://jsonplaceholder.typicode.com"),
        startTime: DateTime.now(),
        statusCode: null,
        reasonPhrase: 'Connection Error',
        responseBodyBytes: 0,
      );
      FNICLient.inspectorNotifierList.value.add(result);
      FNICLient.inspectorNotifierList.notifyListeners();
    }
  }

  void _saveSniffedData() {
    // Implementasi penyimpanan data jika diperlukan
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
                  ],
                ),
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
                  String protocol =
                      data.url?.scheme.toUpperCase() ?? '-'; // HTTPS atau HTTP

                  // Menyusun informasi untuk kolom Info
                  String info =
                      '${data.reasonPhrase} ${data.statusCode ?? '-'}';

                  return Row(
                    children: [
                      _buildTableCell(index.toString(), noWidth, rowHeight),
                      _buildTableCell(data.startTime?.toIso8601String() ?? '-',
                          timeWidth, rowHeight),
                      _buildTableCell(
                          data.url?.host ?? '-', sourceWidth, rowHeight),
                      _buildTableCell(
                          data.url?.path ?? '-', destinationWidth, rowHeight),
                      _buildTableCell(protocol, protoWidth,
                          rowHeight), // Menampilkan Protokol
                      _buildTableCell(data.responseBodyBytes?.toString() ?? '-',
                          lengthWidth, rowHeight),
                      _buildTableCell(
                          info, infoWidth, rowHeight), // Menampilkan Info
                    ],
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

class FNICLient {
  static final ValueNotifier<List<InspectorResult>> inspectorNotifierList =
      ValueNotifier([]);

  Future<http.Response> get(Uri url, {Map<String, String>? headers}) async {
    InspectorResult result =
        InspectorResult(url: url, startTime: DateTime.now());
    inspectorNotifierList.value.add(result);
    inspectorNotifierList.notifyListeners();

    final response = await http.get(url, headers: headers);

    result.statusCode = response.statusCode;
    result.reasonPhrase = response.reasonPhrase;
    result.responseBodyBytes = response.bodyBytes.length;

    inspectorNotifierList.notifyListeners();
    return response;
  }

  Future<http.Response> post(Uri url,
      {Map<String, String>? headers, Object? body}) async {
    InspectorResult result =
        InspectorResult(url: url, startTime: DateTime.now());
    inspectorNotifierList.value.add(result);
    inspectorNotifierList.notifyListeners();

    final response = await http.post(url, headers: headers, body: body);

    result.statusCode = response.statusCode;
    result.reasonPhrase = response.reasonPhrase;
    result.responseBodyBytes = response.bodyBytes.length;

    inspectorNotifierList.notifyListeners();
    return response;
  }

  Future<http.Response> put(Uri url,
      {Map<String, String>? headers, Object? body}) async {
    InspectorResult result =
        InspectorResult(url: url, startTime: DateTime.now());
    inspectorNotifierList.value.add(result);
    inspectorNotifierList.notifyListeners();

    final response = await http.put(url, headers: headers, body: body);

    result.statusCode = response.statusCode;
    result.reasonPhrase = response.reasonPhrase;
    result.responseBodyBytes = response.bodyBytes.length;

    inspectorNotifierList.notifyListeners();
    return response;
  }

  Future<http.Response> patch(Uri url,
      {Map<String, String>? headers, Object? body}) async {
    InspectorResult result =
        InspectorResult(url: url, startTime: DateTime.now());
    inspectorNotifierList.value.add(result);
    inspectorNotifierList.notifyListeners();

    final response = await http.patch(url, headers: headers, body: body);

    result.statusCode = response.statusCode;
    result.reasonPhrase = response.reasonPhrase;
    result.responseBodyBytes = response.bodyBytes.length;

    inspectorNotifierList.notifyListeners();
    return response;
  }

  Future<http.Response> delete(Uri url, {Map<String, String>? headers}) async {
    InspectorResult result =
        InspectorResult(url: url, startTime: DateTime.now());
    inspectorNotifierList.value.add(result);
    inspectorNotifierList.notifyListeners();

    final response = await http.delete(url, headers: headers);

    result.statusCode = response.statusCode;
    result.reasonPhrase = response.reasonPhrase;
    result.responseBodyBytes = response.bodyBytes.length;

    inspectorNotifierList.notifyListeners();
    return response;
  }

  void setEnableLogging(bool enable) {
    // Implementasi untuk mengatur logging
  }

  void close() {
    // Implementasi untuk menutup koneksi jika diperlukan
  }
}
