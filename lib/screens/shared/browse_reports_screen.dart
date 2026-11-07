import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../widgets/filtered_incident_list.dart';
import '../../widgets/incident_filter_bar.dart';

/// Every report on campus, with search and filters.
/// No pull-to-refresh: the Firestore stream updates the list live.
class BrowseReportsScreen extends ConsumerWidget {
  const BrowseReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Campus Reports')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        children: [
          const IncidentFilterBar(),
          const SizedBox(height: 16),
          ...buildFilteredIncidentList(context, ref),
        ],
      ),
    );
  }
}
