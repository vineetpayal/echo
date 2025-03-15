import 'package:echo/models/user.dart';
import 'package:echo/screens/home_screen.dart';
import 'package:echo/services/auth_service.dart';
import 'package:echo/services/database_service.dart';
import 'package:echo/services/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:echo/models/user.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class AddProfileScreen extends StatefulWidget {
  const AddProfileScreen({super.key});

  @override
  State<AddProfileScreen> createState() => _AddProfileScreenState();
}

class _AddProfileScreenState extends State<AddProfileScreen> {
  bool isLoading = false;
  File? _imageFile;
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _statusController = TextEditingController();

  // Constants for validation and UI
  static const int maxDisplayNameLength = 50;
  static const int maxStatusLength = 100;

  //Services
  StorageService storageService = StorageService();
  AuthService authService = AuthService();
  DatabaseService databaseService = DatabaseService();

  @override
  void dispose() {
    _displayNameController.dispose();
    _statusController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        setState(() {
          _imageFile = File(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  Future<void> uploadUserInfo({
    Function()? onSuccess,
    Function()? onFailure,
  }) async {
    var user = await authService.getCurrentUser();
    if (user != null) {
      String userId = user.id;
      final imageUrl = await storageService.uploadImage(_imageFile!, userId);
      final displayName = _displayNameController.text;
      final status = _statusController.text;

      var newUser = User(
          uid: userId,
          phoneNumber: "+${user.phone!}",
          profileUrl: imageUrl,
          displayName: displayName,
          lastSeen: DateTime.now(),
          statusContent: status);

      databaseService.uploadUserInfo(newUser, onSuccess: (response) {
        if (onSuccess != null) {
          onSuccess();
        }
      }, onFailure: (response) {
        if (onFailure != null) onFailure();
      });
    } else {
      if (onFailure != null) onFailure();
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      setState(() => isLoading = true);

      // Upload User Info
      uploadUserInfo(onSuccess: () {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );

        Navigator.of(context)
            .push(MaterialPageRoute(builder: (context) => const HomeScreen()));

        //if failed
      }, onFailure: () {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to Register!')),
        );
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating profile: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: const Text("Add Profile"),
      ),
      body: SafeArea(
        maintainBottomViewPadding: true,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Profile image picker
                GestureDetector(
                  onTap: _pickImage,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 62,
                        backgroundImage: _imageFile != null
                            ? FileImage(_imageFile!) as ImageProvider
                            : const AssetImage('assets/images/profile.png'),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.camera_alt,
                            size: 20,
                            color: theme.colorScheme.onPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 56),

                TextFormField(
                  controller: _displayNameController,
                  decoration: InputDecoration(
                    labelText: "Display Name",
                    hintText: "Enter your name",
                    counterText:
                        "${_displayNameController.text.length}/$maxDisplayNameLength",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ),
                  maxLength: maxDisplayNameLength,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Display name is required';
                    }
                    if (value.length < 2) {
                      return 'Display name must be at least 2 characters';
                    }
                    return null;
                  },
                  onChanged: (value) => setState(() {}),
                ),

                const SizedBox(height: 8),

                TextFormField(
                  controller: _statusController,
                  decoration: InputDecoration(
                    labelText: "Status (Optional)",
                    hintText: "Enter your status",
                    counterText:
                        "${_statusController.text.length}/$maxStatusLength",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ),
                  maxLength: maxStatusLength,
                  maxLines: 2,
                ),

                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _displayNameController.text.isEmpty
                        ? null
                        : _submitForm,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
