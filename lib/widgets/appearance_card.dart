import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/theme_mode_provider.dart';
import '../theme/app_theme.dart';

/// Lets the person choose Light, Dark, or follow their device.
class AppearanceCard extends StatelessWidget {
  const AppearanceCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeModeProvider>();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'APPEARANCE',
              style: TextStyle(
                color: AppColors.gold,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<ThemeMode>(
                segments: const [
                  ButtonSegment(
                    value: ThemeMode.system,
                    label: Text('Auto'),
                    icon: Icon(Icons.brightness_auto_outlined),
                  ),
                  ButtonSegment(
                    value: ThemeMode.light,
                    label: Text('Light'),
                    icon: Icon(Icons.light_mode_outlined),
                  ),
                  ButtonSegment(
                    value: ThemeMode.dark,
                    label: Text('Dark'),
                    icon: Icon(Icons.dark_mode_outlined),
                  ),
                ],
                selected: {theme.mode},
                showSelectedIcon: false,
                style: SegmentedButton.styleFrom(
                  selectedBackgroundColor: AppColors.gold,
                  selectedForegroundColor: AppColors.onGold,
                  foregroundColor: AppColors.text,
                  side: BorderSide(color: AppColors.border),
                ),
                onSelectionChanged: (s) =>
                    context.read<ThemeModeProvider>().setMode(s.first),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              theme.mode == ThemeMode.system
                  ? 'Matches your phone or computer setting.'
                  : 'Always ${theme.mode == ThemeMode.light ? 'light' : 'dark'} on this device.',
              style: TextStyle(fontSize: 12, color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}
