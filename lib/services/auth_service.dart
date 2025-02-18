import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabaseClient = Supabase.instance.client;

  // Send OTP to the user's phone number
  Future<void> sendOTP(String phoneNumber) async {
    try {
      await _supabaseClient.auth.signInWithOtp(phone: phoneNumber);
    } catch (e) {
      throw e;
    }
  }

  // Verify the OTP entered by the user
  Future<User?> verifyOTP(String phoneNumber, String smsCode,
      {Function(User? user)? onVerificationCompleted,
      Function(AuthException e)? onVerificationFailed}) async {
    //send verify request
    try {
      AuthResponse response = await _supabaseClient.auth
          .verifyOTP(type: OtpType.sms, phone: phoneNumber, token: smsCode);

      if (response.user != null && response.session != null) {
        if (onVerificationCompleted != null) {
          onVerificationCompleted(response.user);
        }
        return response.user;
      } else {
        if (onVerificationFailed != null) {
          onVerificationFailed(const AuthException("Verification Failed"));
        }
      }
    } on AuthException catch (e) {
      if (onVerificationFailed != null) {
        onVerificationFailed(e);
      }
      throw e;
    }
  }

  // Sign out the user
  Future<void> signOut() async {
    _supabaseClient.auth.signOut();
  }

  // Get the current user
  User? getCurrentUser() {
    _supabaseClient.auth.currentUser;
  }
}
