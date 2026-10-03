enum ReportedContentType { post, comment }

class ContentReport {
  ContentReport({
    required this.id,
    required this.contentType,
    required this.contentId,
    required this.reporterId,
    required this.createdAt,
    this.resolved = false,
  });

  final String id;
  final ReportedContentType contentType;
  final String contentId;
  final String reporterId;
  final DateTime createdAt;
  bool resolved;
}
