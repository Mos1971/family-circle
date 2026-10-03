import 'package:flutter/foundation.dart';

import '../repositories/admin_repository.dart';

class AdminProvider extends ChangeNotifier {
  AdminProvider(this._repo);

  final AdminRepository _repo;

  FamilyStats getStats() => _repo.getStats();
}
