import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SniffingPage extends StatefulWidget {
  const SniffingPage({super.key});

  @override
  _SniffingPageState createState() => _SniffingPageState();
}

class _SniffingPageState extends State<SniffingPage> {
  bool isStarted = false; // Menyimpan status mulai
  // Dummy data untuk tabel
  final List<Map<String, dynamic>> _dummyData = List.generate(10, (index) {
    return {
      "No": index + 1,
      "Time": "0.${index + 1}2:30:00",
      "Source": "192.168.1.${index + 1}",
      "Destination": "224.0.0.1",
      "Proto.": "MDNS",
      "Length": "330",
      "Info": "Standard query",
    };
  });

  // Fungsi untuk mengubah status mulai
  void _toggleStart() {
    setState(() {
      isStarted = !isStarted; // Mengubah status mulai
    });
  }

  @override
  Widget build(BuildContext context) {
    var mediaQuery = MediaQuery.of(context);
    double screenWidth = mediaQuery.size.width;

    // Menyesuaikan ukuran kolom
    double headerHeight = 28; // Tinggi header yang lebih kecil
    double rowHeight = 22; // Tinggi setiap baris yang lebih kecil
    double noWidth = screenWidth * 0.09; // 9% untuk No.
    double timeWidth = screenWidth * 0.11; // 11% untuk Time
    double sourceWidth = screenWidth * 0.19; // 19% untuk Source
    double destinationWidth = screenWidth * 0.19; // 19% untuk Destination
    double protoWidth =
        screenWidth * 0.13; // 13% untuk Proto. (diperbesar sedikit)
    double lengthWidth =
        screenWidth * 0.13; // 13% untuk Length (diperbesar sedikit)
    double infoWidth = screenWidth * 0.15; // 15% untuk Info (diperkecil)

    return Scaffold(
      body: Column(
        children: [
          const SizedBox(height: 50), // Jarak 20 piksel dari bagian atas
          // Menambahkan judul dan ikon di atas tabel
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
                        color: isStarted
                            ? const Color(0xFF666666)
                            : null, // Warna jika aktif
                        height: 24, // Ukuran ikon lebih besar
                        width: 24,
                      ),
                    ),
                    const SizedBox(width: 8), // Mengurangi jarak
                    GestureDetector(
                      onTap: isStarted ? () => _toggleStart() : null,
                      child: SvgPicture.asset(
                        'assets/icons/stop.svg',
                        color: isStarted
                            ? null
                            : const Color(0xFF666666), // Warna jika tidak aktif
                        height: 24, // Ukuran ikon lebih besar
                        width: 24,
                      ),
                    ),
                    const SizedBox(width: 8), // Mengurangi jarak
                    GestureDetector(
                      onTap: () {
                        // Implementasi fungsi save
                      },
                      child: SvgPicture.asset(
                        'assets/icons/save.svg',
                        height: 24, // Ukuran ikon lebih besar
                        width: 24,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Header Tabel
          Container(
            color: const Color(
                0xFF14172A), // Mengubah warna latar belakang menjadi hitam
            height: headerHeight,
            child: Row(
              children: [
                _buildTableHeader('No.', noWidth),
                _buildTableHeader('Time', timeWidth),
                _buildTableHeader('Source', sourceWidth),
                _buildTableHeader('Destination', destinationWidth),
                _buildTableHeader('Proto.', protoWidth),
                _buildTableHeader('Length', lengthWidth),
                _buildTableHeader('Info', infoWidth),
              ],
            ),
          ),
          // Tabel Data
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: _dummyData.map((data) {
                  return Row(
                    children: [
                      _buildTableCell(
                          data["No"].toString(), noWidth, rowHeight),
                      _buildTableCell(data["Time"], timeWidth, rowHeight),
                      _buildTableCell(data["Source"], sourceWidth, rowHeight),
                      _buildTableCell(
                          data["Destination"], destinationWidth, rowHeight),
                      _buildTableCell(data["Proto."], protoWidth, rowHeight),
                      _buildTableCell(data["Length"], lengthWidth, rowHeight),
                      _buildTableCell(data["Info"], infoWidth, rowHeight),
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
      alignment: Alignment.centerLeft, // Rata kiri
      color: const Color(0xFF14172A),
      padding: const EdgeInsets.symmetric(
          horizontal: 8), // Menambahkan padding horizontal
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
      alignment: Alignment.centerLeft, // Rata kiri
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white)),
      ),
      padding: const EdgeInsets.symmetric(
          horizontal: 8), // Menambahkan padding horizontal
      child: Text(
        content,
        style: const TextStyle(fontFamily: 'Poppins', fontSize: 10),
        overflow: TextOverflow.ellipsis, // Menambahkan pengendalian overflow
      ),
    );
  }
}
