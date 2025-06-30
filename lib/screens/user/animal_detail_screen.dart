import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../firebase_options.dart';
import '../../theme/theme.dart';
import '../../routes/routes.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/cupertino.dart';

class AnimalDetailScreen extends StatefulWidget {
  final String animalId;

  const AnimalDetailScreen({super.key, required this.animalId});

  @override
  State<AnimalDetailScreen> createState() => _AnimalDetailScreenState();
}

class _AnimalDetailScreenState extends State<AnimalDetailScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

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
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: Text(value.toString()),
          ),
        ],
      ),
    );
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
      body: FutureBuilder<DatabaseEvent>(
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
            padding: EdgeInsets.only(
              top: 16,
              left: 16,
              right: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                              controller: _pageController,
                              itemCount: photoUrls.length,
                              onPageChanged: (index) {
                                setState(() => _currentPage = index);
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
                              bool isActive = index == _currentPage;
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
                      style: const TextStyle(
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
                            color: const Color(0xFFFFDDB4),
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
      ),
    );
  }
}