import 'package:flutter/material.dart';

import '../models/announcement.dart';
import '../theme/app_theme.dart';
import '../utils/time_format.dart';

class AnnouncementCard extends StatelessWidget {
  const AnnouncementCard({
    super.key,
    required this.announcement,
    this.onTap,
    this.compact = false,
  });

  final Announcement announcement;
  final VoidCallback? onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surfaceHigh,
          border: Border.all(color: AppColors.gold.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('📢', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
                Text(
                  'FROM THE ADMINS',
                  style: TextStyle(
                    color: AppColors.gold,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    letterSpacing: 1.2,
                  ),
                ),
                const Spacer(),
                if (announcement.pinned)
                  Icon(Icons.push_pin, color: AppColors.gold, size: 16),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              announcement.title,
              style: TextStyle(
                color: AppColors.text,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (!compact) ...[
              const SizedBox(height: 6),
              Text(
                announcement.body,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: AppColors.text, height: 1.4),
              ),
            ],
            const SizedBox(height: 10),
            Text(
              timeAgo(announcement.createdAt),
              style: TextStyle(color: AppColors.muted, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
