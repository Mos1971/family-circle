import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/push_provider.dart';
import '../push/push_service.dart';
import '../theme/app_theme.dart';

/// "Alerts on this device": turns on phone / browser alerts so new messages
/// and updates arrive even when the app is closed or the phone is locked.
class AlertsCard extends StatelessWidget {
  const AlertsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final push = context.watch<PushProvider>();

    String line;
    Widget? action;
    IconData icon = Icons.notifications_active_outlined;

    switch (push.status) {
      case PushStatus.enabled:
        line =
            'On. New messages and updates will alert this device, even '
            'when the app is closed.';
        icon = Icons.notifications_active;
        break;
      case PushStatus.denied:
        line =
            'Blocked for this device. Allow notifications for Family '
            'Circle in your phone or browser settings, then come back.';
        icon = Icons.notifications_off_outlined;
        break;
      case PushStatus.unsupported:
        line =
            'This browser or device can\'t receive alerts. On an iPhone, '
            'add Family Circle to your Home Screen first, then open it from '
            'there.';
        break;
      case PushStatus.notAsked:
        line =
            'Get a ping for new messages and updates, even when your '
            'phone is locked.';
        action = ElevatedButton(
          onPressed: push.busy ? null : () => push.enable(),
          child: Text(push.busy ? 'Turning on…' : 'Turn on alerts'),
        );
        break;
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.gold),
              const SizedBox(width: 10),
              const Text(
                'Alerts on this device',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            line,
            style: TextStyle(fontSize: 13, color: AppColors.muted, height: 1.4),
          ),
          if (action != null) ...[const SizedBox(height: 12), action],
        ],
      ),
    );
  }
}
