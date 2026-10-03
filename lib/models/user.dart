enum MemberRole { member, admin }

enum MemberStatus { pending, approved, rejected }

/// Family Circle is run by a small central admin team — capped so admin
/// access stays deliberate.
const int kMaxAdmins = 3;

class AppUser {
  AppUser({
    required this.id,
    required this.firstName,
    required this.email,
    this.familyName = '',
    this.bio = '',
    this.role = MemberRole.member,
    this.status = MemberStatus.pending,
    required this.joinDate,
    this.postCount = 0,
    this.profileEmoji = '🏡',
  });

  final String id;
  final String firstName;
  final String email;

  /// The family this person belongs to, e.g. "The Okafors".
  final String familyName;
  String bio;
  MemberRole role;
  MemberStatus status;
  final DateTime joinDate;
  int postCount;
  final String profileEmoji;

  bool get isAdmin => role == MemberRole.admin;
  bool get isApproved => status == MemberStatus.approved;
}
