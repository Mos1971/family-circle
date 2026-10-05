import 'package:flutter/material.dart';

import '../models/user.dart';
import '../theme/app_theme.dart';
import 'member_avatar.dart';

/// Avatar for a conversation: the other person's emoji for a private chat, or
/// a group icon for a group.
class ConversationAvatar extends StatelessWidget {
  const ConversationAvatar({
    super.key,
    required this.isGroup,
    this.user,
    this.radius = 22,
  });

  final bool isGroup;
  final AppUser? user;
  final double radius;

  @override
  Widget build(BuildContext context) {
    if (!isGroup) return MemberAvatar(user: user, radius: radius);
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.gold.withValues(alpha: 0.18),
      child: Icon(Icons.groups, color: AppColors.gold, size: radius * 1.1),
    );
  }
}
