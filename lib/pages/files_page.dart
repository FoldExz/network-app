import 'package:flutter/material.dart';
import '../services/database_helper.dart';

// Central list to store all available host servers
List<Map<String, String>> hostServers = []; // Mengubah tipe menjadi Map

class FileTransferPage extends StatefulWidget {
  const FileTransferPage({super.key});

  @override
  _FileTransferPageState createState() => _FileTransferPageState();
}

class _FileTransferPageState extends State<FileTransferPage> {
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
            const Expanded(
              child: TabBarView(
                children: [
                  HostPage(),
                  HostPage(),
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
  const HostPage({super.key});

  @override
  _HostPageState createState() => _HostPageState();
}

class _HostPageState extends State<HostPage> {
  late List<Map<String, String>> servers;
  final DatabaseHelper dbHelper = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    _loadServers();
  }

  // Function to load servers from the database
  Future<void> _loadServers() async {
    final serverList = await dbHelper.getHostServers();
    setState(() {
      servers = serverList.map((server) {
        return {
          'name': server['name'] as String,
          'hostname': server['hostname'] as String,
          'port': server['port'] as String,
          'username': server['username'] as String,
          'password': server['password'] as String,
          'key': server['key'] as String,
        };
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
        _showAddNewHostBottomSheet(context);
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
        leading: const Icon(Icons.cloud, color: Colors.blue),
        title: Text(server['name'] ?? 'Unknown'), // Menampilkan nama
        subtitle: Text('SSH: ${server['username']}@${server['hostname']}'),
        onTap: () {
          // Add your action here
        },
      ),
    );
  }

  void _showAddNewHostBottomSheet(BuildContext context) {
    String name = '';
    String hostname = '';
    String port = '';
    String username = '';
    String password = '';
    String key = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF1E222A),
              borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
            ),
            child: StatefulBuilder(
              builder: (context, setState) {
                return SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Host Baru",
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 20,
                              color: Colors.white,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: const Text(
                              "Batal",
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 16,
                                color: Colors.green,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Form fields
                      TextField(
                        onChanged: (value) => name = value,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Name',
                          labelStyle: const TextStyle(color: Colors.white),
                          filled: true,
                          fillColor: const Color(0xFF15181F),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        onChanged: (value) => hostname = value,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Hostname / IP Address',
                          labelStyle: const TextStyle(color: Colors.white),
                          filled: true,
                          fillColor: const Color(0xFF15181F),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        onChanged: (value) => port = value,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Port',
                          labelStyle: const TextStyle(color: Colors.white),
                          filled: true,
                          fillColor: const Color(0xFF15181F),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        onChanged: (value) => username = value,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Username',
                          labelStyle: const TextStyle(color: Colors.white),
                          filled: true,
                          fillColor: const Color(0xFF15181F),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      PasswordField(
                        onChanged: (value) => password = value,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        onChanged: (value) => key = value,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Key',
                          labelStyle: const TextStyle(color: Colors.white),
                          filled: true,
                          fillColor: const Color(0xFF15181F),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () async {
                          // Menyimpan server baru ke database
                          await dbHelper.insertHostServer({
                            'name': name,
                            'hostname': hostname,
                            'port': port,
                            'username': username,
                            'password': password,
                            'key': key,
                          });

                          // Memuat ulang server setelah penambahan
                          await _loadServers();

                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                          backgroundColor: Colors.green,
                        ),
                        child: const Text(
                          "Lanjut",
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 18,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
