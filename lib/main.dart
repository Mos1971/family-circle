import 'package:flutter/material.dart';

import 'app.dart';
import 'firebase/firebase_backend.dart';

/// Run with `--dart-define=USE_MOCK=true` to use sample data instead of
/// Firebase (no sign-in, resets on restart).
const bool _useMock = bool.fromEnvironment('USE_MOCK');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (_useMock) {
    runApp(const FamilyCircleApp.mock());
    return;
  }
  final backend = await FirebaseBackend.create();
  runApp(FamilyCircleApp.firebase(backend));
}
