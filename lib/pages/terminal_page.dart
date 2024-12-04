import 'package:flutter/material.dart';
import 'package:dart_ping/dart_ping.dart';
import 'package:flutter/services.dart';
import '../utils/ssh_connection.dart';
import '../styles/app_color.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../styles/app_styles.dart';

class TerminalPage extends StatefulWidget {
  const TerminalPage({super.key});

  @override
  _TerminalPageState createState() => _TerminalPageState();
}

class _TerminalPageState extends State<TerminalPage> {
  final _sshConnection = SSHConnection();
  final TextEditingController _hostController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  List<Map<String, String>> savedHosts = [];

  @override
  void initState() {
    super.initState();
    _loadHosts();
  }

  // Load the saved hosts from SharedPreferences
  Future<void> _loadHosts() async {
    final prefs = await SharedPreferences.getInstance();
    List<String>? hostList = prefs.getStringList('savedHosts');

    if (hostList != null) {
      setState(() {
        savedHosts = hostList.map((e) {
          final parts = e.split('|');
          return {
            'host': parts[0],
            'username': parts[1],
            'password': parts.length > 2 ? parts[2] : "",
          };
        }).toList();
      });
      print('Loaded hosts: $savedHosts'); // Debugging
    }
  }

  // Save a new host to SharedPreferences, ensuring no duplicates
  Future<void> _saveHost(String host, String username, String password,
      {bool isEdit = false, int? index}) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> hostList = prefs.getStringList('savedHosts') ?? [];
    if (isEdit && index != null) {
      hostList[index] = '$host|$username|$password';
      savedHosts[index] = {
        'host': host,
        'username': username,
        'password': password, // Pastikan password diperbarui di savedHosts
      };
    } else {
      bool exists = hostList.any((item) {
        final parts = item.split('|');
        return parts[0] == host && parts[1] == username;
      });

      if (!exists) {
        hostList.add('$host|$username|$password');
        savedHosts.add({
          'host': host,
          'username': username,
          'password': password,
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('This configuration already exists!')),
        );
        return;
      }
    }

    await prefs.setStringList('savedHosts', hostList);
    _loadHosts(); // Refresh UI
  }

  Future<void> _deleteHost(int index) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> hostList = prefs.getStringList('savedHosts') ?? [];

    // Hapus host berdasarkan index
    hostList.removeAt(index);

    // Simpan kembali daftar yang telah diperbarui
    await prefs.setStringList('savedHosts', hostList);

    // Muat ulang daftar host
    _loadHosts();
  }

  @override
  Widget build(BuildContext context) {
    // Daftar perintah dengan kategori yang dikelompokkan
    final List<Map<String, dynamic>> commands = [
      {
        'category': 'SSH Commands',
        'commands': [
          {
            'command': 'ssh [user@]host[:port]',
            'example': 'ssh user@192.168.1.1',
          },
          {
            'command': 'scp [file] [user@]host:[path]',
            'example': 'scp myfile.txt user@192.168.1.1:/path/to/directory',
          },
          {
            'command': 'ssh-keygen -t rsa',
            'example': 'Generate SSH key pair',
          },
        ],
      },
      {
        'category': 'Windows Commands',
        'commands': [
          {
            'command': 'ipconfig',
            'example': 'Display IP configuration',
          },
          {
            'command': 'ping',
            'example': 'Ping a host to check network connectivity',
          },
          {
            'command': 'dir',
            'example': 'List directory contents',
          },
          {
            'command': 'netstat',
            'example': 'Display network connections and listening ports',
          },
        ],
      },
      {
        'category': 'Linux Commands',
        'commands': [
          {
            'command': 'ls',
            'example': 'List directory contents',
          },
          {
            'command': 'top',
            'example': 'Display running processes',
          },
          {
            'command': 'chmod',
            'example': 'Change file permissions',
          },
          {
            'command': 'df -h',
            'example': 'Display disk space usage',
          },
        ],
      },
      {
        'category': 'Cisco Commands',
        'commands': [
          {
            'command': 'show ip interface brief',
            'example': 'Show IP interface status',
          },
          {
            'command': 'show running-config',
            'example': 'Display the current running configuration',
          },
          {
            'command': 'ping',
            'example': 'Ping a remote device to check connectivity',
          },
          {
            'command': 'show version',
            'example': 'Display system hardware and software version',
          },
        ],
      },
    ];

    // Membuat list untuk semua commands yang digabungkan dengan kategori sebagai judul
    final List<Map<String, String>> allCommands = [];
    for (var category in commands) {
      // Menambahkan kategori sebagai item pertama
      allCommands.add({
        'command': category['category']!,
        'example': '', // Kategori tidak memiliki contoh
      });
      // Menambahkan semua commands dalam kategori
      for (var cmd in category['commands']) {
        allCommands.add({
          'command': cmd['command']!,
          'example': cmd['example']!,
        });
      }
    }

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          double width = constraints.maxWidth;
          double baseFontSize = width > 1200
              ? 24
              : width > 600
                  ? 20
                  : 16;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 50),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.darkGray,
                    borderRadius: BorderRadius.circular(1000),
                  ),
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: Row(
                    children: [
                      const Icon(Icons.search,
                          color: AppColors.white, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          style: const TextStyle(color: AppColors.white),
                          decoration: InputDecoration(
                            hintText: 'Type a command, ssh...',
                            hintStyle: TextStyle(
                              color: AppColors.mediumGray,
                              fontSize: baseFontSize * 0.9,
                            ),
                            border: InputBorder.none,
                          ),
                          onSubmitted: (command) {
                            if (command.startsWith("ssh")) {
                              _showPasswordBottomSheet(context, command);
                            } else {
                              // Tampilkan snackbar jika perintah tidak dikenal
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Command tidak ditemukan'),
                                  backgroundColor:
                                      Color.fromARGB(255, 255, 255, 255),
                                ),
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Suggestions',
                  style: TextStyle(
                    fontSize: baseFontSize,
                    color: AppColors.white,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 20),
                // Gunakan ListView.builder untuk daftar command items
                Expanded(
                  child: ListView.builder(
                    itemCount: allCommands.length,
                    itemBuilder: (context, index) {
                      final command = allCommands[index];
                      final commandText = command['command']!;
                      final example = command['example']!;

                      // Jika command adalah kategori, tampilkan sebagai teks kategori
                      if (example.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(
                            commandText, // Kategori
                            style: TextStyle(
                              fontSize: baseFontSize - 2,
                              color: AppColors.white,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      } else {
                        // Jika command adalah perintah, tampilkan sebagai CommandItem
                        return CommandItem(
                          command: commandText,
                          example: example,
                          baseFontSize: baseFontSize,
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Saved Hosts',
                  style: TextStyle(
                    fontSize: baseFontSize,
                    color: AppColors.white,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 10),
                // Display saved hosts in ListView
                Expanded(
                  child: savedHosts.isEmpty
                      ? Center(
                          child: Text(
                            'Belum ada konfigurasi host',
                            style: TextStyle(
                              color: const Color.fromARGB(255, 255, 255, 255),
                              fontFamily: 'Poppins',
                            ),
                          ),
                        )
                      : ListView.builder(
                          itemCount: savedHosts.length,
                          itemBuilder: (context, index) {
                            final host = savedHosts[index];
                            return ListTile(
                              title: Text(
                                host['host'] ?? '',
                                style: TextStyle(
                                    color: AppColors.white,
                                    fontSize: baseFontSize),
                              ),
                              subtitle: Text(
                                host['username'] ??
                                    '', // Hanya tampilkan username
                                style: TextStyle(
                                    color: AppColors.mediumGray,
                                    fontSize: baseFontSize * 0.9),
                              ),
                              onTap: () async {
                                String selectedHost = host['host'] ?? '';
                                String selectedUsername =
                                    host['username'] ?? '';
                                String? savedPassword = host['password'];

                                print(
                                    'Host: $selectedHost, Username: $selectedUsername, Password: $savedPassword');

                                if (selectedHost.isNotEmpty &&
                                    selectedUsername.isNotEmpty) {
                                  await _sshConnection.connect(
                                    selectedHost,
                                    selectedUsername,
                                    savedPassword!,
                                  );
                                  _showTerminalScreen(context);
                                }
                              },
                              onLongPress: () {
                                // Panggil modal untuk mengedit host
                                _showEditHostBottomSheet(context, index, host);
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: _buildAddNewHost(context), // FloatingActionButton
    );
  }

  Widget _buildAddNewHost(BuildContext context) {
    return FloatingActionButton(
      onPressed: () {
        _showPasswordBottomSheet(context, ""); // Trigger modal to add new host
      },
      backgroundColor: Colors.green,
      child: const Icon(Icons.add, size: 40),
    );
  }

  Future<void> _showPasswordBottomSheet(
      BuildContext context, String command) async {
    // Load initial values
    String host = "";
    String username = "";
    String password = "";

    if (command.startsWith("ssh")) {
      final regex = RegExp(r"ssh\s+([^\@]+)\@([^\s]+)");
      final match = regex.firstMatch(command);

      if (match != null) {
        username = match.group(1) ?? '';
        host = match.group(2) ?? '';
      }
    }

    // Set initial values for controllers
    _hostController.text = host;
    _usernameController.text = username;
    _passwordController.text = password;

    // Show the modal bottom sheet
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
              color: AppColors.darkGray,
              borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'New Host',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.bold,
                        color: AppColors.white,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.normal,
                          color: AppColors.green,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _hostController,
                  decoration: const InputDecoration(
                    labelText: 'Host Address',
                    labelStyle: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF8C91A5),
                    ),
                    filled: true,
                    fillColor: Color(0xFF15181F),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF242834)),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF242834)),
                    ),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    labelStyle: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF8C91A5),
                    ),
                    filled: true,
                    fillColor: Color(0xFF15181F),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF242834)),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF242834)),
                    ),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 10),

                // Gunakan PasswordField untuk input password

                PasswordField(
                  controller:
                      _passwordController, // Langsung menggunakan controller
                ),

                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      // Grab the values from controllers
                      String host = _hostController.text;
                      String username = _usernameController.text;
                      String password = _passwordController.text;

                      // Save the host configuration
                      await _saveHost(host, username, password);

                      Navigator.pop(context); // Close the modal
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF343746),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      "Continue",
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFFFFFFF),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<bool> _checkHostAvailability(String host) async {
    final ping = Ping(host, count: 3, timeout: 1);
    bool isReachable = false;

    await for (final pingData in ping.stream) {
      if (pingData.response != null) {
        isReachable = true;
        break;
      }
    }

    return isReachable;
  }

  void _showEditHostBottomSheet(
      BuildContext context, int index, Map<String, String> host) {
    // Deklarasi TextEditingController untuk setiap field
    final TextEditingController hostController =
        TextEditingController(text: host['host']);
    final TextEditingController usernameController =
        TextEditingController(text: host['username']);
    final TextEditingController passwordController =
        TextEditingController(text: host['password']); // Tambahkan di sini

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
              color: AppColors.darkGray,
              borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    const Text(
                      'Edit Host',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.bold,
                        color: AppColors.white,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () async {
                        // Fungsi hapus
                        await _deleteHost(index);
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'Delete',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.normal,
                          color: Colors.red,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.normal,
                          color: AppColors.green,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: hostController,
                  decoration: const InputDecoration(
                    labelText: 'Host Address',
                    labelStyle: TextStyle(color: Color(0xFF8C91A5)),
                    filled: true,
                    fillColor: Color(0xFF15181F),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF242834)),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF242834)),
                    ),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    labelStyle: TextStyle(color: Color(0xFF8C91A5)),
                    filled: true,
                    fillColor: Color(0xFF15181F),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF242834)),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF242834)),
                    ),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 10),
                // Gunakan PasswordField untuk input password
                PasswordField(
                  controller:
                      passwordController, // Pastikan controller dihubungkan
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      String updatedHost = hostController.text;
                      String updatedUsername = usernameController.text;
                      String updatedPassword = passwordController.text;

                      await _saveHost(
                        updatedHost,
                        updatedUsername,
                        updatedPassword,
                        isEdit: true,
                        index: index,
                      );

                      Navigator.pop(context); // Tutup modal
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF343746),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      "Save",
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFFFFFFF),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showTerminalScreen(BuildContext context) async {
    bool isConnected = _sshConnection.isConnected;

    if (isConnected) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TerminalScreen(sshConnection: _sshConnection),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Koneksi SSH gagal. Tidak dapat membuka terminal."),
        ),
      );
    }
  }
}

Future<void> _saveConfiguration(
    String host, String username, String password) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('host', host);
  await prefs.setString('username', username);
  await prefs.setString('password', password);
}

Future<Map<String, String?>> _loadConfiguration() async {
  final prefs = await SharedPreferences.getInstance();
  String? host = prefs.getString('host');
  String? username = prefs.getString('username');
  String? password = prefs.getString('password');

  return {'host': host, 'username': username, 'password': password};
}

class TerminalScreen extends StatefulWidget {
  final SSHConnection sshConnection;

  const TerminalScreen({super.key, required this.sshConnection});

  @override
  _TerminalScreenState createState() => _TerminalScreenState();
}

class _TerminalScreenState extends State<TerminalScreen> {
  final TextEditingController _commandController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  String _output = "";
  double _fontSize = 14;

  final List<String> _commandHistory = [];
  int _historyIndex = -1;

  Future<void> _sendCommand(String command) async {
    if (command.isEmpty) return;

    final result = await widget.sshConnection.executeCommand(command);
    setState(() {
      _output += '\n\$ $command\n$result';
      _commandHistory.add(command);
      _historyIndex = _commandHistory.length;
    });

    _scrollToBottom();
    _commandController.clear();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _toggleKeyboard() {
    if (_focusNode.hasFocus) {
      _focusNode.unfocus();
    } else {
      FocusScope.of(context).requestFocus(_focusNode);
    }
  }

  void _zoomIn() {
    setState(() {
      _fontSize += 2;
    });
  }

  void _zoomOut() {
    setState(() {
      _fontSize = (_fontSize - 2).clamp(10, 30);
    });
  }

  void _handleArrowUp() {
    setState(() {
      if (_historyIndex > 0) {
        _historyIndex--;
        _commandController.text = _commandHistory[_historyIndex];
        _commandController.selection = TextSelection.fromPosition(
            TextPosition(offset: _commandController.text.length));
      }
    });
  }

  void _handleArrowDown() {
    setState(() {
      if (_historyIndex < _commandHistory.length - 1) {
        _historyIndex++;
        _commandController.text = _commandHistory[_historyIndex];
      } else {
        _historyIndex = _commandHistory.length;
        _commandController.clear();
      }
      _commandController.selection = TextSelection.fromPosition(
          TextPosition(offset: _commandController.text.length));
    });
  }

  @override
  void dispose() {
    widget.sshConnection.close();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "SSH Terminal",
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                child: SelectableText(
                  _output,
                  style: TextStyle(
                    fontSize: _fontSize,
                    color: Colors.green,
                    fontFamily: 'Consolas',
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 1),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Text(
                        '\$ ',
                        style: TextStyle(
                          color: Colors.green,
                          fontFamily: 'Consolas',
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _commandController,
                          focusNode: _focusNode,
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: 'Consolas',
                            fontSize: _fontSize,
                          ),
                          decoration: const InputDecoration(
                            hintText: 'Enter command',
                            border: InputBorder.none,
                            hintStyle: TextStyle(color: Colors.grey),
                          ),
                          onSubmitted: (command) {
                            _sendCommand(command);
                          },
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        icon:
                            const Icon(Icons.arrow_upward, color: Colors.white),
                        onPressed: _handleArrowUp,
                      ),
                      IconButton(
                        icon: const Icon(Icons.arrow_downward,
                            color: Colors.white),
                        onPressed: _handleArrowDown,
                      ),
                      IconButton(
                        icon: const Icon(Icons.keyboard, color: Colors.white),
                        onPressed: _toggleKeyboard,
                      ),
                      IconButton(
                        icon: const Icon(Icons.zoom_out, color: Colors.white),
                        onPressed: _zoomOut,
                      ),
                      IconButton(
                        icon: const Icon(Icons.zoom_in, color: Colors.white),
                        onPressed: _zoomIn,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget _buildShortcutText(String label, VoidCallback onTap) {
  //   return GestureDetector(
  //     onTap: onTap,
  //     child: Text(
  //       label,
  //       style: TextStyle(
  //         fontSize: 16,
  //         fontFamily: 'Arial Rounded MT Bold',
  //         color: _isCtrlActive && label == 'Ctrl' ? Colors.blue : Colors.white,
  //       ),
  //     ),
  //   );
  // }
}

// Widget untuk input password dengan show/hide
class PasswordField extends StatefulWidget {
  final TextEditingController controller;

  const PasswordField({
    super.key,
    required this.controller,
  });

  @override
  _PasswordFieldState createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _isObscured = true;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller, // Gunakan controller dari parent
      obscureText: _isObscured, // Tampilkan/hide password
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
              _isObscured = !_isObscured; // Toggle password visibility
            });
          },
        ),
        filled: true,
        fillColor: const Color(0xFF15181F),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF242834)),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF242834)),
        ),
      ),
    );
  }
}

class CommandItem extends StatelessWidget {
  final String command;
  final String example;
  final double baseFontSize;

  const CommandItem({
    super.key,
    required this.command,
    required this.example,
    required this.baseFontSize,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            command,
            style: TextStyle(
              fontSize: baseFontSize * 0.9,
              color: const Color(0xFF479F79),
              fontFamily: 'CONSOLA',
            ),
          ),
          Text(
            example,
            style: TextStyle(
              fontSize: baseFontSize * 0.8,
              color: Colors.white,
              fontStyle: FontStyle.italic,
              fontFamily: 'consolai',
            ),
          ),
        ],
      ),
    );
  }
}
