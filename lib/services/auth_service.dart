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

      print(response);
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
      if (e.message.contains('Invalid token') ||
          e.message.contains('Token has expired')) {
        // Wrong OTP or expired OTP
        if (onVerificationFailed != null) {
          onVerificationFailed(const AuthException(
              'Incorrect verification code or code has expired'));
        }
        throw const AuthException(
            'Incorrect verification code or code has expired');
      } else if (e.message.contains('Token not found')) {
        // OTP doesn't exist
        if (onVerificationFailed != null) {
          onVerificationFailed(const AuthException(
              'Verification code not found. Please request a new one'));
        }
        throw const AuthException(
            'Verification code not found. Please request a new one');
      } else {
        // Other auth errors
        throw e;
      }
    } catch (e) {
      throw AuthException('Verification failed: ${e.toString()}');
    }
  }

  // Sign out the user
  Future<void> signOut() async {
    _supabaseClient.auth.signOut();
  }

  // Get the current user
  Future<User?> getCurrentUser() async {
    final session = _supabaseClient.auth.currentSession;

    if (session != null) return session.user;
    return null;
  }

  bool getCurrentSession() {
    return _supabaseClient.auth.currentSession != null;
  }
}
