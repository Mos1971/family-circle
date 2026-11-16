import 'package:flutter_test/flutter_test.dart';

import 'package:family_circle/repositories/mock/mock_backend.dart';
import 'package:family_circle/repositories/mock/mock_contact_repository.dart';

void main() {
  late MockBackend backend;
  late MockContactRepository repo;

  setUp(() {
    backend = MockBackend();
    repo = MockContactRepository(backend);
  });

  test('private contacts are only visible to their owner', () {
    repo.add(ownerId: 'a', name: 'Dr Smith', phone: '0123', shared: false);
    expect(repo.getFor('a'), hasLength(1));
    expect(repo.getFor('b'), isEmpty);
  });

  test('shared contacts are visible to everyone, sorted by name', () {
    repo.add(ownerId: 'a', name: 'zoe', shared: true);
    repo.add(ownerId: 'a', name: 'Adam', address: '1 High St', shared: true);
    expect(repo.getFor('b').map((c) => c.name), ['Adam', 'zoe']);
  });

  test('only the owner can edit; notes and address are saved', () {
    final c = repo.add(ownerId: 'a', name: 'Plumber', shared: true);
    repo.update(
      c.id,
      'b',
      name: 'Hacked',
      phone: '',
      address: '',
      notes: '',
      shared: true,
    );
    expect(repo.getById(c.id)!.name, 'Plumber');

    repo.update(
      c.id,
      'a',
      name: 'Plumber',
      phone: '07700 900123',
      address: '2 Mill Lane',
      notes: 'Call after 5pm',
      shared: false,
    );
    final saved = repo.getById(c.id)!;
    expect(saved.phone, '07700 900123');
    expect(saved.address, '2 Mill Lane');
    expect(saved.notes, 'Call after 5pm');
    expect(saved.shared, isFalse);
  });

  test('only the owner (or an admin for shared) can delete', () {
    final c = repo.add(ownerId: 'a', name: 'Vet', shared: false);
    repo.delete(c.id, 'b');
    expect(repo.getById(c.id), isNotNull);
    repo.delete(c.id, 'a');
    expect(repo.getById(c.id), isNull);
  });
}
