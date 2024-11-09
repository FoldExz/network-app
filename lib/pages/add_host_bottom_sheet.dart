// lib/pages/add_host_bottom_sheet.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'files_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _saveHostsToPreferences() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  List<String> hostsJsonList =
      hostServers.map((host) => jsonEncode(host)).toList();
  await prefs.setStringList('hostServers', hostsJsonList);
}

void showAddNewHostBottomSheet(BuildContext context) {
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
                            fontSize: 20,
                            color: Colors.white,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Text(
                            "Batal",
                            style: TextStyle(fontSize: 16, color: Colors.green),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(
                      label: 'Name',
                      onChanged: (value) => name = value,
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      label: 'Hostname / IP Address',
                      onChanged: (value) => hostname = value,
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      label: 'Port',
                      onChanged: (value) => port = value,
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      label: 'Username',
                      onChanged: (value) => username = value,
                    ),
                    const SizedBox(height: 12),
                    PasswordField(
                      onChanged: (value) => password = value,
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      label: 'Key',
                      onChanged: (value) => key = value,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () async {
                        // Tambahkan host baru ke daftar
                        final newHost = {
                          "name": name,
                          "hostname": hostname,
                          "port": port,
                          "username": username,
                          "password": password,
                        };
                        hostServers.add(newHost);
                        await _saveHostsToPreferences(); // Menyimpan ke SharedPreferences
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        backgroundColor: Colors.green,
                      ),
                      child: const Text(
                        "Lanjut",
                        style: TextStyle(fontSize: 18, color: Colors.white),
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

Widget _buildTextField({
  required String label,
  required Function(String) onChanged,
}) {
  return TextField(
    onChanged: onChanged,
    style: const TextStyle(color: Colors.white),
    decoration: InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white),
      filled: true,
      fillColor: const Color(0xFF15181F),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    ),
  );
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
