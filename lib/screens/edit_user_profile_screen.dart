import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../firebase_options.dart';
import '../theme/theme.dart';
import '../routes/routes.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';

class EditUserProfileScreen extends StatefulWidget {
  const EditUserProfileScreen({super.key});

  @override
  State<EditUserProfileScreen> createState() => _EditUserProfileScreenState();
}

class _EditUserProfileScreenState extends State<EditUserProfileScreen> {
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  final FirebaseStorage _storage = FirebaseStorage.instance;

  File? _selectedImage;
  String? _currentProfileUrl;
  bool _isSaving = false;
  bool _showReauthCard = false;
  String _currentPassword = '';
  bool _showImageSourceCard = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = _auth.currentUser;
    if (user != null) {
      final snapshot = await _dbRef.child('users').child(user.uid).get();
      if (snapshot.exists) {
        final data = snapshot.value as Map;
        _bioController.text = data['bio'] ?? '';
        setState(() {
          _currentProfileUrl = data['profilePhotoUrl'];
        });
      }
    }
  }

  void _showImageSourcePicker() {
    setState(() {
      _showImageSourceCard = true;
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await ImagePicker().pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadProfileImage(String uid) async {
    if (_selectedImage == null) return null;

    final ref = _storage.ref().child('profile_images').child('$uid.jpg');
    await ref.putFile(_selectedImage!);
    return await ref.getDownloadURL();
  }

  Future<void> _saveChanges() async {
    final user = _auth.currentUser;
    if (user == null) {
      _showMessage('No logged-in user found.');
      setState(() => _isSaving = false);
      return;
    }

    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();
    final bio = _bioController.text.trim();

    if (newPassword.isNotEmpty || confirmPassword.isNotEmpty) {
      if (newPassword != confirmPassword) {
        _showMessage('Passwords do not match.');
        setState(() => _isSaving = false);
        return;
      }
      if (newPassword.length < 8) {
        _showMessage('Password must be at least 8 characters long.');
        setState(() => _isSaving = false);
        return;
      }

      try {
        await user.updatePassword(newPassword);
      } on FirebaseAuthException catch (e) {
        if (e.code == 'requires-recent-login') {
          setState(() {
            _showReauthCard = true;
            _isSaving = false;
          });
          return;
        } else {
          _showMessage('Password update failed: ${e.message}');
          setState(() => _isSaving = false);
          return;
        }
      }
    }

    try {
      String? profileImageUrl = await _uploadProfileImage(user.uid);
      final updates = {
        'bio': bio,
        if (profileImageUrl != null) 'profilePhotoUrl': profileImageUrl,
      };
      await _dbRef.child('users').child(user.uid).update(updates);

      _showMessage('Profile updated successfully!');
      Navigator.of(context).pop();
    } catch (e) {
      _showMessage('Error: $e');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _bioController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Widget _buildImageSourceCard() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        margin: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Choose Image Source',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Quicksand',
              ),
            ),
            const SizedBox(height: 16),

            SizedBox(
              width: 200,
              child: ElevatedButton.icon(
                icon: const Icon(CupertinoIcons.photo),
                label: const Text('Gallery'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 14,
                    fontFamily: 'Quicksand',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: () async {
                  await _pickImage(ImageSource.gallery);
                  setState(() => _showImageSourceCard = false);
                },
              ),
            ),
            const SizedBox(height: 12),

            SizedBox(
              width: 200,
              child: ElevatedButton.icon(
                icon: const Icon(CupertinoIcons.camera),
                label: const Text('Camera'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 14,
                    fontFamily: 'Quicksand',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: () async {
                  await _pickImage(ImageSource.camera);
                  setState(() => _showImageSourceCard = false);
                },
              ),
            ),
            const SizedBox(height: 12),

            SizedBox(
              width: 200,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 14,
                    fontFamily: 'Quicksand',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: () =>
                    setState(() => _showImageSourceCard = false),
                child: const Text('Cancel'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReauthCard() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        margin: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Re-authenticate',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Quicksand',
              ),
            ),
            const SizedBox(height: 12),

            const Text(
              'Please enter your current password to proceed.',
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: 'Quicksand'),
            ),
            const SizedBox(height: 16),

            TextField(
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Current Password',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) => _currentPassword = value,
            ),
            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  width: 100,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 14,
                        fontFamily: 'Quicksand',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: () {
                      setState(() {
                        _showReauthCard = false;
                        _currentPassword = '';
                      });
                    },
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 8),

                SizedBox(
                  width: 100,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 14,
                        fontFamily: 'Quicksand',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: () async {
                      final user = _auth.currentUser;
                      if (user != null && user.email != null) {
                        try {
                          final cred = EmailAuthProvider.credential(
                            email: user.email!,
                            password: _currentPassword,
                          );
                          await user.reauthenticateWithCredential(cred);
                          setState(() {
                            _showReauthCard = false;
                          });
                          await _saveChanges();
                        } catch (e) {
                          _showMessage('Re-authentication failed. Please try again.');
                        }
                      }
                    },
                    child: const Text('Confirm'),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: IconButton(
            icon: const Icon(CupertinoIcons.arrow_left, color: Colors.black),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),

                const Text(
                  'Edit Profile',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Quicksand',
                  ),
                ),
                const SizedBox(height: 12),

                const Text(
                  'Update your bio, profile picture, or change your password here.',
                  style: TextStyle(
                      fontSize: 16,
                      fontFamily: 'Quicksand'
                  ),
                ),
                const SizedBox(height: 24),

                const Text(
                  'Note: Your email and username cannot be changed once the account is registered.',
                  style: TextStyle(
                      fontSize: 16,
                      fontFamily: 'Quicksand'
                  ),
                ),
                const SizedBox(height: 24),

                Center(
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundImage: _selectedImage != null
                            ? FileImage(_selectedImage!)
                            : (_currentProfileUrl != null
                            ? NetworkImage(_currentProfileUrl!) as ImageProvider
                            : const AssetImage('assets/images/default_profile.png')),
                      ),
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.white,
                        child: IconButton(
                          icon: const Icon(CupertinoIcons.pencil, size: 24),
                          onPressed: _showImageSourcePicker,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                const Text(
                  'Bio',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Quicksand',
                  ),
                ),
                const SizedBox(height: 8),

                TextField(
                  controller: _bioController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Write something about yourself...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                const Text(
                  'New Password',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Quicksand',
                  ),
                ),
                const SizedBox(height: 8),

                TextField(
                  controller: _newPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    hintText: 'Enter new password',
                  ),
                ),
                const SizedBox(height: 20),

                const Text(
                  'Confirm New Password',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Quicksand',
                  ),
                ),
                const SizedBox(height: 8),

                TextField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    hintText: 'Confirm new password',
                  ),
                ),
                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontFamily: 'Quicksand',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: _isSaving
                        ? null
                        : () async {
                      setState(() {
                        _isSaving = true;
                      });
                      await _saveChanges();
                    },
                    child: _isSaving
                        ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                      ),
                    )
                        : const Text('Save Changes'),
                  ),
                ),
                const SizedBox(height: 16),

              ],
            ),
          ),
          if (_showReauthCard)
            Container(
              color: Colors.black.withOpacity(0.4),
              child: _buildReauthCard(),
            ),
          if (_showImageSourceCard)
            Container(
              color: Colors.black.withOpacity(0.4),
              child: _buildImageSourceCard(),
            ),
        ],
      ),
    );
  }
}