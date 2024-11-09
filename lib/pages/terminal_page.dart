import 'package:flutter/material.dart';
import '../utils/ssh_connection.dart';

class TerminalPage extends StatelessWidget {
  // Remove const keyword here
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

  void _showPasswordBottomSheet(BuildContext context, String command) {
    String address = _extractAddress(command);

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
              children: [
                TextField(
                  controller: _hostController,
                  decoration: const InputDecoration(
                    labelText: 'Host Address',
                    filled: true,
                    fillColor: Color(0xFF15181F),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    filled: true,
                    fillColor: Color(0xFF15181F),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    filled: true,
                    fillColor: Color(0xFF15181F),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    String host = _hostController.text;
                    String username = _usernameController.text;
                    String password = _passwordController.text;

                    await _sshConnection.connect(host, username, password);
                    Navigator.pop(context);
                    _showTerminalScreen(context);
                  },
                  child: const Text("Connect"),
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

  void _showTerminalScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TerminalScreen(sshConnection: _sshConnection),
      ),
    );
  }
}

// Halaman terminal setelah login berhasil
class TerminalScreen extends StatefulWidget {
  final SSHConnection sshConnection;

  const TerminalScreen({super.key, required this.sshConnection});

  @override
  _TerminalScreenState createState() => _TerminalScreenState();
}

class _TerminalScreenState extends State<TerminalScreen> {
  final TextEditingController _commandController = TextEditingController();
  String _output = "";

  Future<void> _sendCommand() async {
    final result =
        await widget.sshConnection.executeCommand(_commandController.text);
    setState(() {
      _output += '\n\$ ${_commandController.text}\n$result';
    });
    _commandController.clear();
  }

  @override
  void dispose() {
    widget.sshConnection.close();
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
                child:
                    Text(_output, style: const TextStyle(color: Colors.green)),
              ),
            ),
            TextField(
              controller: _commandController,
              decoration: const InputDecoration(hintText: "Enter command"),
              onSubmitted: (_) => _sendCommand(),
            ),
            ElevatedButton(
              onPressed: _sendCommand,
              child: const Text("Send"),
            ),
          ],
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
