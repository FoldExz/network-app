import 'package:flutter/material.dart';

class TerminalPage extends StatelessWidget {
  const TerminalPage({super.key});

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
                // Search Bar
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
                            if (command.startsWith("ssh") ||
                                command.startsWith("telnet")) {
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
                          command: 'telnet host [port]',
                          example: 'telnet 192.168.1.1',
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

  // Fungsi untuk menampilkan Modal Bottom Sheet
  void _showPasswordBottomSheet(BuildContext context, String command) {
    String address = _extractAddress(command);
    String commandType = command.startsWith("ssh")
        ? "SSH"
        : "Telnet"; // Menentukan jenis perintah

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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      commandType, // Menampilkan jenis perintah (SSH/Telnet)
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 20,
                        color: Colors.white,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Text(
                        "Cancel",
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
                // Ganti teks sesuai input user
                Text(
                  "Enter the password for $address",
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                // TextField Password
                PasswordField(),
                const SizedBox(height: 20),
                // Button Continue
                ElevatedButton(
                  onPressed: () {
                    // Aksi ketika tombol ditekan
                    Navigator.pop(context);
                    _showTerminalScreen(context);
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: Colors.green,
                  ),
                  child: const Text(
                    "Continue",
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 18,
                      color: Colors.white,
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

  // Fungsi untuk mengekstrak alamat dari perintah
  String _extractAddress(String command) {
    // Mengambil alamat dari command
    RegExp regex = RegExp(r'(?<=@|\s)([\w.-]+)(?::\d+)?');
    Match? match = regex.firstMatch(command);
    if (match != null) {
      return match.group(0) ?? '';
    }
    return 'Unknown host';
  }

  // Fungsi untuk menampilkan layar terminal setelah login berhasil
  void _showTerminalScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const TerminalScreen(),
      ),
    );
  }
}

// Halaman terminal setelah login berhasil
class TerminalScreen extends StatelessWidget {
  const TerminalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E222A),
        title: const Text(
          "Local Terminal",
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 18,
            color: Colors.white,
          ),
        ),
      ),
      body: Container(
        color: const Color(0xFF15181F),
        padding: const EdgeInsets.all(16),
        child: const Text(
          """
Microsoft Windows [Version 10.0.22631.4169]
(c) Microsoft Corporation. All rights reserved.

foldexz@FOLDEXZ C:\\Users\\FoldExz>
          """,
          style: TextStyle(
            fontFamily: 'CONSOLA',
            fontSize: 18,
            color: Colors.green,
          ),
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
