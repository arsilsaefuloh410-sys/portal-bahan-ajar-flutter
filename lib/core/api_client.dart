import 'dart:convert';
import 'dart:math' as math;

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';

/// Penyimpanan sesi login (token Bearer + data pengguna).
class Session {
  static String? token;
  static User? user;

  static bool get isLoggedIn => token != null && user != null;
  static bool get isAdmin => user?.isAdmin ?? false;

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString('token');
    final raw = prefs.getString('user');
    user = raw == null ? null : User.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    if (token != null && user == null) {
      await clear();
    }
  }

  static Future<void> save(String newToken, User newUser) async {
    token = newToken;
    user = newUser;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', newToken);
    await prefs.setString('user', jsonEncode({
      'id': newUser.id,
      'nama': newUser.nama,
      'email': newUser.email,
      'role': newUser.role,
    }));
  }

  static Future<void> clear() async {
    token = null;
    user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user');
  }
}

/// Error dari API — pesan sudah berbahasa Indonesia dan siap ditampilkan.
class ApiException implements Exception {
  final String message;
  final int statusCode;
  const ApiException(this.message, this.statusCode);

  @override
  String toString() => message;
}

/// Klien REST untuk folder api/ di server PHP.
class Api {
  /// Emulator Android -> host PC memakai 10.0.2.2.
  /// Untuk HP fisik, ganti ke IP LAN PC, mis. http://192.168.1.5/WEB_MAGANG_SMA_5/api
  static const String baseUrl = 'http://10.0.2.2/WEB_MAGANG_SMA_5/api';

  static Map<String, String> get _headers => {
        'Authorization': 'Bearer ${Session.token ?? ''}',
      };

  static Map<String, String> get _jsonHeaders => {
        ..._headers,
        'Content-Type': 'application/json',
      };

  /// GET lalu kembalikan objek `data` dari respons {ok, message, data}.
  static Future<dynamic> get(String path, {Map<String, String>? query}) async {
    final uri = Uri.parse('$baseUrl/$path').replace(queryParameters: query);
    final res = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 30));
    return _decode(res);
  }

  /// POST JSON lalu kembalikan objek `data`.
  static Future<dynamic> post(String path, Map<String, dynamic> body) async {
    final uri = Uri.parse('$baseUrl/$path');
    final res = await http
        .post(uri, headers: _jsonHeaders, body: jsonEncode(body))
        .timeout(const Duration(seconds: 30));
    return _decode(res);
  }

  /// POST multipart (unggah berkas). `fields` = tambahan selain berkas.
  static Future<dynamic> postMultipart(
    String path, {
    Map<String, String> fields = const {},
    required String fileField,
    required String filePath,
    required String fileName,
  }) async {
    final uri = Uri.parse('$baseUrl/$path');
    final request = http.MultipartRequest('POST', uri)
      ..headers.addAll(_headers)
      ..fields.addAll(fields)
      ..files.add(await http.MultipartFile.fromPath(fileField, filePath, filename: fileName));

    final streamed = await request.send().timeout(const Duration(minutes: 2));
    final res = await http.Response.fromStream(streamed);
    return _decode(res);
  }

  /// Unduh berkas (dengan menghitung download_count di server).
  static Future<List<int>> download(String path) async {
    final uri = Uri.parse('$baseUrl/$path');
    final res = await http.get(uri, headers: _headers).timeout(const Duration(minutes: 2));
    if (res.statusCode == 401 || res.statusCode == 403 || res.statusCode == 404) {
      throw ApiException(_messageOf(res) ?? 'Gagal mengunduh berkas.', res.statusCode);
    }
    if (res.statusCode != 200) {
      throw ApiException('Gagal mengunduh berkas (HTTP ${res.statusCode}).', res.statusCode);
    }
    return res.bodyBytes;
  }

  static Future<dynamic> _decode(http.Response res) async {
    Map<String, dynamic> json;
    try {
      final decoded = jsonDecode(utf8.decode(res.bodyBytes));
      json = decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
    } on FormatException {
      throw ApiException('Respons server tidak valid (HTTP ${res.statusCode}).', res.statusCode);
    }

    if (res.statusCode == 401) {
      await Session.clear();
    }

    if (json['ok'] != true || res.statusCode >= 400) {
      throw ApiException(
        json['message'] as String? ?? 'Terjadi kesalahan (HTTP ${res.statusCode}).',
        res.statusCode,
      );
    }
    return json['data'];
  }

  static String? _messageOf(http.Response res) {
    try {
      final decoded = jsonDecode(utf8.decode(res.bodyBytes));
      if (decoded is Map<String, dynamic>) return decoded['message'] as String?;
    } on FormatException {
      // abaikan
    }
    return null;
  }
}

/// Format ukuran bytes identik dengan format_bytes() di PHP.
String formatBytes(int bytes, {int precision = 1}) {
  const units = ['B', 'KB', 'MB', 'GB'];
  var size = bytes < 0 ? 0 : bytes.toDouble();
  var pow = size == 0 ? 0 : (math.log(size) / math.log(1024)).floor();
  if (pow > units.length - 1) pow = units.length - 1;
  size /= math.pow(1024, pow).toDouble();
  return '${size.toStringAsFixed(precision)} ${units[pow]}';
}
