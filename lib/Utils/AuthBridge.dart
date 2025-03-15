import 'package:echo/screens/add_profile_screen.dart';
import 'package:echo/screens/home_screen.dart';
import 'package:echo/screens/login_screen.dart';
import 'package:echo/services/auth_service.dart';
import 'package:echo/services/database_service.dart';
import 'package:flutter/material.dart';

class AuthBridge extends StatefulWidget {
  const AuthBridge({super.key});

  @override
  State<AuthBridge> createState() => _AuthBridgeState();
}

class _AuthBridgeState extends State<AuthBridge> {
  final _authService = AuthService();

  final _databaseService = DatabaseService();

  @override
  Widget build(BuildContext context) {
    return !isUserLoggedIn()
        ? const LoginScreen()
        : ((isUserDetailUploaded())
            ? const HomeScreen()
            : const AddProfileScreen());
  }

  //return true if the user is logged in
  bool isUserLoggedIn() {
    return _authService.getCurrentSession();
  }

  //return true if user has registered his info like name,profile etc.
  bool isUserDetailUploaded() {
    var uploaded = true;
    var currentUserId = _databaseService.getCurrentUserId();
    _databaseService.fetchUserInfo(currentUserId, onSuccess: (user) {
      uploaded = true;
    }, onFailure: (e) {
      if (e == "user does not exist") {
        uploaded = false;
      }
    });
    return uploaded;
  }
}
