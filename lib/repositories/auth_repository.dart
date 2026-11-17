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

  /// Permanently deletes the signed-in person's account and everything they
  /// created, in every circle they belong to. [password] re-confirms identity.
  /// Throws an [Exception] with a readable message if it can't be done.
  Future<void> deleteAccount({required String password});

  /// Emails a link for choosing a new password.
  Future<void> sendPasswordReset(String email);

  /// Convenience for demoing the app quickly without typing credentials.
  Future<AppUser> loginAsDemo(String userId);
}
