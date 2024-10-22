import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter1/firebase_options.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter1/pages/speed_test_page.dart';
import 'package:flutter1/pages/sniffing_page.dart';
import 'package:flutter1/pages/terminal_page.dart';
import 'package:flutter1/pages/vpn_page.dart';
import 'package:flutter1/pages/files_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        primarySwatch: Colors.blue,
        textTheme: const TextTheme(
          bodyLarge: TextStyle(fontFamily: 'Poppins'),
          bodyMedium: TextStyle(fontFamily: 'Poppins'),
        ),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  static const List<Widget> _pages = <Widget>[
    SpeedTestPage(),
    SniffingPage(),
    TerminalPage(),
    VPNPage(),
    FileTransferPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: _buildIcon('assets/icons/speedtest.svg', 0),
            label: 'Speed',
          ),
          BottomNavigationBarItem(
            icon: _buildIcon('assets/icons/sniffing.svg', 1),
            label: 'Sniffing',
          ),
          BottomNavigationBarItem(
            icon: _buildIcon('assets/icons/terminal.svg', 2),
            label: 'Terminal',
          ),
          BottomNavigationBarItem(
            icon: _buildIcon('assets/icons/vpn.svg', 3),
            label: 'VPN',
          ),
          BottomNavigationBarItem(
            icon: _buildIcon('assets/icons/files.svg', 4),
            label: 'Files',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white.withOpacity(0.4),
        backgroundColor: Colors.black,
        type: BottomNavigationBarType.fixed,
        onTap: _onItemTapped,
      ),
    );
  }

  Widget _buildIcon(String assetPath, int index) {
    return Opacity(
      opacity: _selectedIndex == index ? 1.0 : 0.4,
      child: SvgPicture.asset(
        assetPath,
        width: 24,
        height: 24,
        colorFilter: _selectedIndex == index
            ? null
            : const ColorFilter.mode(Colors.white, BlendMode.srcIn),
      ),
    );
  }
}
