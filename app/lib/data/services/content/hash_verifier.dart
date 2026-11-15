import 'dart:io';

import 'package:crypto/crypto.dart' as crypto;

class _DigestSink implements Sink<crypto.Digest> {
  crypto.Digest? value;

  @override
  void add(crypto.Digest data) => value = data;

  @override
  void close() {}
}

/// SHA-1 / SHA-512 integrity checks for downloaded content.
abstract final class HashVerifier {
  /// Returns null when every supplied hash matches, otherwise an error message.
  /// Hashes that are null or empty are skipped.
  static String? verifyBytes(List<int> bytes, {String? sha1, String? sha512}) {
    if (_has(sha1) && crypto.sha1.convert(bytes).toString() != sha1!.trim().toLowerCase()) {
      return 'SHA-1 checksum mismatch';
    }
    if (_has(sha512) &&
        crypto.sha512.convert(bytes).toString() != sha512!.trim().toLowerCase()) {
      return 'SHA-512 checksum mismatch';
    }
    return null;
  }

  /// Streaming variant of [verifyBytes] for files on disk.
  static Future<String?> verifyFile(File file, {String? sha1, String? sha512}) async {
    if (!_has(sha1) && !_has(sha512)) return null;
    final sha1Sink = _DigestSink();
    final sha512Sink = _DigestSink();
    final sha1Conv = crypto.sha1.startChunkedConversion(sha1Sink);
    final sha512Conv = crypto.sha512.startChunkedConversion(sha512Sink);
    await for (final chunk in file.openRead()) {
      if (_has(sha1)) sha1Conv.add(chunk);
      if (_has(sha512)) sha512Conv.add(chunk);
    }
    sha1Conv.close();
    sha512Conv.close();
    if (_has(sha1) && sha1Sink.value.toString() != sha1!.trim().toLowerCase()) {
      return 'SHA-1 checksum mismatch';
    }
    if (_has(sha512) && sha512Sink.value.toString() != sha512!.trim().toLowerCase()) {
      return 'SHA-512 checksum mismatch';
    }
    return null;
  }

  static bool _has(String? v) => v != null && v.trim().isNotEmpty;
}
