import 'package:flutter/foundation.dart';

import '../models/contact.dart';
import '../repositories/contact_repository.dart';

class ContactProvider extends ChangeNotifier {
  ContactProvider(this._repo) {
    _repo.changes.listen((_) => notifyListeners());
  }

  final ContactRepository _repo;

  List<Contact> getFor(String userId) => _repo.getFor(userId);
  Contact? getById(String id) => _repo.getById(id);

  Contact add({
    required String ownerId,
    required String name,
    String phone = '',
    String address = '',
    String notes = '',
    required bool shared,
  }) => _repo.add(
    ownerId: ownerId,
    name: name,
    phone: phone,
    address: address,
    notes: notes,
    shared: shared,
  );

  void update(
    String contactId,
    String userId, {
    required String name,
    required String phone,
    required String address,
    required String notes,
    required bool shared,
  }) => _repo.update(
    contactId,
    userId,
    name: name,
    phone: phone,
    address: address,
    notes: notes,
    shared: shared,
  );

  void delete(String contactId, String userId) =>
      _repo.delete(contactId, userId);
}
