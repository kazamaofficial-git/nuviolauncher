import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/constants/app_constants.dart';

/// Error returned by (or while reaching) the Nuvio API.
class ApiException implements Exception {
  const ApiException({required this.code, required this.message, this.status});

  /// API error code (see docs/API.md) or `NETWORK`.
  final String code;
  final String message;
  final int? status;

  bool get isNetwork => code == 'NETWORK';

  @override
  String toString() => 'ApiException($code): $message';
}

/// Thin JSON client for the Nuvio website API.
class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const Map<String, String> _headers = {
    'content-type': 'application/json',
    'accept': 'application/json',
  };

  Uri _uri(String path) => Uri.parse(AppConstants.resolveUrl(path));

  Future<Map<String, dynamic>> getJson(String path) =>
      _send(() => _client.get(_uri(path), headers: _headers));

  Future<Map<String, dynamic>> postJson(String path, Map<String, dynamic> body) =>
      _send(() => _client.post(_uri(path), headers: _headers, body: jsonEncode(body)));

  Future<Map<String, dynamic>> _send(Future<http.Response> Function() request) async {
    final http.Response res;
    try {
      res = await request().timeout(AppConstants.apiTimeout);
    } on TimeoutException {
      throw const ApiException(
        code: 'NETWORK',
        message: 'The server took too long to respond.',
      );
    } catch (_) {
      throw const ApiException(
        code: 'NETWORK',
        message: 'Cannot reach the Nuvio server. Check your connection.',
      );
    }

    Object? decoded;
    try {
      decoded = jsonDecode(utf8.decode(res.bodyBytes));
    } on FormatException {
      throw ApiException(
        code: 'SERVER_ERROR',
        message: 'Unexpected server response (HTTP ${res.statusCode}).',
        status: res.statusCode,
      );
    }
    if (decoded is! Map<String, dynamic>) {
      throw ApiException(
        code: 'SERVER_ERROR',
        message: 'Unexpected server response (HTTP ${res.statusCode}).',
        status: res.statusCode,
      );
    }
    if (res.statusCode >= 400 || decoded['ok'] == false) {
      throw ApiException(
        code: decoded['code'] as String? ?? 'SERVER_ERROR',
        message: decoded['message'] as String? ?? 'Request failed.',
        status: res.statusCode,
      );
    }
    return decoded;
  }
}
