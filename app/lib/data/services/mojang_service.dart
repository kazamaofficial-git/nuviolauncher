import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/constants/app_constants.dart';
import '../models/mc_version.dart';

/// Fetches Mojang's version manifest.
class MojangService {
  MojangService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<List<McVersion>> fetchVersions() async {
    final res = await _client
        .get(Uri.parse(AppConstants.versionManifestUrl))
        .timeout(const Duration(seconds: 20));
    if (res.statusCode != 200) {
      throw Exception('Mojang returned HTTP ${res.statusCode}');
    }
    final json = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    final list = json['versions'] as List<dynamic>? ?? const [];
    return list
        .whereType<Map<String, dynamic>>()
        .map(McVersion.fromJson)
        .toList();
  }
}
