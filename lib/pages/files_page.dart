import 'dart:convert';

import 'package:flutter/material.dart';
import 'add_host_bottom_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dartssh2/dartssh2.dart';
import 'sftp_connection.dart';

// Central list to store all available host servers
List<Map<String, String>> hostServers = [];

class FileTransferPage extends StatefulWidget {
  const FileTransferPage({super.key});

  @override
  _FileTransferPageState createState() => _FileTransferPageState();
}

class _FileTransferPageState extends State<FileTransferPage> {
  @override
  void initState() {
    super.initState();
    _loadHostsFromPreferences(); // Memuat host saat halaman dimuat
  }

  Future<void> _loadHostsFromPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? savedHosts = prefs.getStringList('hostServers');
    if (savedHosts != null) {
      setState(() {
        hostServers = savedHosts
            .map((hostJson) => Map<String, String>.from(jsonDecode(hostJson)))
            .toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        body: Column(
          children: [
            const SizedBox(height: 50),
            Container(
              color: Colors.black,
              child: const TabBar(
                indicatorColor: Colors.white,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                tabs: [
                  Tab(text: 'Host 1'),
                  Tab(text: 'Host 2'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  HostPage(), // No need to pass hostName
                  HostPage(), // Shared logic for both
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PasswordField extends StatefulWidget {
  final Function(String) onChanged;

  const PasswordField({super.key, required this.onChanged});

  @override
  _PasswordFieldState createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _isObscured = true;

  @override
  Widget build(BuildContext context) {
    return TextField(
      obscureText: _isObscured,
      onChanged: widget.onChanged,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: 'Password',
        labelStyle: const TextStyle(color: Colors.white),
        suffixIcon: IconButton(
          icon: Icon(
            _isObscured ? Icons.visibility : Icons.visibility_off,
            color: Colors.white,
          ),
          onPressed: () {
            setState(() {
              _isObscured = !_isObscured;
            });
          },
        ),
        filled: true,
        fillColor: const Color(0xFF15181F),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class HostPage extends StatefulWidget {
  const HostPage({super.key}); // No hostName needed anymore

  @override
  _HostPageState createState() => _HostPageState();
}

class _HostPageState extends State<HostPage> {
  late List<Map<String, String>> servers;

  @override
  void initState() {
    super.initState();
    servers = hostServers; // Use the global shared list of servers
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Remove AppBar and title to save space
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            const Text(
              "Pilih server",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: servers.isEmpty
                  ? const Center(
                      child: Text(
                        "Belum ada server",
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: servers.length,
                      itemBuilder: (context, index) {
                        return _buildHostTile(servers[index]);
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildAddNewHost(context),
    );
  }

  Widget _buildAddNewHost(BuildContext context) {
    return FloatingActionButton(
      onPressed: () {
        showAddNewHostBottomSheet(context);
      },
      backgroundColor: Colors.green,
      child: const Icon(Icons.add, size: 40),
    );
  }

  Widget _buildHostTile(Map<String, String> server) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(Icons.cloud, color: Colors.blue),
        title: Text(server['name'] ?? 'Unknown'),
        subtitle: Text('${server['username']}, ${server['hostname']}'),
        onTap: () async {
          // Mengambil detail dari server
          final String hostname = server['hostname'] ?? '';
          final String username = server['username'] ?? '';
          final String password =
              server['password'] ?? ''; // Pastikan password ada di map

          try {
            // Memanggil fungsi untuk menghubungkan ke server SSH
            // await connectToSftpServer(hostname, username, password);

            // Jika Anda ingin menampilkan daftar file, tambahkan logika di sini
            // Misalnya: tampilkan file setelah berhasil terhubung
          } catch (e) {
            // Tampilkan pesan kesalahan jika terjadi error
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text("Error"),
                content: Text("Gagal terhubung ke server: $e"),
              ),
            );
          }
        },
      ),
    );
  }
}
