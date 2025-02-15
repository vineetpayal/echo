import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: Colors.black, // ✅ Fully black background
  colorScheme: ColorScheme.dark(
    surface: Colors.black,
    primary: const Color(0xFF2323FF), // ✅ Neon blue for buttons
    secondary: Colors.grey[900]!,
    onPrimary: Colors.white, // ✅ White text on primary buttons
    onSurface: Colors.white, // ✅ White text everywhere
  ),
  hintColor: const Color(0xFF2323FF), // ✅ Neon blue hint text

  // ✅ White text globally
  textTheme: GoogleFonts.robotoTextTheme().apply(
    bodyColor: Colors.white,
    displayColor: Colors.white,
  ),

  // ✅ Neon blue for selected buttons
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF2323FF),
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
    ),
  ),

  // ✅ Grey border normally, neon blue on focus
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.black, // ✅ Black background for input fields
    hintStyle: TextStyle(color: Colors.grey[400]), // ✅ Light grey hint text
    labelStyle: const TextStyle(color: Colors.white), // ✅ White labels

    // ✅ Normal border (Grey)
    enabledBorder: OutlineInputBorder(
      borderSide: BorderSide(color: Colors.grey[700]!, width: 1),
      borderRadius: BorderRadius.circular(8),
    ),

    // ✅ Focused border (Neon Blue)
    focusedBorder: OutlineInputBorder(
      borderSide: const BorderSide(color: Color(0xFF2323FF), width: 2),
      borderRadius: BorderRadius.circular(8),
    ),

    // ✅ Error border (Red)
    errorBorder: OutlineInputBorder(
      borderSide: const BorderSide(color: Colors.red, width: 2),
      borderRadius: BorderRadius.circular(8),
    ),

    // ✅ Border when there's an error and focused
    focusedErrorBorder: OutlineInputBorder(
      borderSide: const BorderSide(color: Colors.redAccent, width: 2),
      borderRadius: BorderRadius.circular(8),
    ),
  ),

  // ✅ Neon blue icons
  iconTheme: const IconThemeData(color: Color(0xFF2323FF)),
);
