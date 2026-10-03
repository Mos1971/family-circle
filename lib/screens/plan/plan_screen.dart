import 'package:flutter/material.dart';

import 'calendar_view.dart';
import 'lists_view.dart';

/// "Plan" tab: the shared/private calendar and the to-do lists.
class PlanScreen extends StatelessWidget {
  const PlanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Plan'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Calendar'),
              Tab(text: 'Lists'),
            ],
          ),
        ),
        body: const TabBarView(children: [CalendarView(), ListsView()]),
      ),
    );
  }
}
