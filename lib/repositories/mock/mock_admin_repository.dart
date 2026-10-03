import '../../models/user.dart';
import '../admin_repository.dart';
import 'mock_backend.dart';

class MockAdminRepository implements AdminRepository {
  MockAdminRepository(this._backend);

  final MockBackend _backend;

  @override
  FamilyStats getStats() {
    return FamilyStats(
      approvedMemberCount: _backend.users
          .where((u) => u.status == MemberStatus.approved)
          .length,
      pendingMemberCount: _backend.users
          .where((u) => u.status == MemberStatus.pending)
          .length,
      postCount: _backend.posts.where((p) => !p.hidden).length,
      openReportCount: _backend.reports.where((r) => !r.resolved).length,
    );
  }
}
