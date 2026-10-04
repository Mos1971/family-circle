import '../../models/app_notification.dart';
import '../../models/circle.dart';
import '../../models/user.dart';
import '../user_repository.dart';
import 'mock_backend.dart';

class MockUserRepository implements UserRepository {
  MockUserRepository(this._backend);

  final MockBackend _backend;

  @override
  Circle? get circle => const Circle(
    id: 'mock',
    name: 'Family Circle',
    code: 'DEMO2345',
    ownerId: 'u_admin',
  );

  @override
  List<AppUser> getAll() => List.unmodifiable(_backend.users);

  @override
  AppUser? getById(String id) => _backend.userById(id);

  @override
  List<AppUser> getPendingApproval() => _backend.users
      .where((u) => u.status == MemberStatus.pending)
      .toList(growable: false);

  @override
  void approve(String userId) {
    final user = _backend.userById(userId);
    if (user == null) return;
    user.status = MemberStatus.approved;
    _backend.userChanges.add(null);
    _backend.welcomeNewMember(user);
  }

  @override
  void reject(String userId) {
    final user = _backend.userById(userId);
    if (user == null) return;
    user.status = MemberStatus.rejected;
    _backend.userChanges.add(null);
  }

  @override
  void remove(String userId) {
    _backend.users.removeWhere((u) => u.id == userId);
    _backend.userChanges.add(null);
  }

  @override
  void updateProfile(String userId, {String? bio}) {
    final user = _backend.userById(userId);
    if (user == null) return;
    if (bio != null) user.bio = bio;
    _backend.userChanges.add(null);
  }

  @override
  List<AppUser> getAdmins() =>
      _backend.users.where((u) => u.isAdmin).toList(growable: false);

  @override
  bool promoteToAdmin(String userId) {
    final user = _backend.userById(userId);
    if (user == null || user.isAdmin) return false;
    if (getAdmins().length >= kMaxAdmins) return false;

    user.role = MemberRole.admin;
    _backend.userChanges.add(null);
    _backend.notifications.insert(
      0,
      AppNotification(
        id: _backend.newId(),
        userId: user.id,
        type: AppNotificationType.community,
        title: '🛡️ You\'re now a Family Circle admin',
        body:
            'You\'ve been made an admin of Family Circle. You can now '
            'moderate the feed, post announcements and approve new members '
            'from the admin dashboard.',
        createdAt: DateTime.now(),
      ),
    );
    _backend.notificationChanges.add(null);
    return true;
  }

  @override
  void demoteToMember(String userId) {
    final user = _backend.userById(userId);
    if (user == null || !user.isAdmin) return;
    if (getAdmins().length <= 1) return;

    user.role = MemberRole.member;
    _backend.userChanges.add(null);
  }

  @override
  Stream<void> get changes => _backend.userChanges.stream;
}
