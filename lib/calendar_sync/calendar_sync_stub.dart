import '../models/external_event.dart';
import 'calendar_sync_service.dart';

CalendarSyncService createCalendarSyncService() => _UnsupportedService();

class _UnsupportedService implements CalendarSyncService {
  @override
  bool get supported => false;

  @override
  Future<String> token(ExternalSource source, {required bool interactive}) =>
      throw UnsupportedError('Calendar sync is available in the web app.');

  @override
  Future<void> signOut(ExternalSource source) async {}

  @override
  Set<ExternalSource> loadConnected() => {};

  @override
  void saveConnected(Set<ExternalSource> sources) {}
}
