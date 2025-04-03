import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

class EncryptionService {
  static final _storage = FlutterSecureStorage();

  static Future<encrypt.Encrypter> _getEncrypter() async {
    String? keyBase64 = await _storage.read(key: 'encryption_key');
    if (keyBase64 == null) throw Exception('Encryption key not found');

    final key = encrypt.Key.fromBase64(keyBase64);
    return encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.ecb));
  }

  static Future<String> encryptText(String text) async {
    final encrypter = await _getEncrypter();
    final encrypted = encrypter.encrypt(text);
    return base64Encode(encrypted.bytes);
  }

  static Future<String> decryptText(String encryptedText) async {
    try {
      final encrypter = await _getEncrypter();

      // Validate Base64 input
      Uint8List encryptedBytes;
      try {
        encryptedBytes = base64Decode(encryptedText);
      } catch (e) {
        throw Exception('Invalid Base64 input: $e');
      }

      // Decrypt
      try {
        final encrypted = encrypt.Encrypted(encryptedBytes);
        return encrypter.decrypt(encrypted);
      } catch (e) {
        throw Exception('Decryption failed: $e');
      }
    } catch (e) {
      print("Decryption error: $e");
      rethrow;
    }
  }
}
