import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Offline-mode player UUID: name-based UUID v3 of `OfflinePlayer:<name>`,
/// the same scheme the vanilla server uses for offline players.
String offlineUuid(String playerName) {
  final bytes = md5.convert(utf8.encode('OfflinePlayer:$playerName')).bytes.toList();
  bytes[6] = (bytes[6] & 0x0f) | 0x30; // version 3
  bytes[8] = (bytes[8] & 0x3f) | 0x80; // IETF variant
  final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}

/// Validates a Minecraft-style username (3-16 chars, letters/digits/underscore).
bool isValidUsername(String name) => RegExp(r'^[A-Za-z0-9_]{3,16}$').hasMatch(name);
