import 'package:flutter/material.dart';
import 'package:dart_ping/dart_ping.dart'; // Import package dart_ping
import 'package:flutter/services.dart';
import '../utils/ssh_connection.dart';
import '../styles/app_color.dart';
import '../styles/app_styles.dart';

class TerminalPage extends StatelessWidget {
  TerminalPage({super.key});

  final _sshConnection = SSHConnection();
  final TextEditingController _hostController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
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
                    color: const Color(0xFF15181F),
                    borderRadius: BorderRadius.circular(1000),
                  ),
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: Row(
                    children: [
                      const Icon(Icons.search, color: Colors.white, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Search / Type a command',
                            hintStyle: TextStyle(
                              color: const Color(0xFF515257),
                              fontSize: baseFontSize * 0.9,
                            ),
                            border: InputBorder.none,
                          ),
                          onSubmitted: (command) {
                            if (command.startsWith("ssh")) {
                              _showPasswordBottomSheet(context, command);
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
                    color: Colors.white,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 20),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CommandItem(
                          command: 'ssh [user@]host[:port]',
                          example: 'ssh user@192.168.1.1',
                          baseFontSize: baseFontSize,
                        ),
                        CommandItem(
                          command: 'ping host',
                          example: 'ping google.com',
                          baseFontSize: baseFontSize,
                        ),
                        CommandItem(
                          command: 'traceroute host',
                          example: 'traceroute google.com',
                          baseFontSize: baseFontSize,
                        ),
                        CommandItem(
                          command: 'ifconfig',
                          example: 'ifconfig eth0',
                          baseFontSize: baseFontSize,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<bool> _checkHostAvailability(String host) async {
    final ping = Ping(host, count: 3, timeout: 1); // Timeout dalam detik
    bool isReachable = false;

    await for (final pingData in ping.stream) {
      if (pingData.response != null) {
        isReachable = true;
        break;
      }
    }

    return isReachable;
  }

  void _showPasswordBottomSheet(BuildContext context, String command) {
    bool _isLoading = false;
    bool _isError = false;

    // Parsing command to extract username and host address
    String host = '';
    String username = '';

    // Format yang diharapkan adalah 'ssh username@host'
    if (command.startsWith("ssh")) {
      final regex = RegExp(r"ssh\s+([^\@]+)\@([^\s]+)");
      final match = regex.firstMatch(command);

      if (match != null) {
        username = match.group(1) ?? '';
        host = match.group(2) ?? '';
      }
    }

    // Mengisi controller dengan nilai yang terparsing
    _hostController.text = host;
    _usernameController.text = username;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFF15181F),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'New host',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                          },
                          child: Text(
                            'Cancel',
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.normal,
                              color: Color(0xFF29B06C),
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
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Password',
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
                    const SizedBox(height: 20),
                    if (_isLoading)
                      const LinearProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Color(0xFF29B06C)),
                      ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          setState(() {
                            _isLoading = true;
                            _isError = false;
                          });

                          String host = _hostController.text;
                          String username = _usernameController.text;
                          String password = _passwordController.text;

                          // Cek apakah host dapat dijangkau
                          bool isReachable = await _checkHostAvailability(host);
                          if (!isReachable) {
                            setState(() {
                              _isLoading = false;
                              _isError = true;
                            });
                            return; // Jangan lanjutkan jika host tidak bisa dijangkau
                          }

                          try {
                            // Mencoba untuk melakukan koneksi SSH
                            await _sshConnection.connect(
                                host, username, password);

                            // Jika berhasil, tutup bottom sheet dan buka TerminalScreen
                            Navigator.pop(context);

                            // **Buka TerminalScreen hanya jika koneksi berhasil**
                            _showTerminalScreen(context);
                          } catch (e) {
                            // Jika gagal (misalnya Connection Refused), tampilkan pesan kesalahan
                            setState(() {
                              _isLoading = false;
                              _isError = true;
                            });

                            // Menampilkan error jika koneksi gagal
                            print("Koneksi SSH gagal: $e");
                          }
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
      },
    );
  }

  void _showTerminalScreen(BuildContext context) async {
    // Pastikan SSHConnection telah berhasil terkoneksi sebelumnya
    bool isConnected =
        _sshConnection.isConnected; // Menggunakan getter isConnected

    if (isConnected) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TerminalScreen(sshConnection: _sshConnection),
        ),
      );
    } else {
      // Jika tidak terkoneksi, tampilkan pesan kesalahan atau tidak melakukan apa-apa
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("Koneksi SSH gagal. Tidak dapat membuka terminal.")),
      );
    }
  }

// Fungsi untuk mengecek status koneksi SSH
  Future<bool> _checkSSHConnection() async {
    try {
      // Cek koneksi SSH
      bool isReachable = await _sshConnection.isConnected;
      return isReachable;
    } catch (e) {
      // Jika gagal, berarti koneksi tidak berhasil
      print("Koneksi SSH gagal: $e");
      return false;
    }
  }
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
  final ScrollController _scrollController =
      ScrollController(); // Tambahkan ScrollController
  String _output = "";

  // Fungsi untuk mengirimkan command ke SSH
  Future<void> _sendCommand(String command) async {
    final result = await widget.sshConnection.executeCommand(command);
    setState(() {
      _output += '\n\$ $command\n$result';
    });

    // Scroll otomatis ke bawah
    _scrollToBottom();
    _commandController.clear();
  }

  // Fungsi untuk mengatur scroll ke bawah
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

  // Fungsi untuk menyembunyikan/memunculkan keyboard
  void _toggleKeyboard() {
    if (_focusNode.hasFocus) {
      _focusNode.unfocus(); // Menyembunyikan keyboard
    } else {
      FocusScope.of(context).requestFocus(_focusNode); // Memunculkan keyboard
    }
  }

  @override
  void dispose() {
    widget.sshConnection.close();
    _focusNode.dispose();
    _scrollController.dispose(); // Dispose ScrollController
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("SSH Terminal"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                controller:
                    _scrollController, // Pasang ScrollController di sini
                child: Text(
                  _output,
                  style: const TextStyle(
                    color: Colors.green,
                    fontFamily:
                        'Consolas', // Menggunakan font Consolas untuk output
                  ),
                ),
              ),
            ),

            // Input perintah di terminal
            Padding(
              padding: const EdgeInsets.only(bottom: 20.0),
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
                          style: const TextStyle(
                              color: Colors.white, fontFamily: 'Consolas'),
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
                  // Row untuk shortcut keyboard tanpa kotak
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildShortcutText('Ctrl', () {
                        _commandController.text += "Ctrl ";
                      }),
                      _buildShortcutText('Tab', () {
                        _commandController.text += "Tab ";
                      }),
                      _buildShortcutText('Esc', () {
                        _commandController.text += "Esc ";
                      }),
                      IconButton(
                        icon: const Icon(Icons.keyboard, color: Colors.white),
                        onPressed: _toggleKeyboard,
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

  Widget _buildShortcutText(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 16,
          fontFamily: 'Arial Rounded MT Bold',
          color: Colors.white,
        ),
      ),
    );
  }
}

// Widget untuk input password dengan show/hide
class PasswordField extends StatefulWidget {
  const PasswordField({super.key});

  @override
  _PasswordFieldState createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _isObscured = true;

  @override
  Widget build(BuildContext context) {
    return TextField(
      obscureText: _isObscured,
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
