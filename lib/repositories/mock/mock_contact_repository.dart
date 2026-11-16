import '../../models/contact.dart';
import '../contact_repository.dart';
import 'mock_backend.dart';

class MockContactRepository implements ContactRepository {
  MockContactRepository(this._backend);

  final MockBackend _backend;

  @override
  List<Contact> getFor(String userId) {
    final list = _backend.contacts
        .where((c) => c.shared || c.ownerId == userId)
        .toList();
    list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return list;
  }

  @override
  Contact? getById(String id) {
    for (final c in _backend.contacts) {
      if (c.id == id) return c;
    }
    return null;
  }

  @override
  Contact add({
    required String ownerId,
    required String name,
    String phone = '',
    String address = '',
    String notes = '',
    required bool shared,
  }) {
    final contact = Contact(
      id: _backend.newId(),
      ownerId: ownerId,
      name: name,
      phone: phone,
      address: address,
      notes: notes,
      shared: shared,
    );
    _backend.contacts.add(contact);
    _backend.contactChanges.add(null);
    return contact;
  }

  @override
  void update(
    String contactId,
    String requestingUserId, {
    required String name,
    required String phone,
    required String address,
    required String notes,
    required bool shared,
  }) {
    final c = getById(contactId);
    if (c == null || c.ownerId != requestingUserId) return;
    c.name = name;
    c.phone = phone;
    c.address = address;
    c.notes = notes;
    c.shared = shared;
    _backend.contactChanges.add(null);
  }

  @override
  void delete(String contactId, String requestingUserId) {
    final c = getById(contactId);
    if (c == null) return;
    final requester = _backend.userById(requestingUserId);
    final allowed =
        c.ownerId == requestingUserId ||
        (c.shared && (requester?.isAdmin ?? false));
    if (!allowed) return;
    _backend.contacts.removeWhere((x) => x.id == contactId);
    _backend.contactChanges.add(null);
  }

  @override
  Stream<void> get changes => _backend.contactChanges.stream;
}
