import 'package:echo/Theme/dark_theme.dart';
import 'package:echo/screens/contacts_screen.dart';
import 'package:echo/screens/home_screen.dart';
import 'package:echo/screens/login_screen.dart';
import 'package:echo/screens/add_profile_screen.dart';
import 'package:echo/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'models/user.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  await Supabase.initialize(
      url: "https://guhmljhxhlcltjeubsit.supabase.co",
      anonKey:
          "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imd1aG1samh4aGxjbHRqZXVic2l0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Mzk2Mjk1MzYsImV4cCI6MjA1NTIwNTUzNn0.7PyX2x3c7LfnrVwDgm7HzzSlVAgWrkBG106nCioSLV0");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    //check if the user is logged in
    AuthService authService = AuthService();
    bool isLoggedIn = authService.getCurrentSession();

    return MaterialApp(
      //Dark Mode Theme – Black + Neon Blue (Futuristic, Tech)
      title: 'Echo',
      debugShowCheckedModeBanner: false,
      theme: darkTheme,

      //open HomeScreen directly if the user is already logged in
      home: isLoggedIn ? const HomeScreen() : const LoginScreen(),
    );
  }
}
