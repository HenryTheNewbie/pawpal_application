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

class SanctuaryProfileScreen extends StatefulWidget {
  const SanctuaryProfileScreen({super.key});

  @override
  State<SanctuaryProfileScreen> createState() => _SanctuaryProfileScreenState();
}

class _SanctuaryProfileScreenState extends State<SanctuaryProfileScreen> {
  bool _isLoading = false;
  String? _sanctuaryName;
  String? _description;
  String? _profilePhotoUrl;
  String? _contactPhone;
  String? _location;
  String? _website;

  int _animalCount = 0;
  int _totalLikes = 0;
  int _activeConversations = 0;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  @override
  void initState() {
    super.initState();
    _loadSanctuaryProfile();
    _loadStats();
  }

  Future<void> _loadSanctuaryProfile() async {
    final user = _auth.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      final snapshot = await _dbRef.child('sanctuaries').child(user.uid).once();
      final data = snapshot.snapshot.value as Map?;

      setState(() {
        _sanctuaryName = data?['organizationName'] ?? 'Unknown Sanctuary';
        _description = data?['description'] ?? 'No description set.';
        _profilePhotoUrl = data?['profilePhotoUrl'];
        _contactPhone = data?['contactPhone'] ?? '';
        _location = data?['location'] ?? '';
        _website = data?['website'] ?? '';
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load profile: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _navigateToEditProfile() {
    Navigator.pushNamed(context, AppRoutes.editSanctuaryProfile).then((_) {
      _loadSanctuaryProfile();
    });
  }

  Future<void> _loadStats() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final animalsSnapshot = await _dbRef.child('animals').orderByChild('uploadedBy').equalTo(user.email).once();
      final animalsData = animalsSnapshot.snapshot.value as Map?;
      final myAnimalIds = <String>[];

      if (animalsData != null) {
        myAnimalIds.addAll(animalsData.keys.map((e) => e.toString()));
      }

      setState(() {
        _animalCount = myAnimalIds.length;
      });

      int likeCount = 0;
      final swipesSnapshot = await _dbRef.child('swipes').once();
      final swipesData = swipesSnapshot.snapshot.value as Map?;

      if (swipesData != null) {
        for (final entry in swipesData.entries) {
          final animalId = entry.key.toString();
          if (myAnimalIds.contains(animalId)) {
            final swipeEntry = entry.value as Map?;
            final likes = swipeEntry?['likes'] as Map?;
            if (likes != null) {
              likeCount += likes.length;
            }
          }
        }
      }

      setState(() {
        _totalLikes = likeCount;
      });

      int activeChats = 0;
      final convSnapshot = await _dbRef.child('conversations').once();
      final convData = convSnapshot.snapshot.value as Map?;

      if (convData != null) {
        for (final conv in convData.values) {
          if (conv is Map && conv['participants'] is List) {
            final participants = List<String>.from(conv['participants']);
            if (participants.contains(user.email)) {
              activeChats++;
            }
          }
        }
      }

      setState(() {
        _activeConversations = activeChats;
      });
    } catch (e) {
      debugPrint('Error loading stats: $e');
    }
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
                Navigator.pushNamed(context, AppRoutes.sanctuarySettings);
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
                        _sanctuaryName ?? 'Loading...',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Quicksand',
                        ),
                      ),
                      const SizedBox(height: 4),

                      Text(
                        _description ?? '',
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

            if (_location != null && _location!.isNotEmpty) ...[
              Row(
                children: [
                  const Icon(
                      CupertinoIcons.placemark,
                      size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _location!,
                      style: TextStyle(
                        fontSize: 14,
                        fontFamily: 'Quicksand',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],

            if (_contactPhone != null && _contactPhone!.isNotEmpty) ...[
              Row(
                children: [
                  const Icon(
                    CupertinoIcons.phone,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _contactPhone!,
                      style: const TextStyle(
                        fontSize: 14,
                        fontFamily: 'Quicksand',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],

            if (_website != null && _website!.isNotEmpty) ...[
              Row(
                children: [
                  const Icon(
                      CupertinoIcons.globe,
                      size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _website!,
                      style: const TextStyle(
                        color: Colors.blue,
                        fontSize: 14,
                        fontFamily: 'Quicksand',
                      ),
                    ),
                  ),
                ],
              ),
            ],

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
                    : const Text('Edit Sanctuary Profile')
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                _buildStatItem(CupertinoIcons.hare, 'Animals', _animalCount.toString()),
                _verticalDivider(),
                _buildStatItem(CupertinoIcons.heart, 'Likes Received', _totalLikes.toString()),
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