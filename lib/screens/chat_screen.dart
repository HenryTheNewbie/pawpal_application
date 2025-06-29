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
import 'package:pawpal_application/widgets/chat/conversation_tile.dart';
import '../models/chat_detail_arguments.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _db = FirebaseDatabase.instance.ref();
  final _userEmail = FirebaseAuth.instance.currentUser?.email;

  Map<String, dynamic> _animalMap = {};
  Map<String, dynamic> _sanctuaryMap = {};
  Map<String, String> _sanctuaryImageMap = {};

  bool _isDataLoaded = false;

  @override
  void initState() {
    super.initState();
    _preloadData();
  }

  Future<void> _preloadData() async {
    final animalSnap = await _db.child('animals').get();
    final sanctuarySnap = await _db.child('sanctuaries').get();

    if (animalSnap.exists) {
      final raw = Map<String, dynamic>.from(animalSnap.value as Map);
      for (var entry in raw.entries) {
        final animal = Map<String, dynamic>.from(entry.value);
        final id = animal['id'];
        if (id != null) {
          _animalMap[id] = animal;
        }
      }
    }

    if (sanctuarySnap.exists) {
      final raw = Map<String, dynamic>.from(sanctuarySnap.value as Map);
      for (var entry in raw.entries) {
        final value = Map<String, dynamic>.from(entry.value);
        final email = value['email'];
        final orgName = value['organizationName'];
        final photoUrl = value['profilePhotoUrl'];

        if (email != null) {
          _sanctuaryMap[email] = orgName ?? 'Unknown Sanctuary';
          if (photoUrl != null) {
            _sanctuaryImageMap[email] = photoUrl;
          }
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

  String _getAnimalDescription(String animalId) {
    return _animalMap[animalId]?['description'] ?? '';
  }

  String _getSanctuaryNameForAnimal(String animalId) {
    final uploader = _animalMap[animalId]?['uploadedBy'];
    return _sanctuaryMap[uploader] ?? 'Unknown Sanctuary';
  }

  String _getSanctuaryEmailForAnimal(String animalId) {
    return _animalMap[animalId]?['uploadedBy'] ?? 'Unknown Email';
  }

  String _getSanctuaryImageUrlForAnimal(String animalId) {
    final uploaderEmail = _animalMap[animalId]?['uploadedBy'];
    return _sanctuaryImageMap[uploaderEmail] ?? '';
  }

  String _getAnimalImageUrl(String animalId) {
    final photos = List<String>.from(_animalMap[animalId]?['photoUrls'] ?? []);
    return photos.isNotEmpty ? photos.first : '';
  }

  String _formatTimestamp(dynamic raw) {
    DateTime? dateTime;
    if (raw is int) {
      dateTime = DateTime.fromMillisecondsSinceEpoch(raw);
    } else if (raw is String) {
      dateTime = DateTime.tryParse(raw);
    }
    if (dateTime == null) return '';

    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) return 'Now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${dateTime.day}/${dateTime.month}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final statusBarHeight = MediaQuery.of(context).padding.top;

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
                    ? const Center(
                  child: CircularProgressIndicator(),
                )
                    : StreamBuilder<DatabaseEvent>(
                  stream: FirebaseDatabase.instance.ref('conversations').onValue,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
                      return const Center(
                        child: Text(
                          'No conversations yet.',
                          style: TextStyle(
                            fontSize: 16,
                            fontFamily: 'Quicksand',
                          ),
                        ),
                      );
                    }

                    final data = Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);
                    final conversations = data.entries.where((entry) {
                      final participants = List<String>.from(entry.value['participants'] ?? []);
                      return participants.contains(_userEmail);
                    }).toList();

                    if (conversations.isEmpty) {
                      return const Center(
                        child: Text(
                          'No conversations yet.',
                          style: TextStyle(
                            fontSize: 16,
                            fontFamily: 'Quicksand',
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: conversations.length,
                      itemBuilder: (context, index) {
                        final entry = conversations[index];
                        final conversationId = entry.key;
                        final convo = entry.value;

                        final animalId = convo['animalId'] ?? '';
                        final animalName = _getAnimalName(animalId);
                        final animalDescription = _getAnimalDescription(animalId);

                        final lastMessage = convo['lastMessage'] ?? '';
                        final lastMessageType = convo['lastMessageType'] ?? 'text';
                        final timestamp = convo['lastTimestamp'] ?? '';

                        final lastSender = convo['lastSender'] ?? '';
                        final seenBy = Map<String, dynamic>.from(convo['seenBy'] ?? {});

                        final normalizedUserEmail = _userEmail?.trim().toLowerCase();

                        final normalizedSenderEmail = (lastSender ?? '').toString().trim().toLowerCase();
                        final isMyMessage = normalizedSenderEmail.isNotEmpty &&
                            normalizedSenderEmail == normalizedUserEmail;

                        DateTime? lastMsgTime;
                        if (timestamp is int) {
                          lastMsgTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
                        } else if (timestamp is String) {
                          lastMsgTime = DateTime.tryParse(timestamp);
                        }

                        DateTime? userReadTime;
                        if (seenBy[_userEmail] is String) {
                          userReadTime = DateTime.tryParse(seenBy[_userEmail]);
                        }

                        final isUnread = !isMyMessage &&
                            lastMsgTime != null &&
                            (userReadTime == null || lastMsgTime.isAfter(userReadTime));

                        final sanctuaryName = _getSanctuaryNameForAnimal(animalId);
                        final sanctuaryEmail = _getSanctuaryEmailForAnimal(animalId);
                        final sanctuaryImageUrl = _getSanctuaryImageUrlForAnimal(animalId);

                        final animalImageUrl = _getAnimalImageUrl(animalId);

                        return ChatTile(
                          animalName: animalName,
                          sanctuaryName: sanctuaryName,
                          profileImageUrl: animalImageUrl,
                          lastMessage: lastMessage,
                          lastMessageType: lastMessageType,
                          timestamp: _formatTimestamp(timestamp),
                          isUnread: isUnread,
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              AppRoutes.chatDetail,
                              arguments: ChatDetailArguments(
                                conversationId: conversationId,
                                animalId: animalId,
                                animalName: animalName,
                                animalDescription: animalDescription,
                                sanctuaryName: sanctuaryName,
                                sanctuaryEmail: sanctuaryEmail,
                                sanctuaryImageUrl: sanctuaryImageUrl,
                                profileImageUrl: animalImageUrl,
                              ),
                            );
                          },
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