import 'package:echo/screens/home_screen.dart';
import 'package:echo/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:flutter_otp_text_field/flutter_otp_text_field.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

import '../models/user.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String phoneNumber = "";
  bool isPhoneValid = false;
  bool isCodeValid = false;
  TextEditingController phoneController = TextEditingController();
  int _resendTimer = 60;
  Timer? _timer;
  bool isLoading = false;
  bool isVerifying = false;

  String code = "";

  AuthService _authService = AuthService();

  @override
  void dispose() {
    _timer?.cancel();
    phoneController.dispose();
    super.dispose();
  }

  void startResendTimer() {
    _resendTimer = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_resendTimer > 0) {
          _resendTimer--;
        } else {
          _timer?.cancel();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: const Text(
          "Login",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        maintainBottomViewPadding: true,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Enter your phone number",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "We'll send you a verification code",
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 32),
                IntlPhoneField(
                  controller: phoneController,
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    hintText: 'Enter your phone number',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 20),
                  ),
                  initialCountryCode: 'IN',
                  onChanged: (phone) {
                    setState(() {
                      phoneNumber = phone.completeNumber;
                      isPhoneValid = phone.number.length >= 10;
                    });
                  },
                ),

                //Send OTP Button
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: (!isPhoneValid || isLoading)
                        ? null
                        : () async {
                            setState(() {
                              isLoading = true;
                            });

                            sendOtp(context, phoneNumber);
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: isLoading
                        ? SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Theme.of(context).colorScheme.onPrimary,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            "Continue",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),

                //Term and Condition button
                const SizedBox(height: 24),
                Center(
                  child: TextButton(
                    onPressed: () {
                      // Handle terms and privacy
                    },
                    child: Text(
                      "By continuing, you agree to our Terms and Privacy Policy",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.6),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> openBottomSheetForOTP(
      BuildContext context, String phoneNumber) async {
    String formattedNumber =
        phoneNumber.replaceRange(3, phoneNumber.length - 2, '•••••');
    startResendTimer();

    await showModalBottomSheet(
      elevation: 0,
      useSafeArea: true,
      context: context,
      isDismissible: true,
      enableDrag: true,
      isScrollControlled: true,
      clipBehavior: Clip.antiAlias,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(32),
        ),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: SingleChildScrollView(
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Verification",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Enter the 4-digit code sent to $formattedNumber",
                      style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: OtpTextField(
                          numberOfFields: 6,
                          borderColor: Theme.of(context).colorScheme.primary,
                          focusedBorderColor:
                              Theme.of(context).colorScheme.primary,
                          showFieldAsBox: true,
                          borderRadius: BorderRadius.circular(12),
                          fieldWidth: 40,
                          borderWidth: 2,
                          enabledBorderColor: Theme.of(context)
                              .colorScheme
                              .outline
                              .withOpacity(0.3),
                          onCodeChanged: (String code) {
                            // Handle validation here
                            setState(() {
                              isCodeValid = code.length == 6;
                            });
                          },
                          onSubmit: (String verificationCode) {
                            code = verificationCode;
                            verifyOTP(context, phoneNumber, verificationCode);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    //Resend code button
                    Center(
                      child: TextButton(
                        onPressed: _resendTimer > 0
                            ? null
                            : () {
                                startResendTimer();
                                sendOtp(context, phoneNumber);
                                setState(() {
                                  isVerifying = false;
                                });
                              },
                        child: Text(
                          _resendTimer > 0
                              ? "Resend code in $_resendTimer seconds"
                              : "Resend code",
                          style: TextStyle(
                            color: _resendTimer > 0
                                ? Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withOpacity(0.6)
                                : Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    //verify button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: (!isCodeValid)
                            ? null
                            : () async {
                                //verify
                                verifyOTP(context, phoneNumber, code);
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          foregroundColor:
                              Theme.of(context).colorScheme.onPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: isVerifying
                            ? SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  color:
                                      Theme.of(context).colorScheme.onPrimary,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                "Verify",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    //change phone number button
                    Center(
                      child: TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: Text(
                          "Change phone number",
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void sendOtp(BuildContext context, String phoneNumber) async {
    if (phoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please enter a phone number")));
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      print(phoneNumber);
      await _authService.sendOTP(phoneNumber);

      setState(() {
        isLoading = false;
      });

      //open sheet for verification
      openBottomSheetForOTP(context, phoneNumber);
    } catch (e) {
      print(e.toString());
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Failed to send OTP")));
    }
  }

  void verifyOTP(BuildContext context, String phoneNumber, String code) async {
    // Implement your OTP verification logic here
    if (code.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Please enter OTP")));
      return;
    }

    setState(() {
      isVerifying = true;
    });

    try {
      var user = await _authService.verifyOTP(phoneNumber, code,
          onVerificationFailed: (e) {
        setState(() {
          isVerifying = false;
        });
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      });

      if (user != null) {
        setState(() {
          isVerifying = false;
        });

        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Login Successful")));

        //login successful --> go to home screen
        Navigator.pop(context);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const HomeScreen(),
          ),
        );
      } else {
        setState(() {
          isVerifying = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Verification failed. Please try again.')),
        );
      }
    } catch (e) {
      setState(() {
        isVerifying = false;
      });
    }
  }
}
