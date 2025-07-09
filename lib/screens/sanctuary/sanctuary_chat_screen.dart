import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../firebase_options.dart';
import '../../theme/colors.dart';
import '../../theme/theme.dart';
import '../../routes/routes.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/cupertino.dart';
import 'package:pawpal_application/widgets/chat/sanctuary_animal_conversation_tile.dart';
import '../../models/chat_detail_arguments.dart';

class SanctuaryChatScreen extends StatefulWidget {
  const SanctuaryChatScreen({super.key});

  @override
  State<SanctuaryChatScreen> createState() => _SanctuaryChatScreenState();
}

class _SanctuaryChatScreenState extends State<SanctuaryChatScreen> {
  final _db = FirebaseDatabase.instance.ref();
  final _userEmail = FirebaseAuth.instance.currentUser?.email;

  Map<String, dynamic> _animalMap = {};
  Map<String, int> _animalRequestCount = {};
  Map<String, int> _animalConversationCount = {};

  bool _isDataLoaded = false;

  @override
  void initState() {
    super.initState();
    _preloadData();
  }

  Future<void> _preloadData() async {
    final animalSnap = await _db.child('animals').get();
    final chatRequestsSnap = await _db.child('chatRequests').get();
    final conversationsSnap = await _db.child('conversations').get();

    if (animalSnap.exists) {
      final raw = Map<String, dynamic>.from(animalSnap.value as Map);
      for (var entry in raw.entries) {
        final animal = Map<String, dynamic>.from(entry.value);
        if (animal['uploadedBy'] == _userEmail && animal['id'] != null) {
          _animalMap[animal['id']] = animal;
        }
      }
    }

    if (chatRequestsSnap.exists) {
      final raw = Map<String, dynamic>.from(chatRequestsSnap.value as Map);
      raw.forEach((animalId, requests) {
        if (_animalMap.containsKey(animalId)) {
          _animalRequestCount[animalId] = (requests as Map).length;
        }
      });
    }

    if (conversationsSnap.exists) {
      final raw = Map<String, dynamic>.from(conversationsSnap.value as Map);
      for (var entry in raw.entries) {
        final convo = Map<String, dynamic>.from(entry.value);
        final animalId = convo['animalId'];
        final participants = List<String>.from(convo['participants'] ?? []);

        if (_animalMap.containsKey(animalId) && participants.contains(_userEmail)) {
          _animalConversationCount[animalId] = (_animalConversationCount[animalId] ?? 0) + 1;
        }
      }
    }

    setState(() {
      _isDataLoaded = true;
    });
  }

  String _getAnimalName(String animalId) {
    return _animalMap[animalId]?['name'] ?? '';
  }

  String _getAnimalAge(String animalId) {
    return _animalMap[animalId]?['age']?.toString() ?? '';
  }

  String _getAnimalAgeGroup(String animalId) {
    return _animalMap[animalId]?['ageGroup'] ?? '';
  }

  String _getAnimalSpecies(String animalId) {
    return _animalMap[animalId]?['species'] ?? '';
  }

  String _getAnimalBreed(String animalId) {
    return _animalMap[animalId]?['breed'] ?? '';
  }

  String _getAnimalImageUrl(String animalId) {
    final photos = List<String>.from(_animalMap[animalId]?['photoUrls'] ?? []);
    return photos.isNotEmpty ? photos.first : '';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final filteredAnimalIds = _animalMap.keys.where((id) {
      return (_animalRequestCount[id] ?? 0) > 0 || (_animalConversationCount[id] ?? 0) > 0;
    }).toList();

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        title: const Padding(
          padding: EdgeInsets.only(left: 8.0),
          child: Text(
            'Chat',
            style: TextStyle(
              color: Colors.black,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              fontFamily: 'Quicksand',
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 4),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(1),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      offset: const Offset(0, 1),
                      blurRadius: 3,
                      spreadRadius: 0.5,
                    ),
                  ],
                ),
                child: !_isDataLoaded
                    ? const Center(child: CircularProgressIndicator())
                    : filteredAnimalIds.isEmpty
                    ? const Center(
                  child: Text(
                    'No requests or conversations yet.',
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: 'Quicksand',
                    ),
                  ),
                )
                    : ListView.builder(
                  itemCount: filteredAnimalIds.length,
                  itemBuilder: (context, index) {
                    final animalId = filteredAnimalIds[index];
                    return SanctuaryAnimalConversationTile(
                      animalName: _getAnimalName(animalId),
                      profileImageUrl: _getAnimalImageUrl(animalId),
                      age: _getAnimalAge(animalId),
                      ageGroup: _getAnimalAgeGroup(animalId),
                      species: _getAnimalSpecies(animalId),
                      breed: _getAnimalBreed(animalId),
                      activeChatCount: _animalConversationCount[animalId] ?? 0,
                      requestCount: _animalRequestCount[animalId] ?? 0,
                      onTap: () {
                        Navigator.pushNamed(
                            context,
                            AppRoutes.sanctuaryChatByAnimal,
                            arguments: {
                              'animalId': animalId,
                            }
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}