import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/external_event.dart';
import '../../providers/external_calendar_provider.dart';
import '../../theme/app_theme.dart';

/// Colour used for events synced from Google / Outlook.
const kExternalColor = Color(0xFF6FA8DC);

/// A read-only event synced from the person's Google or Outlook calendar.
class ExternalEventTile extends StatelessWidget {
  const ExternalEventTile({super.key, required this.event});

  final ExternalEvent event;

  @override
  Widget build(BuildContext context) {
    final where = event.location.isEmpty ? '' : ' · ${event.location}';
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 40,
                decoration: BoxDecoration(
                  color: kExternalColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${event.timeLabel} · ${event.source.label}$where',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.sync, size: 18, color: kExternalColor),
            ],
          ),
        ),
      ),
    );
  }
}

/// Connect / sync controls for Google Calendar and Outlook.
class SyncPanel extends StatelessWidget {
  const SyncPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final ext = context.watch<ExternalCalendarProvider>();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.sync, size: 18, color: kExternalColor),
              SizedBox(width: 8),
              Text(
                'Sync your other calendars',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Read-only and only for you: your events show here in blue. '
            'Nothing is saved on our servers and nobody else can see them.',
            style: TextStyle(fontSize: 12, color: AppColors.muted),
          ),
          const SizedBox(height: 10),
          if (!ext.supported)
            const Text(
              'Calendar sync works in the web app. Open Family Circle in '
              'your browser.',
              style: TextStyle(fontSize: 12, color: AppColors.muted),
            )
          else
            for (final source in ExternalSource.values)
              if (ext.isEnabled(source)) _SourceRow(source: source),
        ],
      ),
    );
  }
}

class _SourceRow extends StatelessWidget {
  const _SourceRow({required this.source});

  final ExternalSource source;

  @override
  Widget build(BuildContext context) {
    final ext = context.watch<ExternalCalendarProvider>();
    final connected = ext.isConnected(source);
    final busy = ext.isBusy(source);
    final error = ext.errorFor(source);

    String status;
    if (busy) {
      status = 'Syncing…';
    } else if (connected) {
      status = '${ext.countFor(source)} events synced';
    } else if (ext.needsReconnect(source)) {
      status = 'Tap Reconnect to refresh';
    } else {
      status = 'Not connected';
    }

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                source == ExternalSource.google
                    ? Icons.event_available
                    : Icons.mail_outline,
                size: 20,
                color: connected ? kExternalColor : AppColors.muted,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(source.label),
                    Text(
                      status,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              if (busy)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else if (connected) ...[
                IconButton(
                  tooltip: 'Sync now',
                  icon: const Icon(Icons.refresh, size: 20),
                  onPressed: () => ext.refresh(source),
                ),
                TextButton(
                  onPressed: () => ext.disconnect(source),
                  child: const Text('Disconnect'),
                ),
              ] else
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                  onPressed: () => ext.connect(source),
                  child: Text(
                    ext.needsReconnect(source) ? 'Reconnect' : 'Connect',
                  ),
                ),
            ],
          ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(left: 30, top: 2),
              child: Text(
                error,
                style: const TextStyle(fontSize: 12, color: AppColors.danger),
              ),
            ),
        ],
      ),
    );
  }
}
