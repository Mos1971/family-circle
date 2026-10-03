class FamilyStats {
  const FamilyStats({
    required this.approvedMemberCount,
    required this.pendingMemberCount,
    required this.postCount,
    required this.openReportCount,
  });

  final int approvedMemberCount;
  final int pendingMemberCount;
  final int postCount;
  final int openReportCount;
}

/// Thin aggregation layer over the other repositories for the admin
/// dashboard's stats panel. Member approval and content moderation live on
/// [UserRepository] and [FeedRepository] respectively to avoid duplicating
/// state ownership.
abstract class AdminRepository {
  FamilyStats getStats();
}
