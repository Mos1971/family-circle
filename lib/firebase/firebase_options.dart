import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Connection settings for the `family-circle-mos71` Firebase project, one
/// per platform. These values are public identifiers, not secrets — access is
/// controlled by the Firestore/Auth security rules in `firestore.rules`.
FirebaseOptions get firebaseOptions {
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    return _android;
  }
  return _web;
}

const _web = FirebaseOptions(
  apiKey: 'AIzaSyDorIcn3yU5VqTXazzVnFDx1E0n7OxyIuo',
  appId: '1:926394248212:web:719bb450ce99f89321cb01',
  messagingSenderId: '926394248212',
  projectId: 'family-circle-mos71',
  authDomain: 'family-circle-mos71.firebaseapp.com',
  storageBucket: 'family-circle-mos71.firebasestorage.app',
);

const _android = FirebaseOptions(
  apiKey: 'AIzaSyCojdk_heYNDLk7xf_Ney3SB01RS4IZG3M',
  appId: '1:926394248212:android:f9cc41792b25ee5821cb01',
  messagingSenderId: '926394248212',
  projectId: 'family-circle-mos71',
  storageBucket: 'family-circle-mos71.firebasestorage.app',
);
