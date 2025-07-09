import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../theme/theme.dart';
import '../../routes/routes.dart';
import 'package:flutter/cupertino.dart';

class SanctuaryRequestTile extends StatelessWidget {
  final String username;
  final String bio;
  final String profileImageUrl;
  final String requestTime;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const SanctuaryRequestTile({
    super.key,
    required this.username,
    required this.bio,
    required this.profileImageUrl,
    required this.requestTime,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
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
                  username,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Quicksand',
                  ),
                ),
                const SizedBox(height: 2),

                Text(
                  bio,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    fontFamily: 'Quicksand',
                  ),
                ),
                const SizedBox(height: 6),

                Text(
                  'Requested on $requestTime',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                    fontFamily: 'Quicksand',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          Row(
            children: [
              GestureDetector(
                onTap: onAccept,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Color(0xFF4DED88),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    CupertinoIcons.check_mark,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 16),

              GestureDetector(
                onTap: onReject,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF4D4D),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    CupertinoIcons.xmark,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}