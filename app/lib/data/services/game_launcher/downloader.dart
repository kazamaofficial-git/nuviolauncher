import 'dart:io';

import 'package:crypto/crypto.dart' as crypto;
import 'package:http/http.dart' as http;

/// A file to fetch, with optional integrity data.
class DownloadTask {
  const DownloadTask({required this.url, required this.dest, this.sha1, this.size});

  final String url;
  final File dest;
  final String? sha1;
  final int? size;
}

/// Resumable-by-retry file downloader with SHA-1 verification.
class Downloader {
  Downloader(this._client);

  final http.Client _client;

  /// Downloads only when the file is missing or its size differs.
  Future<void> ensure(DownloadTask task) async {
    if (await _looksComplete(task)) return;
    await download(task.url, task.dest, expectedSha1: task.sha1);
  }

  Future<bool> _looksComplete(DownloadTask task) async {
    if (!await task.dest.exists()) return false;
    final size = task.size;
    if (size == null) return true;
    return await task.dest.length() == size;
  }

  /// Always (re)downloads [url] to [dest], retrying up to three times.
  Future<void> download(String url, File dest, {String? expectedSha1}) async {
    await dest.parent.create(recursive: true);
    final part = File('${dest.path}.part');
    Object? lastError;

    for (var attempt = 1; attempt <= 3; attempt++) {
      try {
        final response = await _client
            .send(http.Request('GET', Uri.parse(url)))
            .timeout(const Duration(seconds: 30));
        if (response.statusCode != 200) {
          throw HttpException('HTTP ${response.statusCode}', uri: Uri.parse(url));
        }
        await response.stream.pipe(part.openWrite());

        if (expectedSha1 != null) {
          final digest = await crypto.sha1.bind(part.openRead()).first;
          if (digest.toString() != expectedSha1.toLowerCase()) {
            throw const FormatException('Checksum mismatch');
          }
        }
        if (await dest.exists()) await dest.delete();
        await part.rename(dest.path);
        return;
      } catch (e) {
        lastError = e;
        if (await part.exists()) await part.delete();
        await Future<void>.delayed(Duration(milliseconds: 400 * attempt));
      }
    }
    throw HttpException('Failed to download $url ($lastError)');
  }
}
