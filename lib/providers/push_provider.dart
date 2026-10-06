import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import '../push/push_service.dart';
import 'auth_provider.dart';

/// State for "Alerts on this device" and the plumbing that keeps the device
/// registered while someone is signed in. [service] is null in demo mode.
class PushProvider extends ChangeNotifier {
  PushProvider(this._service, this._auth, GoRouter router) {
    if (_service == null) return;
    _auth.addListener(_onAuthChanged);
    _onAuthChanged();
    _listenForTaps(router);
  }

  final PushService? _service;
  final AuthProvider _auth;

  PushStatus _status = PushStatus.unsupported;
  PushStatus get status => _status;
  bool _busy = false;
  bool get busy => _busy;
  bool _wasSignedIn = false;

  Future<void> _refreshStatus() async {
    _status = await _service!.status();
    notifyListeners();
  }

  /// Signed in and approved -> make sure this device is registered if the
  /// person has already allowed alerts.
  Future<void> _onAuthChanged() async {
    final ready = _auth.isLoggedIn && _auth.isApproved;
    if (ready) {
      _wasSignedIn = true;
      await _service!.syncIfEnabled();
    }
    await _refreshStatus();
    if (!ready && _wasSignedIn && !_auth.isLoggedIn) _wasSignedIn = false;
  }

  /// Turn alerts on for this device (call from a tap).
  Future<void> enable() async {
    if (_service == null || _busy) return;
    _busy = true;
    notifyListeners();
    _status = await _service.enable();
    _busy = false;
    notifyListeners();
  }

  /// Tapping an alert on Android / iOS opens the right screen.
  void _listenForTaps(GoRouter router) {
    void open(RemoteMessage m) {
      final path = (m.data['path'] as String?)?.replaceFirst('/#', '');
      if (path != null && path.startsWith('/')) router.go(path);
    }

    try {
      FirebaseMessaging.onMessageOpenedApp.listen(open);
      FirebaseMessaging.instance.getInitialMessage().then((m) {
        if (m != null) open(m);
      });
    } catch (e) {
      debugPrint('Push tap handling unavailable: $e');
    }
  }

  @override
  void dispose() {
    _auth.removeListener(_onAuthChanged);
    super.dispose();
  }
}
