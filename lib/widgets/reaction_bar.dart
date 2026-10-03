import 'package:flutter/material.dart';

import '../models/reaction.dart';
import '../theme/app_theme.dart';

class ReactionBar extends StatelessWidget {
  const ReactionBar({
    super.key,
    required this.reactions,
    required this.myReaction,
    required this.onTap,
  });

  final Map<ReactionType, Set<String>> reactions;
  final ReactionType? myReaction;
  final ValueChanged<ReactionType> onTap;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: ReactionType.values.map((type) {
        final count = reactions[type]?.length ?? 0;
        final selected = myReaction == type;
        return InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => onTap(type),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.gold.withValues(alpha: 0.14)
                  : AppColors.surfaceHigh,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected ? AppColors.gold : AppColors.border,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(type.emoji, style: const TextStyle(fontSize: 15)),
                if (count > 0) ...[
                  const SizedBox(width: 5),
                  Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: selected ? AppColors.goldDark : AppColors.muted,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
