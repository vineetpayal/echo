import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:echo/models/user.dart';

class DatabaseService {
  final SupabaseClient _supabaseClient = Supabase.instance.client;
  static const String USERS_DATABASE = "users";

  Future<void> uploadUserInfo(user,
      {Function(dynamic response)? onSuccess,
      Function(dynamic response)? onFailure}) async {
    try {
      final response = await _supabaseClient
          .from(USERS_DATABASE)
          .upsert(user.toMap())
          .select();
      if (response.isEmpty) {
        if (onFailure != null) onFailure(response);
      } else {
        if (onSuccess != null) onSuccess(response);
      }
    } catch (e) {
      throw e;
    }
  }
}
