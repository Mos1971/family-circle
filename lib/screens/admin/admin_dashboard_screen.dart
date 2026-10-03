import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/report.dart';
import '../../models/user.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/feed_provider.dart';
import '../../providers/user_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/time_format.dart';
import '../../widgets/member_avatar.dart';
import '../../widgets/section_header.dart';
import '../announcements/announcement_editor.dart';
import 'promote_admin_dialog.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final users = context.watch<UserProvider>();
    final feed = context.watch<FeedProvider>();
    final me = context.watch<AuthProvider>().currentUser;
    final stats = admin.getStats();
    final pending = users.getPendingApproval();
    final reports = feed.getOpenReports();
    final admins = users.getAdmins();
    final members = users
        .getAll()
        .where((u) => u.isApproved && !u.isAdmin)
        .toList();

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.pop()),
        title: const Text('Admin Dashboard'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.8,
            children: [
              _StatCard(label: 'Members', value: '${stats.approvedMemberCount}'),
              _StatCard(
                label: 'Pending approval',
                value: '${stats.pendingMemberCount}',
                highlight: stats.pendingMemberCount > 0,
              ),
              _StatCard(label: 'Posts', value: '${stats.postCount}'),
              _StatCard(
                label: 'Open reports',
                value: '${stats.openReportCount}',
                highlight: stats.openReportCount > 0,
              ),
            ],
          ),
          const SizedBox(height: 24),
          SectionHeader(title: 'Pending members (${pending.length})'),
          if (pending.isEmpty)
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text('No pending requests.', style: TextStyle(color: AppColors.muted)),
            )
          else
            ...pending.map((u) => Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: MemberAvatar(user: u, radius: 18),
                    title: Text(u.firstName),
                    subtitle: Text(u.email, style: const TextStyle(fontSize: 12)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.check_circle, color: AppColors.success),
                          onPressed: () => users.approve(u.id),
                        ),
                        IconButton(
                          icon: const Icon(Icons.cancel, color: AppColors.danger),
                          onPressed: () => users.reject(u.id),
                        ),
                      ],
                    ),
                  ),
                )),
          const SizedBox(height: 20),
          SectionHeader(title: 'Reported content (${reports.length})'),
          if (reports.isEmpty)
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text('Nothing to review right now.', style: TextStyle(color: AppColors.muted)),
            )
          else
            ...reports.map((r) => _ReportTile(report: r)),
          const SizedBox(height: 20),
          SectionHeader(
            title: 'Admins (${admins.length}/$kMaxAdmins)',
            actionLabel: admins.length < kMaxAdmins ? 'Add admin' : null,
            onAction: admins.length < kMaxAdmins
                ? () => showPromoteAdminDialog(context)
                : null,
          ),
          if (admins.length >= kMaxAdmins)
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text(
                'Maximum of 3 admins reached — remove one to add another.',
                style: TextStyle(fontSize: 12, color: AppColors.muted),
              ),
            ),
          ...admins.map((u) => Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: MemberAvatar(user: u, radius: 18),
                  title: Text(u.id == me?.id ? '${u.firstName} (You)' : u.firstName),
                  subtitle: Text(u.email, style: const TextStyle(fontSize: 12)),
                  trailing: admins.length > 1
                      ? IconButton(
                          icon: const Icon(
                            Icons.remove_circle_outline,
                            color: AppColors.gold,
                          ),
                          tooltip: 'Remove admin access',
                          onPressed: () => users.demoteToMember(u.id),
                        )
                      : null,
                ),
              )),
          const SizedBox(height: 20),
          SectionHeader(title: 'Manage the circle'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Text('📢', style: TextStyle(fontSize: 20)),
                  title: const Text('New announcement'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => showAnnouncementEditor(context),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.dynamic_feed_outlined),
                  title: const Text('View family feed'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.go('/feed'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SectionHeader(title: 'Members (${members.length})'),
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text(
              'Remove a member to end their access to the feed and to '
              'private messaging.',
              style: TextStyle(fontSize: 12, color: AppColors.muted),
            ),
          ),
          ...members.map(
            (u) => Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: MemberAvatar(user: u, radius: 18),
                title: Text(u.firstName),
                subtitle: Text(
                  u.familyName.isEmpty ? u.email : '${u.familyName} · ${u.email}',
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: IconButton(
                  icon: const Icon(
                    Icons.person_remove_outlined,
                    color: AppColors.danger,
                  ),
                  tooltip: 'Remove member',
                  onPressed: () => _confirmRemove(context, u),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value, this.highlight = false});

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: highlight ? AppColors.gold.withValues(alpha: 0.1) : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: highlight ? AppColors.gold : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
        ],
      ),
    );
  }
}

class _ReportTile extends StatelessWidget {
  const _ReportTile({required this.report});

  final ContentReport report;

  @override
  Widget build(BuildContext context) {
    final feed = context.read<FeedProvider>();
    final label = report.contentType == ReportedContentType.post ? 'Post' : 'Comment';
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$label reported', style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(
                    'Reported ${timeAgo(report.createdAt)}',
                    style: const TextStyle(fontSize: 12, color: AppColors.muted),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () => feed.resolveReport(report.id, removeContent: false),
              child: const Text('Dismiss'),
            ),
            ElevatedButton(
              onPressed: () => feed.resolveReport(report.id, removeContent: true),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger, foregroundColor: Colors.white),
              child: const Text('Remove'),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _confirmRemove(BuildContext context, AppUser user) async {
  final users = context.read<UserProvider>();
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('Remove ${user.firstName}?'),
      content: const Text(
        'They will lose access to Family Circle, including the feed and '
        'private messages.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          style: TextButton.styleFrom(foregroundColor: AppColors.danger),
          child: const Text('Remove'),
        ),
      ],
    ),
  );
  if (ok == true) users.reject(user.id);
}
