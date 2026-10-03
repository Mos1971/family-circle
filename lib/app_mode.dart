/// Whether the app is running against the in-memory mock backend (tests and
/// quick demos) or the live Firebase backend.
class AppMode {
  const AppMode({required this.isMock});
  final bool isMock;
}
