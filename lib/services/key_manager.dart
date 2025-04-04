import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import 'package:echo/services/database_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class KeyManager {
  static final _storage = FlutterSecureStorage();

  //just generate the key
  static Future<String> generateKey() async {
    final secretKey = await AesGcm.with256bits().newSecretKey();
    final keyBytes = await secretKey.extractBytes();
    final keyBase64 = base64Encode(keyBytes);

    //debug
    debugPrint("Key Generated: $keyBase64");
    return keyBase64;
  }

  static Future<String?> getKey() async {
    return await _storage.read(key: 'encryption_key');
  }
}
