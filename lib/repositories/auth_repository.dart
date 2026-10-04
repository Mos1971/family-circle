import '../models/user.dart';

/// Abstract auth boundary. The mock implementation keeps everything
/// in-memory; a future FirebaseAuthRepository implements the same
/// interface against real Firebase Auth without any UI changes.
abstract class AuthRepository {
  AppUser? get currentUser;

  Stream<AppUser?> get authStateChanges;

  Future<AppUser> register({
    required String firstName,
    required String familyName,
    required String email,
    required String password,
    String? inviteCode,
    String? licenseCode,
    String? circleName,
  });

  Future<AppUser> login({required String email, required String password});

  Future<void> logout();

  /// Convenience for demoing the app quickly without typing credentials.
  Future<AppUser> loginAsDemo(String userId);
}
