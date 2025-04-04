import 'dart:typed_data';
import 'package:echo/services/chat_service.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

class EncryptionService {
  static final _storage = FlutterSecureStorage();

  static Future<encrypt.Encrypter> _getEncrypter(String chatRoomId) async {
    //fetch from chatRoom
    String? keyBase64 = await ChatService.fetchEncryptionKey(chatRoomId);

    if (keyBase64 == null) throw Exception("Encryption Key not found");

    //debug
    print("Encryption Key: $keyBase64");

    final key = encrypt.Key.fromBase64(keyBase64);
    return encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.ecb));
  }

  //encryption
  static Future<String> encryptText(String text, String chatRoomId) async {
    final encrypter = await _getEncrypter(chatRoomId);
    final encrypted = encrypter.encrypt(text);
    return base64Encode(encrypted.bytes);
  }

  //decryption
  static Future<String> decryptText(
      String encryptedText, String chatRoomId) async {
    try {
      final encrypter = await _getEncrypter(chatRoomId);

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
