import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dartssh2/dartssh2.dart';
import 'sftp_connection.dart';

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
    _loadHostsFromPreferences();
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
  final String initialValue; // Menambahkan parameter initialValue

  const PasswordField({
    super.key,
    required this.onChanged,
    this.initialValue =
        '', // Default menjadi string kosong jika tidak diberikan
  });

  @override
  _PasswordFieldState createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _isObscured = true;
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
        text:
            widget.initialValue); // Inisialisasi controller dengan initialValue
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller, // Menggunakan controller di sini
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

  @override
  void initState() {
    super.initState();
    servers = hostServers; // Gunakan data server yang tersimpan
    _loadHostsFromPreferences(); // Memuat data awal dari SharedPreferences
  }

  // Fungsi untuk memuat ulang daftar host (sudah terdefinisi di _HostPageState)
  Future<void> _refreshHosts() async {
    await _loadHostsFromPreferences();
    setState(() {
      servers = hostServers; // Perbarui tampilan dengan data terbaru
    });
  }

  // Fungsi untuk memuat data dari SharedPreferences
  Future<void> _loadHostsFromPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? savedHosts = prefs.getStringList('hostServers');

    if (savedHosts != null) {
      setState(() {
        // Memuat data dari SharedPreferences ke dalam hostServers
        hostServers = savedHosts
            .map((hostJson) => Map<String, String>.from(jsonDecode(hostJson)))
            .toList();
      });
    }
  }

  Future<void> _removeHost(int index) async {
    // Hapus host dari list
    setState(() {
      hostServers.removeAt(index);
    });

    // Simpan kembali ke SharedPreferences setelah penghapusan
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> updatedHostList =
        hostServers.map((host) => jsonEncode(host)).toList();
    await prefs.setStringList('hostServers', updatedHostList);
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
              child: RefreshIndicator(
                onRefresh: _refreshHosts, // Memanggil fungsi refresh
                child: ListView.builder(
                  itemCount: servers.isEmpty
                      ? 1
                      : servers
                          .length, // Jika kosong, tampilkan 1 item (untuk pesan)
                  itemBuilder: (context, index) {
                    if (servers.isEmpty) {
                      // Jika server kosong, tampilkan pesan dan icon
                      return Align(
                        alignment:
                            Alignment.center, // Menjaga posisi tetap di tengah
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment
                              .center, // Agar semua widget terpusat di tengah
                          children: [
                            Icon(Icons.cloud_off, size: 50, color: Colors.grey),
                            const SizedBox(height: 10),
                            const Text(
                              "Belum ada server",
                              style:
                                  TextStyle(fontSize: 16, color: Colors.grey),
                            ),
                          ],
                        ),
                      );
                    } else {
                      // Jika ada server, tampilkan item seperti biasa
                      return _buildHostTile(servers[index], index);
                    }
                  },
                ),
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
        addHostBottomSheet(
            context, _refreshHosts); // Pass _refreshHosts as a callback
      },
      backgroundColor: Colors.green,
      child: const Icon(Icons.add, size: 40),
    );
  }

  // Modified _buildHostTile to call modifyHostBottomSheet for details or edits
  Widget _buildHostTile(Map<String, String> server, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(Icons.cloud, color: Colors.blue),
        title: Text(server['name'] ?? 'Unknown'),
        subtitle: Text('${server['username']}, ${server['hostname']}'),
        onLongPress: () {
          modifyHostBottomSheet(
              context, server, index); // Edit or modify existing host
        },
      ),
    );
  }
}

// Fungsi untuk menyimpan host ke SharedPreferences
Future<void> _saveHostsToPreferences() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  List<String> hostsJsonList =
      hostServers.map((host) => jsonEncode(host)).toList();
  await prefs.setStringList('hostServers', hostsJsonList);
}

// Fungsi untuk memuat host dari SharedPreferences
Future<void> _loadHostsFromPreferences() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  List<String>? savedHosts = prefs.getStringList('hostServers');
  if (savedHosts != null) {
    hostServers = savedHosts
        .map((hostJson) {
          try {
            final decoded = jsonDecode(hostJson);
            return decoded is Map<String, String> ? decoded : null;
          } catch (e) {
            print("Error decoding host: $e");
            return null;
          }
        })
        .whereType<Map<String, String>>()
        .toList();
  }
}

// Fungsi untuk menampilkan bottom sheet untuk menambahkan host baru
void addHostBottomSheet(BuildContext context, Function refreshHosts) {
  String name = '';
  String hostname = '';
  String port = '';
  String username = '';
  String password = '';

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (BuildContext context) {
      return Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
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
                    const Text(
                      "Add Host",
                      style: TextStyle(fontSize: 20, color: Colors.white),
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(
                        label: 'Name',
                        onChanged: (value) => name = value,
                        initialValue: name),
                    const SizedBox(height: 12),
                    _buildTextField(
                        label: 'Hostname / IP Address',
                        onChanged: (value) => hostname = value,
                        initialValue: hostname),
                    const SizedBox(height: 12),
                    _buildTextField(
                        label: 'Port',
                        onChanged: (value) => port = value,
                        initialValue: port),
                    const SizedBox(height: 12),
                    _buildTextField(
                        label: 'Username',
                        onChanged: (value) => username = value,
                        initialValue: username),
                    const SizedBox(height: 12),
                    PasswordField(
                        onChanged: (value) => password = value,
                        initialValue: password),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () async {
                        final newHost = {
                          "name": name,
                          "hostname": hostname,
                          "port": port,
                          "username": username,
                          "password": password,
                        };

                        // Menambahkan host baru ke dalam list
                        setState(() {
                          hostServers.add(newHost);
                        });

                        // Menyimpan data ke SharedPreferences
                        await _saveHostsToPreferences();

                        // Memanggil fungsi untuk refresh data
                        await refreshHosts();

                        // Menutup bottom sheet
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        backgroundColor: Colors.green,
                      ),
                      child: const Text("Tambah",
                          style: TextStyle(fontSize: 18, color: Colors.white)),
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

void modifyHostBottomSheet(
    BuildContext context, Map<String, String> host, int index) {
  // Cek apakah hostServers memiliki index yang valid
  if (index < 0 || index >= hostServers.length) {
    // Keluarkan pesan error atau return jika index tidak valid
    print('Index is out of range for hostServers');
    return;
  }

  String name = host['name'] ?? '';
  String hostname = host['hostname'] ?? '';
  String port = host['port'] ?? '';
  String username = host['username'] ?? '';
  String password = host['password'] ?? '';

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (BuildContext context) {
      return Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
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
                          "Edit Host",
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                        Row(
                          children: [
                            // Tombol Hapus di sebelah kiri tombol Batal
                            GestureDetector(
                              onTap: () async {
                                setState(() {
                                  hostServers.removeAt(index);
                                });
                                await _saveHostsToPreferences();
                                Navigator.pop(context);

                                // Panggil _refreshHosts untuk memastikan UI terupdate
                                // await _refreshHosts();
                              },
                              child: const Text(
                                "Hapus",
                                style:
                                    TextStyle(fontSize: 16, color: Colors.red),
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: const Text(
                                "Batal",
                                style: TextStyle(
                                    fontSize: 16, color: Colors.green),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(
                        label: 'Name',
                        onChanged: (value) => name = value,
                        initialValue: name),
                    const SizedBox(height: 12),
                    _buildTextField(
                        label: 'Hostname / IP Address',
                        onChanged: (value) => hostname = value,
                        initialValue: hostname),
                    const SizedBox(height: 12),
                    _buildTextField(
                        label: 'Port',
                        onChanged: (value) => port = value,
                        initialValue: port),
                    const SizedBox(height: 12),
                    _buildTextField(
                        label: 'Username',
                        onChanged: (value) => username = value,
                        initialValue: username),
                    const SizedBox(height: 12),
                    PasswordField(
                        onChanged: (value) => password = value,
                        initialValue: password),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () async {
                        final updatedHost = {
                          "name": name,
                          "hostname": hostname,
                          "port": port,
                          "username": username,
                          "password": password,
                        };
                        setState(() {
                          hostServers[index] = updatedHost;
                        });
                        await _saveHostsToPreferences();
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        backgroundColor: Colors.green,
                      ),
                      child: const Text("Simpan",
                          style: TextStyle(fontSize: 18, color: Colors.white)),
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

// Fungsi untuk menampilkan informasi host dalam list
Widget buildHostList(BuildContext context) {
  return FutureBuilder(
    future: _loadHostsFromPreferences(),
    builder: (context, snapshot) {
      return ListView.builder(
        itemCount: hostServers.length,
        itemBuilder: (context, index) {
          final host = hostServers[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: Icon(Icons.cloud, color: Colors.blue),
              title: Text(host['name'] ?? 'Unknown'),
              subtitle: Text('${host['username']}, ${host['hostname']}'),
              onTap: () => showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text("Detail Host"),
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text("Name: ${host['name']}"),
                        Text("Hostname: ${host['hostname']}"),
                        Text("Port: ${host['port']}"),
                        Text("Username: ${host['username']}"),
                        Text("Password: ${host['password']}"),
                      ],
                    ),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("Tutup")),
                    ],
                  );
                },
              ),
              onLongPress: () => modifyHostBottomSheet(context, host, index),
            ),
          );
        },
      );
    },
  );
}

// Fungsi untuk membuat text field dengan nilai awal
Widget _buildTextField({
  required String label,
  required Function(String) onChanged,
  String initialValue = '',
}) {
  return TextField(
    controller: TextEditingController(text: initialValue),
    onChanged: onChanged,
    style: const TextStyle(color: Colors.white),
    decoration: InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white),
      filled: true,
      fillColor: const Color(0xFF15181F),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    ),
  );
}
