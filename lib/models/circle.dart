/// A private space (one family / customer). Everything — members, feed,
/// messages, calendar, lists — lives inside exactly one circle and can never
/// be seen from another.
class Circle {
  const Circle({
    required this.id,
    required this.name,
    required this.code,
    required this.ownerId,
  });

  final String id;
  final String name;

  /// Invite code the admin shares so family members can ask to join.
  final String code;
  final String ownerId;
}
