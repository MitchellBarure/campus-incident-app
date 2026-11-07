import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/router/app_router.dart';
import '../core/theme/app_colors.dart';
import '../models/incident.dart';
import '../providers/filter_providers.dart';
import '../providers/incident_providers.dart';
import 'empty_state.dart';
import 'error_view.dart';
import 'incident_card.dart';
import 'loading_view.dart';

/// The filtered incidents with loading, error and empty states.
/// Returns widgets, not one widget, so screens can add them to a ListView.
List<Widget> buildFilteredIncidentList(BuildContext context, WidgetRef ref) {
  final filtered = ref.watch(filteredIncidentsProvider);
  final hasFilters = ref.watch(hasActiveFiltersProvider);

  return filtered.when(
    loading: () => [const SizedBox(height: 200, child: LoadingView())],
    error: (error, _) => [
      ErrorView(
        message: 'Could not load reports.',
        error: error,
        onRetry: () => ref.invalidate(allIncidentsProvider),
      ),
    ],
    data: (incidents) => _buildCards(context, ref, incidents, hasFilters),
  );
}

List<Widget> _buildCards(
  BuildContext context,
  WidgetRef ref,
  List<Incident> incidents,
  bool hasFilters,
) {
  if (incidents.isEmpty && hasFilters) {
    return [
      EmptyState(
        icon: Icons.search_off,
        title: 'No matching reports',
        message: 'Try a different search or clear the filters.',
        action: OutlinedButton(
          onPressed: () => clearAllFilters(ref),
          style: OutlinedButton.styleFrom(minimumSize: const Size(160, 44)),
          child: const Text('Clear filters'),
        ),
      ),
    ];
  }
  if (incidents.isEmpty) {
    return const [
      EmptyState(
        icon: Icons.inbox_outlined,
        title: 'No reports yet',
        message: 'Campus issues reported by anyone will show up here.',
      ),
    ];
  }

  final countLabel = incidents.length == 1
      ? '1 report'
      : '${incidents.length} reports';

  return [
    Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        countLabel,
        style: Theme.of(context).textTheme.labelMedium
            ?.copyWith(color: AppColors.textSecondary),
      ),
    ),
    for (final incident in incidents)
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: IncidentCard(
          incident: incident,
          onTap: () => context.push(AppRoutes.incidentDetails(incident.id)),
        ),
      ),
  ];
}
