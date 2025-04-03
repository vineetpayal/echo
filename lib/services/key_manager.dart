import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class KeyManager {
  static final _storage = FlutterSecureStorage();

  static Future<void> generateAndStoreKey() async {
    String? existingKey= await _storage.read(key: 'encryption_key');

    if(existingKey == null) {
      final secretKey = await AesGcm.with256bits().newSecretKey();
      final keyBytes = await secretKey.extractBytes();
      final keyBase64 = base64Encode(keyBytes);
      await _storage.write(key: 'encryption_key', value: keyBase64);
      await _storage.write(key: 'encryption_key_generated', value: 'true');
      debugPrint("Key Generated: $keyBase64");
    }
  }

  static Future<String?> getKey() async {
    return await _storage.read(key: 'encryption_key');
  }
}
