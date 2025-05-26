import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../firebase_options.dart';
import '../theme/theme.dart';
import '../routes/routes.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/cupertino.dart';

class UserSettingsScreen extends StatefulWidget {
  const UserSettingsScreen({super.key});

  @override
  State<UserSettingsScreen> createState() => _UserSettingsScreenState();
}

class _UserSettingsScreenState extends State<UserSettingsScreen> {
  bool _isLoading = false;
  bool _showLogoutCard = false;
  bool _showDeleteAccountCard = false;
  String _deleteConfirmText = '';
  String _username = '';

  @override
  void initState() {
    super.initState();
    _loadUsername();
  }

  void _loadUsername() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final snapshot = await FirebaseDatabase.instance
          .ref()
          .child('users')
          .child(user.uid)
          .get();
      final data = snapshot.value as Map?;
      if (data != null && data['username'] != null) {
        setState(() {
          _username = data['username'];
        });
      }
    }
  }

  void _handleLogout() async {
    setState(() => _isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('isLoggedIn');

    await FirebaseAuth.instance.signOut();

    setState(() => _isLoading = false);

    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  Future<void> _deleteAccount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseDatabase.instance.ref('users/${user.uid}').remove();
        await user.delete();
        Navigator.pushNamedAndRemoveUntil(context, '/register', (route) => false);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting account: $e')),
        );
      }
    }
  }

  Widget _buildSettingsButton(String label, VoidCallback onPressed) {
    return SizedBox(
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
        onPressed: _isLoading ? null : onPressed,
        child: _isLoading
            ? const SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
          ),
        )
            : Text(label),
      ),
    );
  }

  Widget _buildLogoutCard() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        margin: const EdgeInsets.symmetric(horizontal: 48),
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
              'Log Out',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Quicksand',
              ),
            ),
            const SizedBox(height: 12),

            const Text(
              'Are you sure you want to log out?',
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: 'Quicksand'),
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
                        _showLogoutCard = false;
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
                    onPressed: _handleLogout,
                    child: const Text('Log Out'),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildDeleteAccountCard(String username) {
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
              'Delete Account',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Quicksand',
              ),
            ),
            const SizedBox(height: 12),

            const Text(
              'To confirm deletion, type your username preceded by @ (e.g., @Henry). This action cannot be undone.',
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: 'Quicksand'),
            ),
            const SizedBox(height: 16),

            TextField(
              decoration: InputDecoration(
                labelText: 'Type @${username}',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _deleteConfirmText = value;
                });
              },
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
                        _showDeleteAccountCard = false;
                        _deleteConfirmText = '';
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
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
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
                    onPressed: _deleteConfirmText == '@$username'
                        ? () async {
                      await _deleteAccount();
                    }
                        : null,
                    child: const Text('Delete'),
                  ),
                ),
              ],
            ),
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
            onPressed: () => Navigator.of(context).pop(),
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
                  'Settings',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Quicksand',
                  ),
                ),
                const SizedBox(height: 12),

                const Text(
                  'Manage your preferences and account here.',
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'Quicksand',
                  ),
                ),
                const SizedBox(height: 24),

                _buildSettingsButton('Notifications', () {
                  Navigator.pushNamed(context, AppRoutes.userNotifications);
                }),
                const SizedBox(height: 16),

                _buildSettingsButton('FAQ', () {
                  Navigator.pushNamed(context, AppRoutes.userFaq);
                }),
                const SizedBox(height: 16),

                _buildSettingsButton('Privacy Policy', () {
                  Navigator.pushNamed(context, AppRoutes.userPrivacyPolicy);
                }),
                const SizedBox(height: 16),

                _buildSettingsButton('Terms of Use', () {
                  Navigator.pushNamed(context, AppRoutes.userTerms);
                }),
                const SizedBox(height: 16),

                _buildSettingsButton('About the App', () {
                  Navigator.pushNamed(context, AppRoutes.aboutTheApp);
                }),
                const SizedBox(height: 16),

                _buildSettingsButton('Log Out', () {
                  setState(() {
                    _showLogoutCard = true;
                  });
                }),
                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
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
                    onPressed: () {
                      setState(() {
                        _showDeleteAccountCard = true;
                      });
                    },
                    child: const Text('Delete Account'),
                  ),
                ),
              ],
            ),
          ),
          if (_showLogoutCard)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: _buildLogoutCard(),
            ),
          if (_showDeleteAccountCard)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: _buildDeleteAccountCard(_username),
            ),
        ],
      ),
    );
  }
}