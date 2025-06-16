import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../theme/theme.dart';
import '../../routes/routes.dart';
import 'package:flutter/cupertino.dart';

class ChatTile extends StatelessWidget {
  final String animalName;
  final String sanctuaryName;
  final String profileImageUrl;
  final String lastMessage;
  final String lastMessageType;
  final String timestamp;
  final bool isUnread;
  final VoidCallback onTap;

  const ChatTile({
    super.key,
    required this.animalName,
    required this.sanctuaryName,
    required this.profileImageUrl,
    required this.lastMessage,
    required this.lastMessageType,
    required this.timestamp,
    this.isUnread = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        onTap();
      },
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
                    sanctuaryName,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      fontFamily: 'Quicksand',
                    ),
                  ),
                  const SizedBox(height: 6),

                  Row(
                    children: [
                      if (lastMessageType == 'image') ...[
                        const Icon(CupertinoIcons.photo, size: 16, color: AppColors.textPrimary),
                        const SizedBox(width: 6),
                        Text(
                          'Photo',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textPrimary,
                            fontFamily: 'Quicksand',
                            fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ] else ...[
                        Expanded(
                          child: Text(
                            lastMessage,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textPrimary,
                              fontFamily: 'Quicksand',
                              fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),

            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  timestamp,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontFamily: 'Quicksand',
                  ),
                ),
                if (isUnread) ...[
                  const SizedBox(height: 8),

                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}