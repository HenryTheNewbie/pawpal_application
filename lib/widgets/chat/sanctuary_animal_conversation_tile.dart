import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../theme/theme.dart';
import '../../routes/routes.dart';
import 'package:flutter/cupertino.dart';

class SanctuaryAnimalConversationTile extends StatelessWidget {
  final String animalName;
  final String profileImageUrl;
  final String age;
  final String ageGroup;
  final String species;
  final String breed;
  final int activeChatCount;
  final int requestCount;
  final VoidCallback onTap;

  const SanctuaryAnimalConversationTile({
    super.key,
    required this.animalName,
    required this.profileImageUrl,
    required this.age,
    required this.ageGroup,
    required this.species,
    required this.breed,
    required this.activeChatCount,
    required this.requestCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    String subtitleLine1 = '';
    if (ageGroup.isNotEmpty) {
      subtitleLine1 += ageGroup;
    }
    if (species.isNotEmpty || breed.isNotEmpty) {
      if (subtitleLine1.isNotEmpty) subtitleLine1 += ' · ';
      subtitleLine1 += '$breed${breed.isNotEmpty && species.isNotEmpty ? ' · ' : ''}$species';
    }

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 30,
              backgroundImage: NetworkImage(profileImageUrl),
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

                  Text(
                    subtitleLine1,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      fontFamily: 'Quicksand',
                    ),
                  ),
                  const SizedBox(height: 6),

                  Text(
                    '$requestCount chat requests',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                      fontFamily: 'Quicksand',
                    ),
                  ),
                  const SizedBox(height: 4),

                  Text(
                    '$activeChatCount active conversations',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                      fontFamily: 'Quicksand',
                    ),
                  ),
                ],
              ),
            ),
            const Icon(CupertinoIcons.forward, color: AppColors.textPrimary),
          ],
        ),
      ),
    );
  }
}