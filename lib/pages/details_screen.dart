import 'package:flutter/material.dart';
import 'package:flutter_network_inspector/models/inspector_result.dart';
import 'package:flutter_network_inspector/utils/utils.dart';

class DetailsScreen extends StatelessWidget {
  const DetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Mengambil data InspectorResult dari argument di ModalRoute
    final data = ModalRoute.of(context)!.settings.arguments as InspectorResult;
    final success =
        (data.statusCode ?? 0) >= 200 && (data.statusCode ?? 0) < 300;

    return Scaffold(
      appBar: AppBar(
        elevation: 3,
        centerTitle: true,
        backgroundColor: const Color(0xFF14172A), // Background warna #14172A
        title: const Text(
          'Details',
          style: TextStyle(
            color: Colors.white, // Mengubah warna teks menjadi putih #FFFFFF
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 5, 20, 20),
          children: [
            _buildRow('Start Time', formatDateTime(data.startTime)),
            _buildRow('Status Code', data.statusCode?.toString() ?? '-'),
            _buildRow('Protocol', data.url?.scheme.toUpperCase() ?? '-'),
            _buildRow('Host', data.url?.host ?? '-'),
            _buildRow('Path', data.url?.path ?? '-'),
            _buildRow(
              'Response Size',
              '${(data.responseBodyBytes ?? 0) / 1024} KB',
            ),
            _buildRow(
              success ? 'Reason Phrase' : 'Error Message',
              data.reasonPhrase ?? '-',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }
}

String formatDateTime(DateTime? dateTime) {
  if (dateTime == null) return '-';
  return '${dateTime.hour}:${dateTime.minute}:${dateTime.second}';
}
