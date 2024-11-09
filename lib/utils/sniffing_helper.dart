import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_network_inspector/models/inspector_result.dart';
import 'package:http/http.dart' as http;

class FNICLient {
  static final ValueNotifier<List<InspectorResult>> inspectorNotifierList =
      ValueNotifier([]);

  Future<http.Response> get(Uri url, {Map<String, String>? headers}) async {
    InspectorResult result =
        InspectorResult(url: url, startTime: DateTime.now());

    // Buat salinan sementara dan tambahkan `result`
    final updatedList = List<InspectorResult>.from(inspectorNotifierList.value);
    updatedList.add(result);
    inspectorNotifierList.value = updatedList; // Memicu notifyListeners

    final response = await http.get(url, headers: headers);
    result.endTime = DateTime.now();
    result.statusCode = response.statusCode;
    result.reasonPhrase = response.reasonPhrase;
    result.responseBodyBytes = response.bodyBytes.length;

    // Memperbarui kembali value untuk memicu notifyListeners
    inspectorNotifierList.value =
        List<InspectorResult>.from(inspectorNotifierList.value);

    return response;
  }

  Future<http.Response> post(Uri url,
      {Map<String, String>? headers, Object? body}) async {
    InspectorResult result =
        InspectorResult(url: url, startTime: DateTime.now());

    final updatedList = List<InspectorResult>.from(inspectorNotifierList.value);
    updatedList.add(result);
    inspectorNotifierList.value = updatedList; // Memicu notifyListeners

    final response = await http.post(url, headers: headers, body: body);
    result.endTime = DateTime.now();
    result.statusCode = response.statusCode;
    result.reasonPhrase = response.reasonPhrase;
    result.responseBodyBytes = response.bodyBytes.length;

    inspectorNotifierList.value =
        List<InspectorResult>.from(inspectorNotifierList.value);

    return response;
  }

  Future<http.Response> put(Uri url,
      {Map<String, String>? headers, Object? body}) async {
    InspectorResult result =
        InspectorResult(url: url, startTime: DateTime.now());

    final updatedList = List<InspectorResult>.from(inspectorNotifierList.value);
    updatedList.add(result);
    inspectorNotifierList.value = updatedList; // Memicu notifyListeners

    final response = await http.put(url, headers: headers, body: body);
    result.endTime = DateTime.now();
    result.statusCode = response.statusCode;
    result.reasonPhrase = response.reasonPhrase;
    result.responseBodyBytes = response.bodyBytes.length;

    inspectorNotifierList.value =
        List<InspectorResult>.from(inspectorNotifierList.value);

    return response;
  }

  Future<http.Response> patch(Uri url,
      {Map<String, String>? headers, Object? body}) async {
    InspectorResult result =
        InspectorResult(url: url, startTime: DateTime.now());

    final updatedList = List<InspectorResult>.from(inspectorNotifierList.value);
    updatedList.add(result);
    inspectorNotifierList.value = updatedList; // Memicu notifyListeners

    final response = await http.patch(url, headers: headers, body: body);
    result.endTime = DateTime.now();
    result.statusCode = response.statusCode;
    result.reasonPhrase = response.reasonPhrase;
    result.responseBodyBytes = response.bodyBytes.length;

    inspectorNotifierList.value =
        List<InspectorResult>.from(inspectorNotifierList.value);

    return response;
  }

  Future<http.Response> delete(Uri url, {Map<String, String>? headers}) async {
    InspectorResult result =
        InspectorResult(url: url, startTime: DateTime.now());

    final updatedList = List<InspectorResult>.from(inspectorNotifierList.value);
    updatedList.add(result);
    inspectorNotifierList.value = updatedList; // Memicu notifyListeners

    final response = await http.delete(url, headers: headers);
    result.endTime = DateTime.now();
    result.statusCode = response.statusCode;
    result.reasonPhrase = response.reasonPhrase;
    result.responseBodyBytes = response.bodyBytes.length;

    inspectorNotifierList.value =
        List<InspectorResult>.from(inspectorNotifierList.value);

    return response;
  }

  void setEnableLogging(bool enable) {
    // Implementasi untuk mengatur logging
  }

  void close() {
    // Implementasi untuk menutup koneksi jika diperlukan
  }
}
