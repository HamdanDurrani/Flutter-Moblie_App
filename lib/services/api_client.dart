import 'dart:convert';

import 'package:http/http.dart' as http;

/// Same backend the Expo app uses (trim trailing slash / whitespace).
const String kApiBaseUrl =
    'https://uninertly-merry-stephane.ngrok-free.dev';

const String kStorageTokenKey = 'pc.ops.access_token.v3';
const String kStorageSessionKey = 'pc.ops.session.v3';

class ApiError implements Exception {
  ApiError(this.status, this.detail);

  final int status;
  final String detail;

  @override
  String toString() => detail;
}

class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  String? _accessToken;

  void setAccessToken(String? token) => _accessToken = token;

  String? get accessToken => _accessToken;

  String get baseUrl => kApiBaseUrl.replaceAll(RegExp(r'/$'), '');

  Future<T> request<T>(
    String path, {
    String method = 'GET',
    Map<String, dynamic>? body,
    bool auth = true,
    String fallbackError = 'Request failed.',
  }) async {
    final headers = <String, String>{
      'Accept': 'application/json',
      // ngrok free interstitial bypass
      'ngrok-skip-browser-warning': 'true',
    };
    if (body != null) headers['Content-Type'] = 'application/json';
    if (auth) {
      final token = _accessToken;
      if (token == null || token.isEmpty) {
        throw ApiError(401, 'Not signed in.');
      }
      headers['Authorization'] = 'Bearer $token';
    }

    final uri = Uri.parse('$baseUrl$path');
    late http.Response res;
    try {
      switch (method.toUpperCase()) {
        case 'POST':
          res = await _client.post(
            uri,
            headers: headers,
            body: body == null ? null : jsonEncode(body),
          );
        case 'PATCH':
          res = await _client.patch(
            uri,
            headers: headers,
            body: body == null ? null : jsonEncode(body),
          );
        case 'DELETE':
          res = await _client.delete(uri, headers: headers);
        default:
          res = await _client.get(uri, headers: headers);
      }
    } catch (_) {
      throw ApiError(
        0,
        'Could not reach API at $baseUrl. Is the backend running?',
      );
    }

    dynamic parsed;
    if (res.body.isNotEmpty) {
      try {
        parsed = jsonDecode(res.body);
      } catch (_) {
        parsed = null;
      }
    }

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw ApiError(res.statusCode, _readDetail(parsed, fallbackError));
    }

    return parsed as T;
  }

  String _readDetail(dynamic body, String fallback) {
    if (body is! Map) return fallback;
    final detail = body['detail'];
    if (detail is String && detail.trim().isNotEmpty) return detail;
    if (detail is List) {
      final msgs = detail
          .map((item) {
            if (item is String) return item;
            if (item is Map && item['msg'] != null) return '${item['msg']}';
            return '';
          })
          .where((s) => s.isNotEmpty)
          .join('\n');
      if (msgs.isNotEmpty) return msgs;
    }
    return fallback;
  }
}
