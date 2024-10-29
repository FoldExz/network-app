import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_network_inspector/client/network_inspector_client.dart';
import 'package:flutter_network_inspector/models/inspector_result.dart';

class SniffingPage extends StatefulWidget {
  const SniffingPage({super.key});

  @override
  _SniffingPageState createState() => _SniffingPageState();
}

class _SniffingPageState extends State<SniffingPage> {
  bool isStarted = false;
  final FNICLient _client = FNICLient();
  final List<InspectorResult> _sniffedData = [];

  @override
  void initState() {
    super.initState();
    FNICLient.inspectorNotifierList.addListener(_updateSniffedData);
  }

  @override
  void dispose() {
    FNICLient.inspectorNotifierList.removeListener(_updateSniffedData);
    _client.close();
    super.dispose();
  }

  void _updateSniffedData() {
    setState(() {
      _sniffedData.clear();
      _sniffedData.addAll(FNICLient.inspectorNotifierList.value);
    });
  }

  void _toggleStart() {
    setState(() {
      isStarted = !isStarted;
      _client.setEnableLogging(isStarted); // Logging aktif saat sniffing mulai
    });
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
                _buildTableHeader('Destination', destinationWidth),
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

                  return Row(
                    children: [
                      _buildTableCell(index.toString(), noWidth, rowHeight),
                      _buildTableCell(data.startTime?.toIso8601String() ?? '-',
                          timeWidth, rowHeight),
                      _buildTableCell(
                          data.url?.host ?? '-', sourceWidth, rowHeight),
                      _buildTableCell(
                          data.url?.path ?? '-', destinationWidth, rowHeight),
                      _buildTableCell(data.statusCode?.toString() ?? '-',
                          protoWidth, rowHeight),
                      _buildTableCell(data.responseBodyBytes?.toString() ?? '-',
                          lengthWidth, rowHeight),
                      _buildTableCell(
                          data.reasonPhrase ?? '-', infoWidth, rowHeight),
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
