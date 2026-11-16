import '../models/contact.dart';

abstract class ContactRepository {
  /// Contacts [userId] can see: their own plus everything shared with the
  /// family, sorted by name.
  List<Contact> getFor(String userId);

  Contact? getById(String id);

  Contact add({
    required String ownerId,
    required String name,
    String phone = '',
    String address = '',
    String notes = '',
    required bool shared,
  });

  /// Only the owner may change a contact.
  void update(
    String contactId,
    String requestingUserId, {
    required String name,
    required String phone,
    required String address,
    required String notes,
    required bool shared,
  });

  /// Only the owner (or an admin, for shared contacts) may delete.
  void delete(String contactId, String requestingUserId);

  Stream<void> get changes;
}
