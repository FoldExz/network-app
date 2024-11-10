import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dartssh2/dartssh2.dart';
import 'sftp_connection.dart';
import '../utils/ssh_connection.dart';
import 'dir_screen.dart';

List<Map<String, String>> hostServers = [];

class FileTransferPage extends StatefulWidget {
  const FileTransferPage({super.key});

  @override
  _FileTransferPageState createState() => _FileTransferPageState();
}

class _FileTransferPageState extends State<FileTransferPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadHostsFromPreferences();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
    return Scaffold(
      body: Column(
        children: [
          const SizedBox(height: 50),
          Container(
            color: Colors.black,
            child: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              tabs: const [
                Tab(text: 'Host 1'),
                Tab(text: 'Host 2'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                HostPage(tabController: _tabController),
                HostPage(tabController: _tabController),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class HostPage extends StatefulWidget {
  final TabController tabController;

  const HostPage({super.key, required this.tabController});

  @override
  _HostPageState createState() => _HostPageState();
}

class _HostPageState extends State<HostPage> {
  late List<Map<String, String>> servers;
  bool _showDirScreen = false;

  @override
  void initState() {
    super.initState();
    servers = hostServers;
    _loadHostsFromPreferences();
  }

  Future<void> refreshHosts() async {
    await _loadHostsFromPreferences();
    setState(() {
      servers = hostServers;
    });
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

  Future<void> _removeHost(int index) async {
    setState(() {
      hostServers.removeAt(index);
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> updatedHostList =
        hostServers.map((host) => jsonEncode(host)).toList();
    await prefs.setStringList('hostServers', updatedHostList);
  }

  @override
  Widget build(BuildContext context) {
    // Tampilkan DirScreen jika _showDirScreen true, atau daftar server jika false
    return _showDirScreen
        ? DirScreen(
            onClose: () {
              setState(() {
                _showDirScreen = false;
              });
            },
          )
        : Scaffold(
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
                      onRefresh: refreshHosts,
                      child: ListView.builder(
                        itemCount: servers.isEmpty ? 1 : servers.length,
                        itemBuilder: (context, index) {
                          if (servers.isEmpty) {
                            return Center(child: Text("Belum ada server"));
                          } else {
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
        addHostBottomSheet(context, refreshHosts);
      },
      backgroundColor: Colors.green,
      child: const Icon(Icons.add, size: 40),
    );
  }

  Widget _buildHostTile(Map<String, String> server, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(Icons.cloud, color: Colors.blue),
        title: Text(server['name'] ?? 'Unknown'),
        subtitle: Text('${server['username']}, ${server['hostname']}'),
        onLongPress: () {
          modifyHostBottomSheet(context, server, index, refreshHosts);
        },
        onTap: () async {
          String host = server['hostname'] ?? '';
          String username = server['username'] ?? '';
          String password = server['password'] ?? '';

          SSHConnection sshConnection = SSHConnection();

          try {
            await sshConnection.connect(host, username, password);
            if (sshConnection.isConnected) {
              print("Successfully connected to $host via SFTP");

              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Connected to $host via SFTP')));

              // Tampilkan DirScreen di dalam HostPage
              setState(() {
                _showDirScreen = true;
              });
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to connect to $host')));
            }
          } catch (e) {
            print("Error: $e");
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text('Error: $e')));
          }
        },
      ),
    );
  }

  Widget buildHostList(BuildContext context) {
    return FutureBuilder(
      future: _loadHostsFromPreferences(), // Memuat data awal
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Menampilkan loading spinner saat data sedang dimuat
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        // Memastikan data sudah tersedia
        if (!snapshot.hasData || hostServers.isEmpty) {
          return Center(child: Text("Belum ada host tersedia"));
        }

        return ListView.builder(
          itemCount: hostServers.length,
          itemBuilder: (context, index) {
            final host = hostServers[index];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
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
                onLongPress: () {
                  modifyHostBottomSheet(context, host, index, refreshHosts);
                },
              ),
            );
          },
        );
      },
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
            color: Color(
                0xFF15181F), // Mengubah warna latar belakang menjadi #15181F
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
                        backgroundColor: const Color(
                            0xFF343746), // Mengubah warna tombol menjadi #343746
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

void modifyHostBottomSheet(BuildContext context, Map<String, String> host,
    int index, Function refreshHosts) {
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
            color: Color(0xFF15181F),
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
                            GestureDetector(
                              onTap: () async {
                                setState(() {
                                  hostServers.removeAt(index); // Menghapus host
                                });
                                await _saveHostsToPreferences();
                                await refreshHosts(); // Memanggil refreshHosts
                                Navigator.pop(context); // Menutup bottom sheet
                              },
                              child: const Text(
                                "Hapus",
                                style:
                                    TextStyle(fontSize: 16, color: Colors.red),
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => Navigator.pop(
                                  context), // Menutup bottom sheet
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
                          hostServers[index] = updatedHost; // Update host data
                        });
                        await _saveHostsToPreferences();
                        await refreshHosts(); // Memanggil refreshHosts untuk update UI
                        Navigator.pop(context); // Menutup bottom sheet
                      },
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        backgroundColor: const Color(0xFF343746),
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
