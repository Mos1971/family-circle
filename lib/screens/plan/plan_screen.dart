import 'package:flutter/material.dart';

import 'calendar_view.dart';
import 'lists_view.dart';

/// "Plan" tab: the shared/private calendar and the to-do lists.
///
/// [initialTab] is 0 for Calendar and 1 for Lists. Shortcuts such as
/// "/plan?tab=lists" change it while this screen is already alive, so it
/// follows changes instead of only reading it once.
class PlanScreen extends StatefulWidget {
  const PlanScreen({super.key, this.initialTab = 0, this.nonce});

  final int initialTab;

  /// Changes on every shortcut tap, so tapping the same shortcut again still
  /// switches tab after the person has moved to the other one by hand.
  final String? nonce;

  @override
  State<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends State<PlanScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 1),
    );
  }

  @override
  void didUpdateWidget(PlanScreen old) {
    super.didUpdateWidget(old);
    final target = widget.initialTab.clamp(0, 1);
    final requested = target != old.initialTab || widget.nonce != old.nonce;
    if (requested && target != _controller.index) {
      _controller.animateTo(target);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plan'),
        bottom: TabBar(
          controller: _controller,
          tabs: const [
            Tab(text: 'Calendar'),
            Tab(text: 'Lists'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _controller,
        children: const [CalendarView(), ListsView()],
      ),
    );
  }
}
