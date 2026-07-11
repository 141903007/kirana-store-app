import 'dart:convert';

import 'package:crypto/crypto.dart';

/// One-way SHA-256 hashing for locally stored credentials.
///
/// There is no server round-trip in this offline app, so a per-user salt
/// would only protect against someone reading this device's own database
/// file to attack itself — a plain hash is sufficient here.
class PasswordHasher {
  PasswordHasher._();

  static String hash(String plainText) {
    return sha256.convert(utf8.encode(plainText)).toString();
  }

  static bool matches(String plainText, String hash) {
    return PasswordHasher.hash(plainText) == hash;
  }
}
