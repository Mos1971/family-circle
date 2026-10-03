import '../../models/app_notification.dart';
import '../../models/user.dart';
import '../auth_repository.dart';
import 'mock_backend.dart';

class MockAuthRepository implements AuthRepository {
  MockAuthRepository(this._backend);

  final MockBackend _backend;

  @override
  AppUser? get currentUser => _backend.currentUser;

  @override
  Stream<AppUser?> get authStateChanges => _backend.authChanges.stream;

  @override
  Future<AppUser> register({
    required String firstName,
    required String familyName,
    required String email,
    required String password,
    required String verificationNote,
  }) async {
    final user = AppUser(
      id: _backend.newId(),
      firstName: firstName,
      familyName: familyName,
      email: email,
      status: MemberStatus.pending,
      joinDate: DateTime.now(),
    );
    _backend.users.add(user);
    _backend.currentUserId = user.id;
    _backend.userChanges.add(null);
    _backend.authChanges.add(user);
    _backend.notifyAdmins(
      type: AppNotificationType.community,
      title: 'New member request',
      body: '$firstName has requested to join Family Circle.',
    );
    return user;
  }

  @override
  Future<AppUser> login({required String email, required String password}) async {
    final match = _backend.users
        .where((u) => u.email.toLowerCase() == email.toLowerCase())
        .toList();
    if (match.isEmpty) {
      throw Exception('No account found for $email.');
    }
    _backend.currentUserId = match.first.id;
    _backend.authChanges.add(match.first);
    return match.first;
  }

  @override
  Future<void> logout() async {
    _backend.currentUserId = null;
    _backend.authChanges.add(null);
  }

  @override
  Future<AppUser> loginAsDemo(String userId) async {
    final user = _backend.userById(userId);
    if (user == null) throw Exception('Unknown demo user $userId');
    _backend.currentUserId = user.id;
    _backend.authChanges.add(user);
    return user;
  }
}
