import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;

class NetworkCheck {
  // Mengecek apakah perangkat terhubung ke jaringan (WiFi atau data seluler)
  static Future<bool> isNetworkAvailable() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  // Mengecek apakah perangkat memiliki akses internet dengan ping ke server Google
  static Future<bool> isInternetAvailable() async {
    try {
      final response = await http
          .get(Uri.parse('https://www.google.com'))
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // Memantau perubahan status jaringan dan internet secara real-time
  static Stream<bool> get internetStatusStream async* {
    yield await isInternetAvailable();
    // ignore: unused_local_variable
    await for (var status in Connectivity().onConnectivityChanged) {
      yield await isInternetAvailable();
    }
  }
}
