import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../firebase_options.dart';
import '../../theme/colors.dart';
import '../theme/theme.dart';
import '../routes/routes.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/cupertino.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';
// import 'package:file_picker/file_picker.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:intl/intl.dart';

class ChatDetailScreen extends StatefulWidget {
  final String conversationId;
  final String animalId;
  final String animalName;
  final String animalDescription;
  final String sanctuaryName;
  final String sanctuaryEmail;
  final String sanctuaryImageUrl;
  final String profileImageUrl;

  const ChatDetailScreen({
    super.key,
    required this.conversationId,
    required this.animalId,
    required this.animalName,
    required this.animalDescription,
    required this.sanctuaryName,
    required this.sanctuaryEmail,
    required this.sanctuaryImageUrl,
    required this.profileImageUrl,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _userEmail = FirebaseAuth.instance.currentUser?.email;
  late final DatabaseReference _messagesRef;
  bool _showAttachmentOptionsCard = false;

  final List<File> _selectedAttachments = [];
  bool _isSending = false;

  String? _lastReadTimestamp;
  bool _hasScrolled = false;

  bool unreadMarkerInserted = false;

  String? _otherUserReadTimestamp;

  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _messagesRef = FirebaseDatabase.instance
        .ref('conversations/${widget.conversationId}/messages');

    final safeEmail = _userEmail!.replaceAll('.', '_');

    FirebaseDatabase.instance
        .ref('conversations/${widget.conversationId}/readStatus')
        .onValue
        .listen((event) {
      final data = event.snapshot.value;
      if (data is Map) {
        final readMap = Map<String, dynamic>.from(data);
        for (final entry in readMap.entries) {
          if (entry.key != safeEmail) {
            setState(() {
              _otherUserReadTimestamp = entry.value.toString();
            });
          }
        }
      }
    });
  }

  Widget _buildCardSection({required String title, required Widget child}) {
    return SizedBox(
      width: double.infinity,
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontFamily: 'Quicksand',
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              child,
            ],
          ),
        ),
      ),
    );
  }

  Widget? _infoRow(String label, dynamic value) {
    if (value == null || (value is String && value.isEmpty)) return null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value.toString())),
        ],
      ),
    );
  }

  String formatFullTimestamp(DateTime timestamp) {
    return DateFormat('EEE, MMM d, h:mm a').format(timestamp);
  }

  String formatTimeOnly(DateTime timestamp) {
    return DateFormat('h:mm a').format(timestamp);
  }

  InlineSpan formatTimestampLabel(DateTime timestamp) {
    final now = DateTime.now();
    final date = DateTime(timestamp.year, timestamp.month, timestamp.day);
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final timeString = formatTimeOnly(timestamp);

    const TextStyle defaultStyle = TextStyle(
      fontSize: 14,
      fontFamily: 'Quicksand',
      color: Colors.grey,
    );

    const TextStyle boldStyle = TextStyle(
      fontSize: 14,
      fontFamily: 'Quicksand',
      fontWeight: FontWeight.bold,
      color: Colors.grey,
    );

    if (date == today) {
      return TextSpan(
        text: timeString,
        style: defaultStyle,
      );
    } else if (date == yesterday) {
      return TextSpan(
        style: defaultStyle,
        children: [
          TextSpan(text: 'Yesterday ', style: boldStyle),
          TextSpan(text: timeString),
        ],
      );
    } else if (now.difference(date).inDays < 7) {
      final weekday = DateFormat('EEEE').format(timestamp);
      return TextSpan(
        style: defaultStyle,
        children: [
          TextSpan(text: '$weekday ', style: boldStyle),
          TextSpan(text: timeString),
        ],
      );
    } else {
      final fullDate = DateFormat('EEE, MMM d, ').format(timestamp);
      return TextSpan(
        style: defaultStyle,
        children: [
          TextSpan(text: fullDate, style: boldStyle),
          TextSpan(text: timeString),
        ],
      );
    }
  }

  bool shouldShowTimestamp(DateTime current, DateTime? previous) {
    if (previous == null) return true;
    return current.difference(previous).inMinutes > 15 || !isSameDay(current, previous);
  }

  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
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

  void _showSanctuaryInfoSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.93,
          minChildSize: 0.60,
          maxChildSize: 0.93,
          builder: (context, scrollController) {
            return FutureBuilder<DatabaseEvent>(
              future: FirebaseDatabase.instance
                  .ref('sanctuaries')
                  .orderByChild('email')
                  .equalTo(widget.sanctuaryEmail)
                  .once(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
                  return const Center(child: CircularProgressIndicator());
                }

                final value = (snapshot.data!.snapshot.value as Map).values.first;
                final data = Map<String, dynamic>.from(value);

                return SingleChildScrollView(
                  controller: scrollController,
                  child: Padding(
                    padding: EdgeInsets.only(
                      top: 16,
                      left: 16,
                      right: 16,
                      bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 50,
                          height: 5,
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton(
                            icon: const Icon(CupertinoIcons.arrow_left, color: Colors.black),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ),
                        const SizedBox(height: 4),

                        GestureDetector(
                          onTap: () {
                            showDialog(
                              context: context,
                              barrierColor: Colors.black.withOpacity(0.9),
                              builder: (_) => Dialog(
                                backgroundColor: Colors.transparent,
                                insetPadding: EdgeInsets.zero,
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () => Navigator.of(context).pop(),
                                  child: Stack(
                                    children: [
                                      Center(
                                        child: InteractiveViewer(
                                          child: Image.network(
                                            widget.sanctuaryImageUrl,
                                            fit: BoxFit.contain,
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        top: MediaQuery.of(context).padding.top + 12,
                                        left: 12,
                                        child: IconButton(
                                          icon: const Icon(CupertinoIcons.arrow_left, color: Colors.white),
                                          onPressed: () => Navigator.of(context).pop(),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                          child: CircleAvatar(
                            backgroundImage: NetworkImage(widget.sanctuaryImageUrl),
                            radius: 64,
                          ),
                        ),
                        const SizedBox(height: 20),

                        Text(
                          data['organizationName'] ?? 'Sanctuary',
                          style: const TextStyle(
                            fontSize: 20,
                            fontFamily: 'Quicksand',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),

                        if (data['email'] != null)
                          Text(
                            data['email'],
                            style: const TextStyle(
                              fontSize: 16,
                              fontFamily: 'Quicksand',
                            ),
                          ),
                        const SizedBox(height: 8),

                        if (data['contactPhone'] != null)
                          Text(
                            data['contactPhone'],
                            style: const TextStyle(
                              fontSize: 16,
                              fontFamily: 'Quicksand',
                            ),
                          ),
                        const SizedBox(height: 16),

                        if (data['description'] != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Text(
                              data['description'],
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 14,
                                fontFamily: 'Quicksand',
                              ),
                            ),
                          ),

                        if (data['location'] != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  CupertinoIcons.placemark,
                                  size: 18,
                                ),
                                const SizedBox(width: 6),

                                Text(
                                  data['location'],
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontFamily: 'Quicksand',
                                  ),
                                ),
                              ],
                            ),
                          ),

                        if (data['website'] != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  CupertinoIcons.globe,
                                  size: 18,
                                ),
                                const SizedBox(width: 6),

                                GestureDetector(
                                  onTap: () async {
                                    final url = Uri.parse(data['website']);
                                    // if (await canLaunchUrl(url)) {
                                    //   await launchUrl(url);
                                    // }
                                  },
                                  child: Text(
                                    data['website'],
                                    style: const TextStyle(
                                      color: Colors.blue,
                                      fontSize: 14,
                                      fontFamily: 'Quicksand',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _showAnimalInfoSheet() {
    final PageController _localPageController = PageController();
    int _localCurrentPage = 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.93,
              minChildSize: 0.60,
              maxChildSize: 0.93,
              builder: (context, scrollController) {
                return FutureBuilder<DatabaseEvent>(
                  future: FirebaseDatabase.instance
                      .ref('animals')
                      .orderByChild('id')
                      .equalTo(widget.animalId)
                      .once(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final dataMap = Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);
                    final firstEntry = dataMap.entries.first.value as Map<dynamic, dynamic>;
                    final data = Map<String, dynamic>.from(firstEntry);
                    final photoUrls = List<String>.from(data['photoUrls'] ?? []);

                    return SingleChildScrollView(
                      controller: scrollController,
                      padding: EdgeInsets.only(
                        top: 16,
                        left: 16,
                        right: 16,
                        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Container(
                              width: 50,
                              height: 5,
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: IconButton(
                              icon: const Icon(CupertinoIcons.arrow_left, color: Colors.black),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ),
                          const SizedBox(height: 4),

                          if (photoUrls.isNotEmpty) ...[
                            SizedBox(
                              height: 220,
                              child: Stack(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).scaffoldBackgroundColor,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    width: double.infinity,
                                    height: double.infinity,
                                    alignment: Alignment.center,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: PageView.builder(
                                        controller: _localPageController,
                                        itemCount: photoUrls.length,
                                        onPageChanged: (index) {
                                          setModalState(() {
                                            _localCurrentPage = index;
                                          });
                                        },
                                        itemBuilder: (context, index) {
                                          return Image.network(
                                            photoUrls[index],
                                            fit: BoxFit.contain,
                                            width: double.infinity,
                                            height: double.infinity,
                                          );
                                        },
                                      ),
                                    ),
                                  ),

                                  Positioned(
                                    top: 10,
                                    left: 16,
                                    right: 16,
                                    child: Row(
                                      children: List.generate(photoUrls.length, (index) {
                                        bool isActive = index == _localCurrentPage;
                                        return Expanded(
                                          child: Container(
                                            margin: const EdgeInsets.symmetric(horizontal: 3),
                                            height: 2,
                                            decoration: BoxDecoration(
                                              color: isActive ? Colors.white : Colors.white.withOpacity(0.3),
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                          ),
                                        );
                                      }),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],

                          Center(
                            child: Column(
                              children: [
                                Text(
                                  '${data['name'] ?? 'Animal'}${data['age'] != null ? ' · ${data['age']}' : ''}',
                                  style: const TextStyle(
                                      fontSize: 20,
                                      fontFamily: 'Quicksand',
                                      fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),

                                if (data['breed'] != null || data['species'] != null)
                                  Text(
                                    '${data['breed'] ?? ''}${data['breed'] != null && data['species'] != null ? ' · ' : ''}${data['species'] ?? ''}',
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontFamily: 'Quicksand',
                                        fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                const SizedBox(height: 16),

                                _buildAdoptionStatusBadge(data['adoptionStatus']),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          if ((data['description'] ?? '').toString().trim().isNotEmpty)
                            _buildCardSection(
                              title: 'About Me',
                              child: Text(data['description'],
                                style: TextStyle(
                                  fontSize: 14,
                                  fontFamily: 'Quicksand',
                                ),
                              ),
                            ),

                          if (data['tags'] != null && data['tags'] is List && data['tags'].isNotEmpty)
                            _buildCardSection(
                              title: 'Traits',
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: List<String>.from(data['tags']).map((tag) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Color(0xFFFFDDB4),
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      tag,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontFamily: 'Quicksand',
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),

                          _buildCardSection(
                            title: 'Other Information',
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _infoRow('Gender', data['gender']),
                                _infoRow('Health Status', data['healthStatus']),
                              ].whereType<Widget>().toList(),
                            ),
                          ),

                          _buildCardSection(
                            title: 'Listed On',
                            child: Text(
                              _formatDate(data['createdAt']),
                              style: const TextStyle(
                                fontSize: 14,
                                fontFamily: 'Quicksand',
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> _sendMessage() async {
    if (_isSending || _userEmail == null) return;

    final text = _messageController.text.trim();
    final timestamp = DateTime.now().toIso8601String();

    if (text.isEmpty && _selectedAttachments.isEmpty) return;

    setState(() => _isSending = true);

    try {
      bool updatedLastMessage = false;

      if (_selectedAttachments.isNotEmpty) {
        for (final file in _selectedAttachments) {
          final fileExt = path.extension(file.path).toLowerCase();
          final isImage = ['.jpg', '.jpeg', '.png'].contains(fileExt);
          final fileName = DateTime.now().millisecondsSinceEpoch.toString();
          final storagePath = 'chat_attachments/${widget.conversationId}/$fileName$fileExt';

          final ref = FirebaseStorage.instance.ref(storagePath);
          final uploadTask = await ref.putFile(File(file.path));
          final downloadUrl = await uploadTask.ref.getDownloadURL();

          final newMessageRef = _messagesRef.push();

          if (isImage) {
            await newMessageRef.set({
              'sender': _userEmail,
              'imageUrl': downloadUrl,
              'timestamp': timestamp,
            });

            await FirebaseDatabase.instance
                .ref('conversations/${widget.conversationId}')
                .update({
              'lastMessage': '[Photo]',
              'lastMessageType': 'image',
              'lastTimestamp': timestamp,
              'lastSender': _userEmail,
            });
          } else {
            await newMessageRef.set({
              'sender': _userEmail,
              'documentUrl': downloadUrl,
              'fileName': path.basename(file.path),
              'timestamp': timestamp,
            });

            await FirebaseDatabase.instance
                .ref('conversations/${widget.conversationId}')
                .update({
              'lastMessage': '[Document]',
              'lastMessageType': 'document',
              'lastTimestamp': timestamp,
              'lastSender': _userEmail,
            });
          }

          updatedLastMessage = true;
        }

        setState(() => _selectedAttachments.clear());
      }

      if (text.isNotEmpty) {
        final newMessageRef = _messagesRef.push();
        await newMessageRef.set({
          'sender': _userEmail,
          'text': text,
          'timestamp': timestamp,
        });

        await FirebaseDatabase.instance
            .ref('conversations/${widget.conversationId}')
            .update({
          'lastMessage': text,
          'lastMessageType': 'text',
          'lastTimestamp': timestamp,
          'lastSender': _userEmail,
        });

        updatedLastMessage = true;
        _messageController.clear();
      }

      if (updatedLastMessage) _scrollToBottom();
    } catch (e) {
      print('Send message error: $e');
    } finally {
      setState(() => _isSending = false);
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 200), () {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  bool _isMyMessage(String senderEmail) {
    return senderEmail == _userEmail;
  }

  void _showAttachmentPicker() {
    setState(() {
      _showAttachmentOptionsCard = true;
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        _selectedAttachments.add(File(pickedFile.path));
        _showAttachmentOptionsCard = false;
      });
    }
  }

  /*
  Future<void> _pickDocument() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx'],
    );

    if (result != null && result.files.isNotEmpty) {
      final pickedFile = result.files.first;
      if (pickedFile.path != null) {
        setState(() {
          _selectedAttachments.add(File(pickedFile.path!));
          _showAttachmentOptionsCard = false;
        });
      }
    }
  }
   */

  void _updateReadStatusIfNewer(dynamic timestamp) {
    if (_lastReadTimestamp == null || timestamp.compareTo(_lastReadTimestamp!) > 0) {
      setState(() {
        _lastReadTimestamp = timestamp;
      });

      final safeEmail = _userEmail!.replaceAll('.', '_');
      FirebaseDatabase.instance
          .ref('conversations/${widget.conversationId}/readStatus/$safeEmail')
          .set(timestamp);
    }
  }

  Widget _buildAdoptionStatusBadge(String? status) {
    if (status == null) return const SizedBox.shrink();

    final Map<String, Map<String, dynamic>> statusMap = {
      'available': {
        'text': 'Available for Adoption',
        'color': Colors.green,
        'background': Colors.green[100],
      },
      'pending': {
        'text': 'Adoption Pending',
        'color': Colors.orange,
        'background': Colors.orange[100],
      },
      'adopted': {
        'text': 'Already Adopted',
        'color': Colors.red,
        'background': Colors.red[100],
      },
      'not_available': {
        'text': 'Not Available',
        'color': Colors.grey,
        'background': Colors.grey[300],
      },
    };

    final adoptionInfo = statusMap[status.toLowerCase()];
    if (adoptionInfo == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: adoptionInfo['background'],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        adoptionInfo['text'],
        style: TextStyle(
          color: adoptionInfo['color'],
          fontSize: 16,
          fontFamily: 'Quicksand',
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildAttachmentOptionsCard() {
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
              'Choose Attachment',
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
                  setState(() => _showAttachmentOptionsCard = false);
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
                  setState(() => _showAttachmentOptionsCard = false);
                },
              ),
            ),
            const SizedBox(height: 12),

            SizedBox(
              width: 200,
              child: ElevatedButton.icon(
                icon: const Icon(CupertinoIcons.doc_text),
                label: const Text('Document'),
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
                  // await _pickDocument();
                  setState(() => _showAttachmentOptionsCard = false);
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
                    setState(() => _showAttachmentOptionsCard = false),
                child: const Text('Cancel'),
              ),
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
        toolbarHeight: 74,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: IconButton(
            icon: const Icon(CupertinoIcons.arrow_left, color: Colors.black),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        titleSpacing: 6,
        title: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _showSanctuaryInfoSheet,
          child: SizedBox(
            height: kToolbarHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  backgroundImage: NetworkImage(widget.sanctuaryImageUrl),
                  radius: 26,
                ),
                const SizedBox(width: 12),

                Text(
                  widget.sanctuaryName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontFamily: 'Quicksand',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _showAnimalInfoSheet,
                child: Container(
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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundImage: NetworkImage(widget.profileImageUrl),
                        radius: 24,
                      ),
                      const SizedBox(width: 12),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.animalName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontFamily: 'Quicksand',
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),

                            Text(
                              widget.animalDescription,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                                fontFamily: 'Quicksand',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              Expanded(
                child: StreamBuilder<DatabaseEvent>(
                  stream: _messagesRef.orderByChild('timestamp').onValue,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
                      return const Center(
                          child: Text(
                              'No messages yet.',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontFamily: 'Quicksand'
                              )
                          )
                      );
                    }

                    final value = snapshot.data!.snapshot.value;
                    List<Map<String, dynamic>> messages = [];

                    if (value is Map) {
                      final raw = Map<String, dynamic>.from(value);
                      messages = raw.entries.map((e) {
                        final val = Map<String, dynamic>.from(e.value);
                        return {
                          'sender': val['sender'] ?? '',
                          'text': val['text'] ?? '',
                          'imageUrl': val['imageUrl'],
                          'timestamp': val['timestamp'],
                        };
                      }).toList();
                    } else if (value is List) {
                      for (var item in value) {
                        if (item != null && item is Map) {
                          final val = Map<String, dynamic>.from(item);
                          messages.add({
                            'sender': val['sender'] ?? '',
                            'text': val['text'] ?? '',
                            'imageUrl': val['imageUrl'],
                            'timestamp': val['timestamp'],
                          });
                        }
                      }
                    }

                    messages.sort((a, b) {
                      DateTime? aTime;
                      DateTime? bTime;

                      if (a['timestamp'] is int) {
                        aTime = DateTime.fromMillisecondsSinceEpoch(a['timestamp']);
                      } else if (a['timestamp'] is String) {
                        aTime = DateTime.tryParse(a['timestamp']);
                      }

                      if (b['timestamp'] is int) {
                        bTime = DateTime.fromMillisecondsSinceEpoch(b['timestamp']);
                      } else if (b['timestamp'] is String) {
                        bTime = DateTime.tryParse(b['timestamp']);
                      }

                      if (aTime == null && bTime == null) return 0;
                      if (aTime == null) return -1;
                      if (bTime == null) return 1;
                      return aTime.compareTo(bTime);
                    });

                    DateTime? previous;
                    for (var msg in messages) {
                      final rawTimestamp = msg['timestamp'];
                      DateTime? ts;

                      if (rawTimestamp is int) {
                        ts = DateTime.fromMillisecondsSinceEpoch(rawTimestamp);
                      } else if (rawTimestamp is String) {
                        ts = DateTime.tryParse(rawTimestamp);
                      }

                      final show = ts != null && shouldShowTimestamp(ts, previous);
                      msg['showTimestamp'] = show;
                      if (show && ts != null) previous = ts;
                    }

                    return ListView.builder(
                      controller: _scrollController,
                      itemCount: messages.length,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      itemBuilder: (context, index) {
                        final message = messages[index];
                        final isMe = _isMyMessage(message['sender']);
                        final rawTimestamp = message['timestamp'];
                        DateTime? dtTimestamp;

                        if (rawTimestamp is int) {
                          dtTimestamp = DateTime.fromMillisecondsSinceEpoch(rawTimestamp);
                        } else if (rawTimestamp is String) {
                          dtTimestamp = DateTime.tryParse(rawTimestamp);
                        }

                        final key = Key('msg-${dtTimestamp?.millisecondsSinceEpoch ?? index}');
                        final showTimestamp = message['showTimestamp'] == true;

                        print('Message: $message, isMe: $isMe, timestamp: $rawTimestamp, dtTimestamp: $dtTimestamp');

                        final isLastMyMessage = isMe &&
                            (index == messages.lastIndexWhere((m) => _isMyMessage(m['sender'])));
                        final seenByOther = _otherUserReadTimestamp != null &&
                            dtTimestamp != null &&
                            DateTime.tryParse(_otherUserReadTimestamp!) != null &&
                            (dtTimestamp.isBefore(DateTime.parse(_otherUserReadTimestamp!)) ||
                                dtTimestamp.isAtSameMomentAs(DateTime.parse(_otherUserReadTimestamp!)));

                        return Column(
                          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            if (showTimestamp && dtTimestamp != null)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: Center(
                                  child: RichText(
                                    textAlign: TextAlign.center,
                                    text: formatTimestampLabel(dtTimestamp),
                                    textScaleFactor: 1.0,
                                  ),
                                ),
                              ),
                            VisibilityDetector(
                              key: key,
                              onVisibilityChanged: (info) {
                                if (info.visibleFraction > 0.7 && dtTimestamp != null) {
                                  _updateReadStatusIfNewer(dtTimestamp.millisecondsSinceEpoch);
                                }
                              },
                              child: Align(
                                alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                                child: Container(
                                  margin: const EdgeInsets.symmetric(vertical: 4),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  constraints: BoxConstraints(
                                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isMe ? Colors.blue[100] : Colors.grey[200],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (message['imageUrl'] != null &&
                                          message['imageUrl'].toString().isNotEmpty)
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: Image.network(
                                            message['imageUrl'],
                                            width: 200,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      if (message['text'] != null &&
                                          message['text'].toString().isNotEmpty)
                                        Text(
                                          message['text'],
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontFamily: 'Quicksand',
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            if (isLastMyMessage)
                              Padding(
                                padding: const EdgeInsets.only(top: 2, right: 8),
                                child: Text(
                                  seenByOther ? 'Seen' : 'Sent',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                    fontFamily: 'Quicksand',
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),

              if (_selectedAttachments.isNotEmpty)
                Container(
                  height: 100,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _selectedAttachments.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      final file = _selectedAttachments[index];
                      return Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              File(file.path),
                              height: 80,
                              width: 80,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () {
                                setState(() => _selectedAttachments.removeAt(index));
                              },
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                    Icons.close,
                                    size: 18,
                                    color: Colors.white,
                                ),
                              ),
                            ),
                          )
                        ],
                      );
                    },
                  ),
                ),

              SafeArea(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        offset: const Offset(0, -3),
                        blurRadius: 6,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(CupertinoIcons.add),
                        color: Colors.blue,
                        onPressed: () {
                          _showAttachmentPicker();
                        },
                      ),
                      const SizedBox(width: 2),

                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          decoration: InputDecoration(
                            hintText: 'Type a message...',
                            hintStyle: const TextStyle(
                              fontSize: 16,
                              fontFamily: 'Quicksand',
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide.none,
                            ),
                            fillColor: Colors.grey[200],
                            filled: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),

                      _isSending
                          ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.blue),
                          ),
                        ),
                      )
                          : IconButton(
                        onPressed: _sendMessage,
                        icon: const Icon(CupertinoIcons.paperplane_fill),
                        color: Colors.blue,
                      ),
                    ],
                  ),
                ),
              )
            ],
          ),
          if (_showAttachmentOptionsCard)
            Container(
              color: Colors.black.withOpacity(0.4),
              child: _buildAttachmentOptionsCard(),
            ),
        ],
      ),
    );
  }
}