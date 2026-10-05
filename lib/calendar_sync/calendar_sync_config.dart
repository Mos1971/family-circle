/// Public OAuth client IDs for calendar sync. These are identifiers, not
/// secrets. Leave a value empty to hide that provider in the app.
///
/// See docs/CALENDAR_SYNC_SETUP.md for how to create them.
class CalendarSyncConfig {
  CalendarSyncConfig._();

  /// Google Cloud Console -> APIs & Services -> Credentials -> OAuth client ID
  /// (type "Web application"). Looks like 123456-abc.apps.googleusercontent.com
  static const googleClientId =
      '926394248212-l5vj601v4lac0hoobq4cpkoiqsq099l7.apps.googleusercontent.com';

  /// Azure portal -> App registrations -> Application (client) ID.
  /// Looks like 11111111-2222-3333-4444-555555555555
  static const microsoftClientId = '807a952b-d50f-44f8-a5d5-c3998b69808a';

  static bool get googleEnabled => googleClientId.isNotEmpty;
  static bool get microsoftEnabled => microsoftClientId.isNotEmpty;
  static bool get anyEnabled => googleEnabled || microsoftEnabled;
}
