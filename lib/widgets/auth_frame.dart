import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';
import 'app_layout.dart';

/// Wraps the sign-in / register / waiting screens. On a phone it does
/// nothing; on a wide screen it shows a brand panel beside the form.
class AuthFrame extends StatelessWidget {
  const AuthFrame({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!isDesktopWidth(context)) return child;

    return Material(
      color: AppColors.bg,
      child: Row(
        children: [
          const Expanded(child: _BrandPanel()),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: child,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BrandPanel extends StatelessWidget {
  const _BrandPanel();

  @override
  Widget build(BuildContext context) {
    Widget point(IconData icon, String title, String body) => Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
            ),
            child: Icon(icon, color: AppColors.gold, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: TextStyle(color: AppColors.muted, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AppColors.brandGradient,
        ),
        border: Border(right: BorderSide(color: AppColors.border)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 72, vertical: 56),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'A private home\nfor your whole family.',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 46,
                  height: 1.15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.gold,
                ),
              ),
              const SizedBox(height: 36),
              point(
                Icons.dynamic_feed_outlined,
                'Share with the family',
                'A feed just for the people you trust.',
              ),
              point(
                Icons.chat_bubble_outline,
                'Private messages',
                'One-to-one chats only the two of you can read.',
              ),
              point(
                Icons.event_note_outlined,
                'Calendar & lists',
                'Plan together, keep your own, share when you want to.',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
