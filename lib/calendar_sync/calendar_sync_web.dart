import 'dart:js_interop';

import '../models/external_event.dart';
import 'calendar_sync_config.dart';
import 'calendar_sync_service.dart';

@JS('fcCalendarSync.googleToken')
external JSPromise<JSString> _googleToken(String clientId, bool interactive);

@JS('fcCalendarSync.microsoftToken')
external JSPromise<JSString> _microsoftToken(String clientId, bool interactive);

@JS('fcCalendarSync.microsoftSignOut')
external JSPromise<JSAny?> _microsoftSignOut();

@JS('fcCalendarSync.getFlags')
external String _getFlags();

@JS('fcCalendarSync.setFlags')
external void _setFlags(String value);

CalendarSyncService createCalendarSyncService() => _WebService();

class _WebService implements CalendarSyncService {
  @override
  bool get supported => true;

  @override
  Future<String> token(
    ExternalSource source, {
    required bool interactive,
  }) async {
    try {
      if (source == ExternalSource.google) {
        final t = await _googleToken(
          CalendarSyncConfig.googleClientId,
          interactive,
        ).toDart;
        return t.toDart;
      }
      final t = await _microsoftToken(
        CalendarSyncConfig.microsoftClientId,
        interactive,
      ).toDart;
      return t.toDart;
    } catch (e) {
      throw Exception(_describe(e));
    }
  }

  /// JS errors surface as opaque objects; pull out something readable.
  String _describe(Object e) {
    final text = e.toString();
    if (text.contains('popup_closed') || text.contains('user_cancelled')) {
      return 'Sign-in was cancelled.';
    }
    if (text.contains('popup_window_error') ||
        text.contains('empty_window_error') ||
        text.contains('popup_failed_to_open')) {
      return 'Your browser blocked the sign-in pop-up. Allow pop-ups for this '
          'site, then try again.';
    }
    if (text.contains('interaction_required') ||
        text.contains('consent_required') ||
        text.contains('login_required')) {
      return 'Please connect again.';
    }
    return text.replaceFirst('Exception: ', '').replaceFirst('Error: ', '');
  }

  @override
  Future<void> signOut(ExternalSource source) async {
    if (source == ExternalSource.microsoft) {
      try {
        await _microsoftSignOut().toDart;
      } catch (_) {}
    }
  }

  @override
  Set<ExternalSource> loadConnected() {
    final raw = _getFlags();
    return {
      for (final s in ExternalSource.values)
        if (raw.split(',').contains(s.name)) s,
    };
  }

  @override
  void saveConnected(Set<ExternalSource> sources) =>
      _setFlags(sources.map((s) => s.name).join(','));
}
