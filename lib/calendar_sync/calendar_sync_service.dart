import '../models/external_event.dart';
import 'calendar_sync_stub.dart'
    if (dart.library.js_interop) 'calendar_sync_web.dart'
    as impl;

/// Platform bridge for the sign-in step. Only the web app can do this today.
abstract class CalendarSyncService {
  factory CalendarSyncService() => impl.createCalendarSyncService();

  bool get supported;

  /// Returns an access token for reading the person's calendar. When
  /// [interactive] is false it must not open any pop-up (it throws instead).
  Future<String> token(ExternalSource source, {required bool interactive});

  Future<void> signOut(ExternalSource source);

  /// Which sources this browser has connected before (so the app can
  /// reconnect quietly on the next visit).
  Set<ExternalSource> loadConnected();
  void saveConnected(Set<ExternalSource> sources);
}
