import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/theme_mode_provider.dart';
import '../theme/app_theme.dart';

class _SchemeChoice extends StatelessWidget {
  const _SchemeChoice({
    required this.scheme,
    required this.selected,
    required this.onTap,
  });

  final AppScheme scheme;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: SizedBox(
        width: 84,
        child: Column(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: scheme.swatch,
                border: Border.all(
                  color: selected ? AppColors.text : AppColors.border,
                  width: selected ? 3 : 1,
                ),
              ),
              child: selected
                  ? const Icon(Icons.check, color: Colors.black87)
                  : null,
            ),
            const SizedBox(height: 6),
            Text(
              scheme.label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? AppColors.text : AppColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Lets the person choose Light, Dark, or follow their device, plus a colour
/// scheme.
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
            const SizedBox(height: 18),
            Text(
              'Colour scheme',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 12,
              children: [
                for (final s in AppScheme.values)
                  _SchemeChoice(
                    scheme: s,
                    selected: s == theme.scheme,
                    onTap: () => context.read<ThemeModeProvider>().setScheme(s),
                  ),
              ],
            ),
            const SizedBox(height: 14),
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
