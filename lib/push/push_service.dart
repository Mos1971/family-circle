import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

enum PushStatus {
  /// This browser / device can't receive push alerts.
  unsupported,

  /// The person hasn't been asked yet.
  notAsked,

  /// They said no (it can be switched back on in the device's settings).
  denied,

  /// Alerts are on and this device is registered.
  enabled,
}

/// Registers this device for push alerts.
///
/// Each device saves its push token to `users/{uid}/devices/{token}`. A Cloud
/// Function (see `functions/index.js`) sends an alert to every saved device
/// whenever an in-app notification is created for that person.
class PushService {
  PushService(this._db, this._auth);

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  FirebaseMessaging get _fcm => FirebaseMessaging.instance;

  StreamSubscription<String>? _refreshSub;
  String? _token;

  Future<PushStatus> status() async {
    try {
      if (!await _fcm.isSupported()) return PushStatus.unsupported;
      final settings = await _fcm.getNotificationSettings();
      final s = settings.authorizationStatus;
      if (s == AuthorizationStatus.authorized ||
          s == AuthorizationStatus.provisional) {
        return PushStatus.enabled;
      }
      if (s == AuthorizationStatus.notDetermined) return PushStatus.notAsked;
      return PushStatus.denied; // denied (or denied for good)
    } catch (e) {
      debugPrint('Push status unavailable: $e');
      return PushStatus.unsupported;
    }
  }

  /// Asks permission (must follow a tap on the web) and registers the device.
  Future<PushStatus> enable() async {
    try {
      await _fcm.requestPermission();
      if (await status() == PushStatus.enabled) await _saveToken();
    } catch (e) {
      debugPrint('Enabling push failed: $e');
    }
    return status();
  }

  /// Re-registers quietly when permission was already given earlier.
  Future<void> syncIfEnabled() async {
    try {
      if (await status() == PushStatus.enabled) await _saveToken();
    } catch (e) {
      debugPrint('Push sync failed: $e');
    }
  }

  Future<void> _saveToken() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    final token = await _fcm.getToken();
    if (token == null) return;
    _token = token;
    await _db.collection('users').doc(uid).collection('devices').doc(token).set(
      {
        'platform': kIsWeb ? 'web' : defaultTargetPlatform.name,
        'updatedAt': Timestamp.now(),
      },
    );
    _refreshSub ??= _fcm.onTokenRefresh.listen((fresh) async {
      final id = _auth.currentUser?.uid;
      if (id == null) return;
      final devices = _db.collection('users').doc(id).collection('devices');
      final old = _token;
      _token = fresh;
      if (old != null && old != fresh) await devices.doc(old).delete();
      await devices.doc(fresh).set({
        'platform': kIsWeb ? 'web' : defaultTargetPlatform.name,
        'updatedAt': Timestamp.now(),
      });
    });
  }

  /// Stops alerts going to this device (called when the person logs out).
  Future<void> unregister() async {
    try {
      final uid = _auth.currentUser?.uid;
      final token = _token ?? await _fcm.getToken();
      if (uid != null && token != null) {
        await _db
            .collection('users')
            .doc(uid)
            .collection('devices')
            .doc(token)
            .delete();
      }
      await _refreshSub?.cancel();
      _refreshSub = null;
      _token = null;
      await _fcm.deleteToken();
    } catch (e) {
      debugPrint('Push unregister failed: $e');
    }
  }
}
