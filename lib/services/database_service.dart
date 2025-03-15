import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:echo/models/user.dart' as model;


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

  Future<void> fetchUserInfo(String uid,
      {Function(model.User user)? onSuccess,
      Function(Object e)? onFailure}) async {
    try {
      final response = await _supabaseClient
          .from(USERS_DATABASE)
          .select()
          .filter('uid', 'eq', uid);

      if (response.isNotEmpty) {
        if(onSuccess != null){
          onSuccess(model.User.fromMap(response[0]));
        }
      } else {
        if (onFailure != null) onFailure("user does not exist");
      }
    } catch (e) {
      if (onFailure != null) {
        onFailure(e);
      }
    }
  }

  Future<List<model.User>> fetchRegisteredUsers(List<String> phoneNumbers,
      {Function(List<model.User> users)? onSuccess,
      Function(Object e)? onFailure}) async {
    try {
      final response = await _supabaseClient
          .from(USERS_DATABASE)
          .select()
          .filter("phoneNumber", "in", phoneNumbers);

      List<model.User> users = [];
      for (var mp in response) {
        users.add(model.User.fromMap(mp));
      }
      return users;
    } catch (e) {
      if (onFailure != null) {
        onFailure(e);
      }
      throw e;
    }
  }

  Future<model.User?> getCurrentUser() async {
    try {
      final currentUserId = _supabaseClient.auth.currentUser?.id;

      if (currentUserId == null) {
        return null;
      }

      final response = await _supabaseClient
          .from(USERS_DATABASE)
          .select()
          .eq('uid', currentUserId)
          .limit(1)
          .single();

      return model.User.fromMap(response);
    } catch (e) {
      print("Error getting current user: ${e.toString()}");
      return null;
    }
  }

  String getCurrentUserId(){
    return _supabaseClient.auth.currentUser!.id;
  }


}
