import 'dart:io';
import 'package:echo/models/user.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StorageService {
  final SupabaseClient _supabaseClient = Supabase.instance.client;
  static const String PROFILES_BUCKET = "profiles_bucket";

  Future<String?> uploadImage(File file, String userId) async {
    try {
      final filePath = "$userId/profile_image.jpg";

      print(filePath);
      await _supabaseClient.storage
          .from(PROFILES_BUCKET)
          .upload(filePath, file);

      //get the public url
      final imageUrl =
          _supabaseClient.storage.from(PROFILES_BUCKET).getPublicUrl(filePath);

      return imageUrl;
    } catch (e) {
      throw e;
    }
  }
}
