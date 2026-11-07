import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/incident_filters.dart';
import '../../providers/auth_providers.dart';
import '../../providers/incident_providers.dart';
import '../../widgets/filtered_incident_list.dart';
import '../../widgets/incident_filter_bar.dart';
import '../../widgets/summary_card.dart';

/// Staff home: status counts and every incident, with search and filters.
class StaffDashboardScreen extends ConsumerWidget {
  const StaffDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentUserProfileProvider).value;
    // The counts use every incident, not the filtered list.
    final allIncidents = ref.watch(allIncidentsProvider).value;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff Dashboard'),
        actions: [
          IconButton(
            tooltip: 'Profile',
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: () => context.push(AppRoutes.staffProfile),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text(
            'Hello, ${Formatters.firstName(profile?.name ?? '')}',
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Review and resolve campus issues.',
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          // The list below shows the loading/error state.
          if (allIncidents != null) ...[
            SummaryGrid(
              counts: IncidentCounts.from(allIncidents),
              totalLabel: 'All Reports',
            ),
            const SizedBox(height: 24),
          ],
          Text(
            'All Reports',
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          const IncidentFilterBar(),
          const SizedBox(height: 16),
          ...buildFilteredIncidentList(context, ref),
        ],
      ),
    );
  }
}
