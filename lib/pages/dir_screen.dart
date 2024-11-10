import 'package:flutter/material.dart';
import '../utils/ssh_connection.dart';

class DirScreen extends StatelessWidget {
  final VoidCallback onClose;

  DirScreen({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      appBar: AppBar(
        backgroundColor: Colors.black87,
        title: Text('Root'),
        actions: [
          IconButton(
            icon: Icon(Icons.close),
            onPressed: onClose, // Use callback to close DirScreen
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: 3,
        itemBuilder: (context, index) {
          return ListTile(
            leading: Icon(Icons.folder, color: Colors.grey[600]),
            title: Text('${index + 1}',
                style: TextStyle(color: Colors.white, fontSize: 16)),
            subtitle: Text('folder ${index + 1}',
                style: TextStyle(color: Colors.grey, fontSize: 14)),
            onTap: () {
              // Handle folder tap
            },
          );
        },
      ),
    );
  }
}
