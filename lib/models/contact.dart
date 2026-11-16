/// An entry in the family address book. Private to its [ownerId] unless the
/// owner chooses to [shared] it with the whole family circle.
class Contact {
  Contact({
    required this.id,
    required this.ownerId,
    required this.name,
    this.phone = '',
    this.address = '',
    this.notes = '',
    this.shared = false,
  });

  final String id;
  final String ownerId;
  String name;
  String phone;
  String address;
  String notes;
  bool shared;
}
