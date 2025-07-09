import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../firebase_options.dart';
import '../../theme/colors.dart';
import '../../theme/theme.dart';
import '../../routes/routes.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/cupertino.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  bool _isLoading = false;
  String? _username;
  String? _bio;
  String? _profilePhotoUrl;

  int _likeCount = 0;
  int _dislikeCount = 0;
  int _activeConversations = 0;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadStats();
  }

  Future<void> _loadUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      final snapshot = await _dbRef.child('users').child(user.uid).once();
      final data = snapshot.snapshot.value as Map?;

      setState(() {
        _username = data?['username'] ?? 'Unknown';
        _bio = data?['bio'] ?? 'No bio set.';
        _profilePhotoUrl = data?['profilePhotoUrl'];
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load profile: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadStats() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final email = user.email;
    if (email == null) return;

    try {
      int likes = 0;
      int dislikes = 0;

      final swipesSnapshot = await _dbRef.child('swipes').once();
      final swipesData = swipesSnapshot.snapshot.value as Map?;

      if (swipesData != null) {
        for (final animalEntry in swipesData.entries) {
          final data = animalEntry.value as Map?;

          final likeMap = data?['likes'] as Map?;
          final dislikeMap = data?['dislikes'] as Map?;

          if (likeMap != null) {
            for (final entry in likeMap.entries) {
              if (entry.key.toString().replaceAll(',', '.') == email) {
                likes++;
                break;
              }
            }
          }

          if (dislikeMap != null) {
            for (final entry in dislikeMap.entries) {
              if (entry.key.toString().replaceAll(',', '.') == email) {
                dislikes++;
                break;
              }
            }
          }
        }
      }

      int active = 0;
      final convSnapshot = await _dbRef.child('conversations').once();
      final convData = convSnapshot.snapshot.value as Map?;

      if (convData != null) {
        for (final conv in convData.values) {
          if (conv is Map && conv['participants'] is List) {
            final participants = List<String>.from(conv['participants']);
            if (participants.contains(email)) {
              active++;
            }
          }
        }
      }

      setState(() {
        _likeCount = likes;
        _dislikeCount = dislikes;
        _activeConversations = active;
      });
    } catch (e) {
      debugPrint('Error loading stats: $e');
    }
  }

  void _navigateToEditProfile() {
    Navigator.pushNamed(context, AppRoutes.editUserProfile).then((_) {
      _loadUserProfile();
    });
  }

  Widget _buildStatItem(IconData icon, String label, String count) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 28, color: Colors.black),
            const SizedBox(height: 8),
            Text(
              count,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Quicksand',
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
                fontFamily: 'Quicksand',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _verticalDivider() {
    return Container(
      width: 1,
      height: 80,
      color: AppColors.textSecondary.withOpacity(0.5),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
              iconSize: 30,
              icon: const Icon(CupertinoIcons.gear_alt, color: Colors.black),
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.userSettings);
              },
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 45,
                  backgroundImage: _profilePhotoUrl != null
                      ? NetworkImage(_profilePhotoUrl!)
                      : const AssetImage('assets/images/default_profile.png') as ImageProvider,
                ),
                const SizedBox(width: 16),

                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _username ?? 'Loading...',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Quicksand',
                        ),
                      ),
                      const SizedBox(height: 4),

                      Text(
                        _bio ?? '',
                        style: const TextStyle(
                          fontSize: 16,
                          fontFamily: 'Quicksand',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

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
                onPressed: _isLoading ? null : _navigateToEditProfile,
                child: _isLoading
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                  ),
                )
                    : const Text('Edit Profile'),
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                _buildStatItem(CupertinoIcons.heart_slash, 'Dislikes', _dislikeCount.toString()),
                _verticalDivider(),
                _buildStatItem(CupertinoIcons.heart, 'Likes', _likeCount.toString()),
                _verticalDivider(),
                _buildStatItem(CupertinoIcons.chat_bubble, 'Conversations', _activeConversations.toString()),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}