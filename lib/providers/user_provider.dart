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

  List<AppUser> getAll() => _repo.getAll();
  AppUser? getById(String id) => _repo.getById(id);
  List<AppUser> getPendingApproval() => _repo.getPendingApproval();
  void approve(String userId) => _repo.approve(userId);
  void reject(String userId) => _repo.reject(userId);
  void remove(String userId) => _repo.remove(userId);
  void updateProfile(String userId, {String? bio}) =>
      _repo.updateProfile(userId, bio: bio);

  List<AppUser> getAdmins() => _repo.getAdmins();
  bool promoteToAdmin(String userId) => _repo.promoteToAdmin(userId);
  void demoteToMember(String userId) => _repo.demoteToMember(userId);
}
