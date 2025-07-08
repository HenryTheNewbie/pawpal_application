import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../firebase_options.dart';
import '../../theme/theme.dart';
import '../../routes/routes.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/cupertino.dart';
import '../../widgets/animal_management/animal_tile.dart';

class SanctuaryAnimalManagementScreen extends StatefulWidget {
  const SanctuaryAnimalManagementScreen({super.key});

  @override
  State<SanctuaryAnimalManagementScreen> createState() => _SanctuaryAnimalManagementScreenState();
}

class _SanctuaryAnimalManagementScreenState extends State<SanctuaryAnimalManagementScreen> {
  final _db = FirebaseDatabase.instance.ref();
  final _auth = FirebaseAuth.instance;
  List<Map<String, dynamic>> _animals = [];
  bool _isLoading = true;
  String _userEmail = '';

  @override
  void initState() {
    super.initState();
    _preloadData();
  }

  Future<void> _preloadData() async {
    final user = _auth.currentUser;
    if (user == null) return;

    _userEmail = user.email ?? '';
    final animalSnap = await _db.child('animals').get();

    if (animalSnap.exists) {
      final raw = Map<String, dynamic>.from(animalSnap.value as Map);
      final List<Map<String, dynamic>> loadedAnimals = [];

      for (var entry in raw.entries) {
        final animal = Map<String, dynamic>.from(entry.value);
        if (animal['uploadedBy'] == _userEmail && animal['id'] != null) {
          loadedAnimals.add(animal);
        }
      }

      setState(() {
        _animals = loadedAnimals;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return '';
    DateTime date;
    if (timestamp is int) {
      date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    } else if (timestamp is String) {
      date = DateTime.tryParse(timestamp) ?? DateTime.now();
    } else {
      return '';
    }
    return '${date.month}/${date.day}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
              iconSize: 30,
              icon: const Icon(CupertinoIcons.add, color: Colors.black),
              onPressed: () async {
                final result = await Navigator.pushNamed(
                  context,
                  AppRoutes.sanctuaryAddAnimal,
                );
                if (result == true) {
                  await _preloadData();
                }
              },
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _animals.isEmpty
          ? const Center(
        child: Text(
          'No animals added yet.',
          style: TextStyle(
            fontSize: 16,
            fontFamily: 'Quicksand',
          ),
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 12),
        itemCount: _animals.length,
        itemBuilder: (context, index) {
          final animal = _animals[index];
          return AnimalTile(
            animalName: animal['name'] ?? 'Unnamed',
            profileImageUrl: animal['photoUrls'] != null &&
                animal['photoUrls'] is List &&
                (animal['photoUrls'] as List).isNotEmpty
                ? animal['photoUrls'][0]
                : '',
            species: animal['species'] ?? '',
            breed: animal['breed'] ?? '',
            description: animal['description'] ?? '',
            dateAdded: _formatDate(animal['createdAt']),
            adoptionStatus: animal['adoptionStatus'] ?? 'Available',
            onTap: () async {
              final result = await Navigator.pushNamed(
                context,
                AppRoutes.sanctuaryEditAnimal,
                arguments: {
                  'animalId': animal['id'],
                },
              );
              if (result == true) {
                await _preloadData();
              }
            },
          );
        },
      ),
    );
  }
}