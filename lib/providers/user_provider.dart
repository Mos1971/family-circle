import 'package:flutter/foundation.dart';

import '../models/circle.dart';
import '../models/user.dart';
import '../repositories/user_repository.dart';

class UserProvider extends ChangeNotifier {
  UserProvider(this._repo) {
    _repo.changes.listen((_) => notifyListeners());
  }

  final UserRepository _repo;

  Circle? get circle => _repo.circle;
  List<CircleRef> get myCircles => _repo.myCircles;
  void switchCircle(String id) => _repo.switchCircle(id);

  /// Returns null on success, otherwise a readable error message.
  Future<String?> leaveCircle(String id) async {
    try {
      await _repo.leaveCircle(id);
      return null;
    } catch (e) {
      return e.toString().replaceFirst('Exception: ', '');
    }
  }

  Future<void> addCircle({
    required String firstName,
    required String familyName,
    String? inviteCode,
    String? licenseCode,
    String? circleName,
  }) => _repo.addCircle(
    firstName: firstName,
    familyName: familyName,
    inviteCode: inviteCode,
    licenseCode: licenseCode,
    circleName: circleName,
  );

  List<AppUser> getAll() => _repo.getAll();
  AppUser? getById(String id) => _repo.getById(id);
  List<AppUser> getPendingApproval() => _repo.getPendingApproval();
  void approve(String userId) => _repo.approve(userId);
  void reject(String userId) => _repo.reject(userId);
  void restore(String userId) => _repo.restore(userId);
  void remove(String userId) => _repo.remove(userId);
  void updateProfile(String userId, {String? bio, String? profileEmoji}) =>
      _repo.updateProfile(userId, bio: bio, profileEmoji: profileEmoji);

  List<AppUser> getAdmins() => _repo.getAdmins();
  bool promoteToAdmin(String userId) => _repo.promoteToAdmin(userId);
  void demoteToMember(String userId) => _repo.demoteToMember(userId);
}
