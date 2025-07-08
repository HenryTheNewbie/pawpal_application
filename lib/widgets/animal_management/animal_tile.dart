import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../theme/theme.dart';
import '../../routes/routes.dart';
import 'package:flutter/cupertino.dart';

class AnimalTile extends StatelessWidget {
  final String animalName;
  final String profileImageUrl;
  final String species;
  final String breed;
  final String description;
  final String dateAdded;
  final String adoptionStatus;
  final VoidCallback onTap;

  const AnimalTile({
    super.key,
    required this.animalName,
    required this.profileImageUrl,
    required this.species,
    required this.breed,
    required this.description,
    required this.dateAdded,
    required this.adoptionStatus,
    required this.onTap,
  });

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
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: adoptionInfo['background'],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        adoptionInfo['text'],
        style: TextStyle(
          color: adoptionInfo['color'],
          fontSize: 14,
          fontFamily: 'Quicksand',
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String subtitleLine = '';
    if (breed.isNotEmpty) {
      subtitleLine += breed;
    }
    if (species.isNotEmpty) {
      if (subtitleLine.isNotEmpty) subtitleLine += ' · ';
      subtitleLine += species;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Card(
        elevation: 4,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage: profileImageUrl.isNotEmpty ? NetworkImage(profileImageUrl) : null,
                  child: profileImageUrl.isEmpty
                      ? const Icon(Icons.pets, color: Colors.grey, size: 28)
                      : null,
                ),
                const SizedBox(width: 16),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        animalName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Quicksand',
                        ),
                      ),
                      const SizedBox(height: 2),

                      if (subtitleLine.isNotEmpty)
                        Text(
                          subtitleLine,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                            fontFamily: 'Quicksand',
                          ),
                        ),

                      if (description.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textPrimary,
                            fontFamily: 'Quicksand',
                          ),
                        ),
                      ],

                      const SizedBox(height: 6),
                      Text(
                        'Added on $dateAdded',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textPrimary,
                          fontFamily: 'Quicksand',
                        ),
                      ),

                      const SizedBox(height: 6),
                      _buildAdoptionStatusBadge(adoptionStatus),
                    ],
                  ),
                ),
                const Icon(CupertinoIcons.forward, color: AppColors.textPrimary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}