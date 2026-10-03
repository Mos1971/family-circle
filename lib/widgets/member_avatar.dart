import 'package:flutter/material.dart';

import '../models/user.dart';
import '../theme/app_theme.dart';

class MemberAvatar extends StatelessWidget {
  const MemberAvatar({super.key, this.user, this.radius = 20});

  final AppUser? user;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.gold.withValues(alpha: 0.12),
      child: Text(
        user?.profileEmoji ?? '🧡',
        style: TextStyle(fontSize: radius * 0.95),
      ),
    );
  }
}
