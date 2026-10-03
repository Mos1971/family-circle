import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/user.dart';
import '../repositories/auth_repository.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider(this._repo) {
    _sub = _repo.authStateChanges.listen((_) => notifyListeners());
  }

  final AuthRepository _repo;
  late final StreamSubscription<AppUser?> _sub;

  AppUser? get currentUser => _repo.currentUser;
  bool get isLoggedIn => currentUser != null;
  bool get isPending => currentUser?.status == MemberStatus.pending;
  bool get isApproved => currentUser?.status == MemberStatus.approved;
  bool get isAdmin => currentUser?.isAdmin ?? false;

  String? _error;
  String? get error => _error;

  Future<bool> register({
    required String firstName,
    required String familyName,
    required String email,
    required String password,
    required String verificationNote,
  }) async {
    _error = null;
    try {
      await _repo.register(
        firstName: firstName,
        familyName: familyName,
        email: email,
        password: password,
        verificationNote: verificationNote,
      );
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    _error = null;
    try {
      await _repo.login(email: email, password: password);
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<void> loginAsDemo(String userId) => _repo.loginAsDemo(userId);

  Future<void> logout() => _repo.logout();

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
