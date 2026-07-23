import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;
  ApiException(this.statusCode, this.message);
  @override
  String toString() => message;
}

/// Thin wrapper around the KIMI BANK core backend.
/// Point [baseUrl] at your local Spring Boot instance (defaults to the
/// Android emulator's loopback alias; change for iOS simulator/device).
class ApiClient {
  ApiClient._internal();
  static final ApiClient instance = ApiClient._internal();

  final String baseUrl = 'http://10.0.2.2:8080';
  final _storage = const FlutterSecureStorage();

  Future<String?> get _accessToken => _storage.read(key: 'access_token');
  Future<String?> get _refreshToken => _storage.read(key: 'refresh_token');

  Future<void> saveTokens({required String access, required String refresh}) async {
    await _storage.write(key: 'access_token', value: access);
    await _storage.write(key: 'refresh_token', value: refresh);
  }

  Future<void> clearTokens() async {
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'refresh_token');
  }

  Future<bool> get isLoggedIn async => (await _accessToken) != null;

  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body,
      {bool auth = true, Map<String, String>? query}) async {
    return _send('POST', path, body: body, auth: auth, query: query);
  }

  Future<dynamic> get(String path, {bool auth = true, Map<String, String>? query}) async {
    return _send('GET', path, auth: auth, query: query);
  }

  Future<dynamic> _send(String method, String path,
      {Map<String, dynamic>? body, bool auth = true, Map<String, String>? query}) async {
    var uri = Uri.parse('$baseUrl$path');
    if (query != null) uri = uri.replace(queryParameters: query);

    final headers = {'Content-Type': 'application/json'};
    if (auth) {
      final token = await _accessToken;
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }

    http.Response response;
    final encodedBody = body != null ? jsonEncode(body) : null;

    switch (method) {
      case 'POST':
        response = await http.post(uri, headers: headers, body: encodedBody);
        break;
      default:
        response = await http.get(uri, headers: headers);
    }

    if (response.statusCode == 401 && auth) {
      final refreshed = await _tryRefresh();
      if (refreshed) return _send(method, path, body: body, auth: auth, query: query);
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    }

    String message = 'Something went wrong';
    try {
      final decoded = jsonDecode(response.body);
      message = decoded['message'] ?? message;
    } catch (_) {}
    throw ApiException(response.statusCode, message);
  }

  Future<bool> _tryRefresh() async {
    final refresh = await _refreshToken;
    if (refresh == null) return false;
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': refresh}),
      );
      if (res.statusCode != 200) return false;
      final decoded = jsonDecode(res.body);
      await saveTokens(access: decoded['accessToken'], refresh: decoded['refreshToken']);
      return true;
    } catch (_) {
      return false;
    }
  }
}
