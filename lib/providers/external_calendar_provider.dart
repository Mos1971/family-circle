import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../calendar_sync/calendar_sync_config.dart';
import '../calendar_sync/calendar_sync_service.dart';
import '../models/external_event.dart';

/// Pulls events from the person's own Google / Outlook calendars so they can
/// be shown (read-only) on "My calendar". Events are held in memory only —
/// nothing is copied to our servers — and are refreshed whenever the person
/// taps Sync (and once automatically after each visit's first connect).
class ExternalCalendarProvider extends ChangeNotifier {
  ExternalCalendarProvider({CalendarSyncService? service})
    : _service = service ?? CalendarSyncService() {
    _remembered = _service.loadConnected();
    // Quietly reconnect anything connected on a previous visit.
    for (final s in _remembered.toList()) {
      if (_enabled(s)) _reconnectQuietly(s);
    }
  }

  final CalendarSyncService _service;
  Set<ExternalSource> _remembered = {};

  final Map<ExternalSource, List<ExternalEvent>> _events = {};
  final Map<ExternalSource, String> _tokens = {};
  final Map<ExternalSource, String> _errors = {};
  final Set<ExternalSource> _busy = {};
  final Map<ExternalSource, DateTime> _lastSync = {};

  bool get supported => _service.supported;
  bool get anyEnabled => CalendarSyncConfig.anyEnabled;

  bool isEnabled(ExternalSource s) => _enabled(s);
  bool isConnected(ExternalSource s) => _tokens.containsKey(s);
  bool isBusy(ExternalSource s) => _busy.contains(s);

  /// Remembered from an earlier visit but not currently signed in.
  bool needsReconnect(ExternalSource s) =>
      _remembered.contains(s) && !isConnected(s) && !isBusy(s);
  String? errorFor(ExternalSource s) => _errors[s];
  DateTime? lastSync(ExternalSource s) => _lastSync[s];
  int countFor(ExternalSource s) => _events[s]?.length ?? 0;

  bool _enabled(ExternalSource s) => s == ExternalSource.google
      ? CalendarSyncConfig.googleEnabled
      : CalendarSyncConfig.microsoftEnabled;

  List<ExternalEvent> get all => [for (final l in _events.values) ...l];

  /// External events on [day], all-day first then by time.
  List<ExternalEvent> onDay(DateTime day) {
    final list = all
        .where(
          (e) =>
              e.date.year == day.year &&
              e.date.month == day.month &&
              e.date.day == day.day,
        )
        .toList();
    list.sort(
      (a, b) =>
          (a.minutesFromMidnight ?? -1).compareTo(b.minutesFromMidnight ?? -1),
    );
    return list;
  }

  // ---- Actions ------------------------------------------------------------

  /// Shows the sign-in pop-up (must be called from a tap) and pulls events.
  Future<void> connect(ExternalSource source) async {
    _errors.remove(source);
    _busy.add(source);
    notifyListeners();
    try {
      _tokens[source] = await _service.token(source, interactive: true);
      _remembered.add(source);
      _service.saveConnected(_remembered);
      await _fetch(source);
    } catch (e) {
      _tokens.remove(source);
      _errors[source] = _clean(e);
    } finally {
      _busy.remove(source);
      notifyListeners();
    }
  }

  Future<void> refresh(ExternalSource source) async {
    if (!isConnected(source)) return connect(source);
    _errors.remove(source);
    _busy.add(source);
    notifyListeners();
    try {
      await _fetch(source);
    } catch (e) {
      _errors[source] = _clean(e);
    } finally {
      _busy.remove(source);
      notifyListeners();
    }
  }

  Future<void> refreshAll() async {
    for (final s in _tokens.keys.toList()) {
      await refresh(s);
    }
  }

  Future<void> disconnect(ExternalSource source) async {
    _tokens.remove(source);
    _events.remove(source);
    _errors.remove(source);
    _lastSync.remove(source);
    _remembered.remove(source);
    _service.saveConnected(_remembered);
    await _service.signOut(source);
    notifyListeners();
  }

  Future<void> _reconnectQuietly(ExternalSource source) async {
    _busy.add(source);
    notifyListeners();
    try {
      _tokens[source] = await _service.token(source, interactive: false);
      await _fetch(source);
    } catch (_) {
      // Needs the person to tap Connect again; shown as "Reconnect".
      _tokens.remove(source);
    } finally {
      _busy.remove(source);
      notifyListeners();
    }
  }

  String _clean(Object e) =>
      e.toString().replaceFirst('Exception: ', '').replaceFirst('Error: ', '');

  // ---- Fetching -----------------------------------------------------------

  Future<void> _fetch(ExternalSource source) async {
    final now = DateTime.now();
    final from = DateTime(now.year, now.month - 1, 1);
    final to = DateTime(now.year, now.month + 4, 1);

    try {
      _events[source] = source == ExternalSource.google
          ? await _fetchGoogle(_tokens[source]!, from, to)
          : await _fetchMicrosoft(_tokens[source]!, from, to);
    } on _Unauthorized {
      // Token expired (they last ~1 hour). Try for a fresh one without a
      // pop-up; if that needs the person, ask them to reconnect.
      try {
        _tokens[source] = await _service.token(source, interactive: false);
        _events[source] = source == ExternalSource.google
            ? await _fetchGoogle(_tokens[source]!, from, to)
            : await _fetchMicrosoft(_tokens[source]!, from, to);
      } catch (_) {
        _tokens.remove(source);
        throw Exception('Your ${source.label} session ended. Tap Connect.');
      }
    }
    _lastSync[source] = DateTime.now();
  }

  Future<List<ExternalEvent>> _fetchGoogle(
    String token,
    DateTime from,
    DateTime to,
  ) async {
    final out = <ExternalEvent>[];
    String? pageToken;
    var pages = 0;
    do {
      final uri = Uri.https(
        'www.googleapis.com',
        '/calendar/v3/calendars/primary/events',
        {
          'singleEvents': 'true',
          'orderBy': 'startTime',
          'maxResults': '250',
          'timeMin': from.toUtc().toIso8601String(),
          'timeMax': to.toUtc().toIso8601String(),
          'pageToken': ?pageToken,
        },
      );
      final r = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      );
      if (r.statusCode == 401) throw _Unauthorized();
      if (r.statusCode != 200) {
        throw Exception('Google Calendar said no (${r.statusCode}).');
      }
      final data = jsonDecode(r.body) as Map<String, dynamic>;
      for (final item in (data['items'] as List? ?? const [])) {
        final m = item as Map<String, dynamic>;
        if (m['status'] == 'cancelled') continue;
        final start = m['start'] as Map<String, dynamic>?;
        if (start == null) continue;
        final parsed = _parseStart(
          dateTime: start['dateTime'] as String?,
          date: start['date'] as String?,
        );
        if (parsed == null) continue;
        out.add(
          ExternalEvent(
            id: 'g_${m['id']}',
            title: (m['summary'] as String?)?.trim().isNotEmpty == true
                ? m['summary'] as String
                : '(No title)',
            date: parsed.$1,
            minutesFromMidnight: parsed.$2,
            source: ExternalSource.google,
            location: (m['location'] as String?) ?? '',
          ),
        );
      }
      pageToken = data['nextPageToken'] as String?;
      pages++;
    } while (pageToken != null && pages < 4);
    return out;
  }

  Future<List<ExternalEvent>> _fetchMicrosoft(
    String token,
    DateTime from,
    DateTime to,
  ) async {
    final out = <ExternalEvent>[];
    Uri? next = Uri.https('graph.microsoft.com', '/v1.0/me/calendarView', {
      'startDateTime': from.toUtc().toIso8601String(),
      'endDateTime': to.toUtc().toIso8601String(),
      r'$top': '250',
      r'$orderby': 'start/dateTime',
      r'$select': 'id,subject,start,isAllDay,location,isCancelled',
    });
    var pages = 0;
    while (next != null && pages < 4) {
      final r = await http.get(
        next,
        headers: {
          'Authorization': 'Bearer $token',
          // Ask for UTC so we convert to the person's local time ourselves.
          'Prefer': 'outlook.timezone="UTC"',
        },
      );
      if (r.statusCode == 401) throw _Unauthorized();
      if (r.statusCode != 200) {
        throw Exception('Outlook said no (${r.statusCode}).');
      }
      final data = jsonDecode(r.body) as Map<String, dynamic>;
      for (final item in (data['value'] as List? ?? const [])) {
        final m = item as Map<String, dynamic>;
        if (m['isCancelled'] == true) continue;
        final start = m['start'] as Map<String, dynamic>?;
        final raw = start?['dateTime'] as String?;
        if (raw == null) continue;
        final allDay = m['isAllDay'] == true;
        // Graph returns e.g. 2026-10-05T09:00:00.0000000 (UTC, no suffix).
        final utc = DateTime.parse(raw.endsWith('Z') ? raw : '${raw}Z');
        final local = allDay
            ? DateTime(utc.year, utc.month, utc.day)
            : utc.toLocal();
        out.add(
          ExternalEvent(
            id: 'm_${m['id']}',
            title: (m['subject'] as String?)?.trim().isNotEmpty == true
                ? m['subject'] as String
                : '(No title)',
            date: DateTime(local.year, local.month, local.day),
            minutesFromMidnight: allDay ? null : local.hour * 60 + local.minute,
            source: ExternalSource.microsoft,
            location:
                ((m['location'] as Map<String, dynamic>?)?['displayName']
                    as String?) ??
                '',
          ),
        );
      }
      final link = data['@odata.nextLink'] as String?;
      next = link == null ? null : Uri.parse(link);
      pages++;
    }
    return out;
  }

  /// Returns (day, minutesFromMidnight?) for a Google start value.
  (DateTime, int?)? _parseStart({String? dateTime, String? date}) {
    if (dateTime != null) {
      final local = DateTime.parse(dateTime).toLocal();
      return (
        DateTime(local.year, local.month, local.day),
        local.hour * 60 + local.minute,
      );
    }
    if (date != null) {
      final d = DateTime.parse(date);
      return (DateTime(d.year, d.month, d.day), null);
    }
    return null;
  }
}

class _Unauthorized implements Exception {}
