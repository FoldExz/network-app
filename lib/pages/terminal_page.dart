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
          };
        }).toList();
      });
    }
  }

  // Save a new host to SharedPreferences, ensuring no duplicates
  Future<void> _saveHost(String host, String username) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> hostList = prefs.getStringList('savedHosts') ?? [];

    // Check if the host and username combination already exists
    bool exists = hostList.any((item) {
      final parts = item.split('|');
      return parts[0] == host && parts[1] == username;
    });

    if (!exists) {
      // If the host-username combination doesn't exist, add it
      hostList.add('$host|$username');
      await prefs.setStringList('savedHosts', hostList);
      _loadHosts(); // Reload hosts after saving
    } else {
      // Optionally, show an error or message to inform the user
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This configuration already exists!')),
      );
    }
  }

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
                            hintText: 'Search / Type a command',
                            hintStyle: TextStyle(
                              color: AppColors.mediumGray,
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
                    color: AppColors.white,
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
                // Inside ListView.builder:
                Expanded(
                  child: ListView.builder(
                    itemCount: savedHosts.length,
                    itemBuilder: (context, index) {
                      final host = savedHosts[index];
                      return ListTile(
                        title: Text(
                          host['host'] ?? '',
                          style: TextStyle(
                              color: AppColors.white, fontSize: baseFontSize),
                        ),
                        subtitle: Text(
                          host['username'] ?? '',
                          style: TextStyle(
                            color: AppColors.mediumGray,
                            fontSize: baseFontSize * 0.9,
                          ),
                        ),
                        onTap: () async {
                          // Grab the host and username from the tapped saved host
                          String selectedHost = host['host'] ?? '';
                          String selectedUsername = host['username'] ?? '';

                          // Optionally, you could load the password from SharedPreferences, or prompt the user for it
                          Map<String, String?> config =
                              await _loadConfiguration();
                          String? savedPassword = config['password'];

                          // You can use this data to either connect directly or show a password entry modal
                          if (selectedHost.isNotEmpty &&
                              selectedUsername.isNotEmpty) {
                            // Option 1: Direct connection (if password is available)
                            if (savedPassword != null) {
                              _sshConnection.connect(selectedHost,
                                  selectedUsername, savedPassword);
                              _showTerminalScreen(context);
                            } else {
                              // Option 2: Show password input modal if password is missing
                              _showPasswordBottomSheet(context,
                                  "ssh $selectedUsername@$selectedHost");
                            }
                          } else {
                            // Handle any error cases, e.g., invalid host/username
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text('Invalid saved host or username')),
                            );
                          }
                        },
                      );
                    },
                  ),
                )
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
    bool isLoading = false;
    bool isError = false;

    Map<String, String?> config = await _loadConfiguration();
    String host = config['host'] ?? '';
    String username = config['username'] ?? '';

    // If command is provided, parse it
    if (command.startsWith("ssh")) {
      final regex = RegExp(r"ssh\s+([^\@]+)\@([^\s]+)");
      final match = regex.firstMatch(command);

      if (match != null) {
        username = match.group(1) ?? '';
        host = match.group(2) ?? '';
      }
    }

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
                          'New host',
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
                    if (isLoading)
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
                            isLoading = true;
                            isError = false;
                          });

                          String host = _hostController.text;
                          String username = _usernameController.text;
                          String password = _passwordController.text;

                          bool isReachable = await _checkHostAvailability(host);
                          if (!isReachable) {
                            setState(() {
                              isLoading = false;
                              isError = true;
                            });
                            return;
                          }

                          try {
                            await _sshConnection.connect(
                                host, username, password);
                            // Save configuration dan host
                            await _saveConfiguration(host, username, password);
                            await _saveHost(host, username);

                            Navigator.pop(context);
                            _showTerminalScreen(
                                context); //membuka termninal screen
                          } catch (e) {
                            setState(() {
                              isLoading = false;
                              isError = true;
                            });

                            print("Connection failed: $e");
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
