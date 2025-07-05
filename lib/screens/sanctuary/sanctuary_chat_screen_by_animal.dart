import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../firebase_options.dart';
import '../../models/sanctuary_chat_detail_arguments.dart';
import '../../theme/colors.dart';
import '../../theme/theme.dart';
import '../../routes/routes.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/cupertino.dart';
import 'package:pawpal_application/widgets/chat/sanctuary_request_tile.dart';
import 'package:pawpal_application/widgets/chat/sanctuary_conversation_tile.dart';
import '../../models/chat_detail_arguments.dart';

class SanctuaryChatScreenByAnimal extends StatefulWidget {
  final String animalId;

  const SanctuaryChatScreenByAnimal({super.key, required this.animalId});

  @override
  State<SanctuaryChatScreenByAnimal> createState() => _SanctuaryChatScreenByAnimalState();
}

class _SanctuaryChatScreenByAnimalState extends State<SanctuaryChatScreenByAnimal> {
  final _db = FirebaseDatabase.instance.ref();
  final _userEmail = FirebaseAuth.instance.currentUser?.email;

  int _selectedTabIndex = 0;

  Map<String, dynamic> _animalMap = {};
  Map<String, dynamic> _sanctuaryMap = {};
  Map<String, String> _sanctuaryImageMap = {};

  Map<String, Map<String, dynamic>> _userMapByEmail = {};

  List<Map<String, dynamic>> _conversationList = [];
  List<Map<String, dynamic>> _requestList = [];

  bool _isDataLoaded = false;

  bool _showOverlay = false;
  Widget? _overlayContent;
  Map<String, dynamic>? _selectedRequest;

  bool _showAcceptCard = false;
  bool _showDeclineCard = false;

  @override
  void initState() {
    super.initState();
    _preloadData();
  }

  Future<void> _preloadData() async {
    final animalSnap = await _db.child('animals').get();
    final sanctuarySnap = await _db.child('sanctuaries').get();
    final usersSnap = await _db.child('users').get();

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

    if (usersSnap.exists) {
      final raw = Map<String, dynamic>.from(usersSnap.value as Map);
      for (var entry in raw.entries) {
        final user = Map<String, dynamic>.from(entry.value);
        final email = user['email'];
        if (email != null) {
          _userMapByEmail[email] = user;
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

  String _getAnimalImageUrl(String animalId) {
    final photos = List<String>.from(_animalMap[animalId]?['photoUrls'] ?? []);
    return photos.isNotEmpty ? photos.first : '';
  }

  String _getUserName(String email) {
    return _userMapByEmail[email]?['username'] ?? 'Unknown User';
  }

  String _getUserBio(String email) {
    return _userMapByEmail[email]?['bio'] ?? '';
  }

  String _getUserImageUrl(String email) {
    return _userMapByEmail[email]?['profilePhotoUrl'] ?? '';
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

  Future<void> _acceptRequest(Map<String, dynamic> request) async {
    final animalId = request['animalId'];
    final requesterEmail = request['requesterEmail'];
    final convoKey = request['key'];
    if (animalId == null || requesterEmail == null || convoKey == null) return;

    final animal = _animalMap[animalId] ?? {};

    final conversationData = {
      'animalId': animalId,
      'animalName': animal['name'] ?? '',
      'lastMessage': 'Conversation started.',
      'lastMessageType': 'text',
      'lastSender': _userEmail,
      'lastTimestamp': DateTime.now().toIso8601String(),
      'participants': [requesterEmail, _userEmail],
      'messages': {
        '0': {
          'sender': _userEmail,
          'text': 'Conversation started.',
          'timestamp': DateTime.now().toIso8601String(),
          'type': 'text',
        },
      },
      'readStatus': {
        '${requesterEmail.replaceAll('.', '_')}': '',
        '${_userEmail?.replaceAll('.', '_')}': '',
      },
    };

    try {
      await _db.child('conversations').push().set(conversationData);
      await _db.child('chatRequests/$convoKey').remove();
    } catch (e) {
      debugPrint('Failed to accept request: $e');
    }
  }

  Future<void> _rejectRequest(Map<String, dynamic> request) async {
    final convoKey = request['key'];
    if (convoKey == null) return;

    try {
      await _db.child('chatRequests/$convoKey').remove();
    } catch (e) {
      debugPrint('Failed to decline request: $e');
    }
  }

  Widget _buildTabButton(String title, int index) {
    final isSelected = _selectedTabIndex == index;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          setState(() {
            _selectedTabIndex = index;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? AppColors.primary : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontFamily: 'Quicksand',
              color: isSelected ? AppColors.primary : AppColors.textPrimary,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRequestsView() {
    return StreamBuilder<DatabaseEvent>(
      stream: _db.child('chatRequests/${widget.animalId}').onValue,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
          return const Center(
            child: Text(
              'No requests yet.',
              style: TextStyle(fontSize: 16, fontFamily: 'Quicksand'),
            ),
          );
        }

        final rawData = Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);

        final requestList = rawData.entries.map((entry) {
          final request = Map<String, dynamic>.from(entry.value);
          request['key'] = entry.key;
          return request;
        }).toList();

        if (requestList.isEmpty) {
          return const Center(
            child: Text(
              'No requests yet.',
              style: TextStyle(fontSize: 16, fontFamily: 'Quicksand'),
            ),
          );
        }

        return ListView.builder(
          itemCount: requestList.length,
          itemBuilder: (context, index) {
            final req = requestList[index];
            final adopterEmail = req['adopterEmail'] ?? 'Unknown';

            final userData = _userMapByEmail[adopterEmail] ?? {};
            final username = userData['username'] ?? adopterEmail;
            final bio = userData['bio'] ?? '';
            final profileImageUrl = userData['profilePhotoUrl'] ?? '';

            return SanctuaryRequestTile(
              username: username,
              bio: bio,
              profileImageUrl: profileImageUrl,
              requestTime: _formatDate(req['requestedAt']),
              onAccept: () {
                setState(() {
                  _selectedRequest = req;
                  _showAcceptCard = true;
                });
              },
              onReject: () {
                setState(() {
                  _selectedRequest = req;
                  _showDeclineCard = true;
                });
              },
            );
          },
        );
      },
    );
  }

  Widget _buildAcceptRequestCard(VoidCallback onConfirm, VoidCallback onCancel) {
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
              'Accept Request',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
                decoration: TextDecoration.none,
                fontFamily: 'Quicksand',
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Are you sure you want to accept this request?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.normal,
                color: AppColors.textPrimary,
                decoration: TextDecoration.none,
                fontFamily: 'Quicksand',
              ),
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
                    onPressed: onCancel,
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 8),

                SizedBox(
                  width: 100,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4DED88),
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
                    onPressed: onConfirm,
                    child: const Text('Accept'),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildDeclineRequestCard(VoidCallback onConfirm, VoidCallback onCancel) {
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
              'Decline Request',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
                decoration: TextDecoration.none,
                fontFamily: 'Quicksand',
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Are you sure you want to decline this request?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.normal,
                color: AppColors.textPrimary,
                decoration: TextDecoration.none,
                fontFamily: 'Quicksand',
              ),
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
                    onPressed: onCancel,
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 8),

                SizedBox(
                  width: 100,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFFF4D4D),
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
                    onPressed: onConfirm,
                    child: const Text('Decline'),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildConversationsView() {
    return StreamBuilder<DatabaseEvent>(
      stream: FirebaseDatabase.instance.ref('conversations').onValue,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
          return const Center(
            child: Text(
              'No conversations yet.',
              style: TextStyle(fontSize: 16, fontFamily: 'Quicksand'),
            ),
          );
        }

        final rawData = Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);

        final conversations = rawData.entries.where((entry) {
          final convo = Map<String, dynamic>.from(entry.value);
          return convo['animalId'] == widget.animalId;
        }).toList();

        if (conversations.isEmpty) {
          return const Center(child: Text('No chats for this animal.'));
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
            final readStatus = Map<String, dynamic>.from(convo['readStatus'] ?? {});

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
            final readKey = _userEmail?.replaceAll('.', '_') ?? '';
            if (readStatus[readKey] is String) {
              userReadTime = DateTime.tryParse(readStatus[readKey]);
            }

            final isUnread = !isMyMessage &&
                lastMsgTime != null &&
                (userReadTime == null || lastMsgTime.isAfter(userReadTime));

            final participants = List<String>.from(convo['participants'] ?? []);
            final otherEmail = participants.firstWhere(
                  (email) => email.trim().toLowerCase() != normalizedUserEmail,
              orElse: () => '',
            );

            final username = _getUserName(otherEmail);
            final bio = _getUserBio(otherEmail);
            final userImageUrl = _getUserImageUrl(otherEmail);

            final animalImageUrl = _getAnimalImageUrl(animalId);

            return SanctuaryChatTile(
              username: username,
              bio: bio,
              profileImageUrl: userImageUrl,
              lastMessage: lastMessage,
              lastMessageType: lastMessageType,
              timestamp: _formatTimestamp(timestamp),
              isUnread: isUnread,
              onTap: () {
                Navigator.pushNamed(
                  context,
                  AppRoutes.sanctuaryChatDetail,
                  arguments: SanctuaryChatDetailArguments(
                    conversationId: conversationId,
                    animalId: animalId,
                    animalName: animalName,
                    animalDescription: animalDescription,
                    username: username,
                    email: otherEmail,
                    userImageUrl: userImageUrl,
                    profileImageUrl: animalImageUrl,
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final statusBarHeight = MediaQuery.of(context).padding.top;

    return Stack(
      children: [
        Scaffold(
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
            title: Padding(
              padding: const EdgeInsets.only(left: 4.0),
              child: Text(
                _getAnimalName(widget.animalId),
                style: const TextStyle(
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
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      offset: const Offset(0, 3),
                      blurRadius: 6,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: SafeArea(
                  bottom: false,
                  child: Row(
                    children: [
                      _buildTabButton('Requests', 0),
                      _buildTabButton('Conversations', 1),
                    ],
                  ),
                ),
              ),

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
                        : _selectedTabIndex == 0
                        ? _buildRequestsView()
                        : _buildConversationsView(),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_showAcceptCard)
          _buildAcceptRequestCard(
                () {
              _acceptRequest(_selectedRequest!);
              setState(() => _showAcceptCard = false);
            },
                () {
              setState(() => _showAcceptCard = false);
            },
          ),

        if (_showDeclineCard)
          _buildDeclineRequestCard(
                () {
              _rejectRequest(_selectedRequest!);
              setState(() => _showDeclineCard = false);
            },
                () {
              setState(() => _showDeclineCard = false);
            },
          ),

        if (_showOverlay)
          Container(
            color: Colors.black.withOpacity(0.4),
            alignment: Alignment.center,
            child: _overlayContent,
          ),
      ],
    );
  }
}