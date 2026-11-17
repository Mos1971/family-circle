import 'package:flutter_test/flutter_test.dart';

import 'package:family_circle/repositories/mock/mock_auth_repository.dart';
import 'package:family_circle/repositories/mock/mock_backend.dart';
import 'package:family_circle/repositories/mock/mock_contact_repository.dart';

void main() {
  test('deleting an account removes the person and what they created', () async {
    final backend = MockBackend();
    final auth = MockAuthRepository(backend);
    final contacts = MockContactRepository(backend);

    final user = await auth.register(
      firstName: 'Test',
      familyName: 'Person',
      email: 'test@example.com',
      password: 'secret1',
    );
    contacts.add(ownerId: user.id, name: 'Plumber', shared: true);
    expect(backend.users.any((u) => u.id == user.id), isTrue);

    await auth.deleteAccount(password: 'secret1');

    expect(auth.currentUser, isNull);
    expect(backend.users.any((u) => u.id == user.id), isFalse);
    expect(backend.contacts.where((c) => c.ownerId == user.id), isEmpty);
  });
}
