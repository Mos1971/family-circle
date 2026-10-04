import '../models/circle.dart';
import '../models/user.dart';

abstract class UserRepository {
  /// The signed-in member's circle (name + invite code), once loaded.
  Circle? get circle;

  List<AppUser> getAll();
  AppUser? getById(String id);
  List<AppUser> getPendingApproval();
  void approve(String userId);
  void reject(String userId);
  void remove(String userId);
  void updateProfile(String userId, {String? bio});

  List<AppUser> getAdmins();

  /// Promotes an approved member to admin. Returns false without making a
  /// change if the [kMaxAdmins] cap is already reached.
  bool promoteToAdmin(String userId);

  /// Demotes an admin back to a regular member. No-ops if this would leave
  /// zero admins — there must always be at least one.
  void demoteToMember(String userId);

  Stream<void> get changes;
}
