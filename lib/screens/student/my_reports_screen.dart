import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/incident_filters.dart';
import '../../models/app_user.dart';
import '../../models/incident.dart';
import '../../models/incident_status.dart';
import '../../providers/auth_providers.dart';
import '../../providers/incident_providers.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_view.dart';
import '../../widgets/incident_card.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/status_filter_chips.dart';

class MyReportsScreen extends ConsumerStatefulWidget {
  const MyReportsScreen({super.key});

  @override
  ConsumerState<MyReportsScreen> createState() => _MyReportsScreenState();
}

class _MyReportsScreenState extends ConsumerState<MyReportsScreen> {
  /// null means "All". This filter only matters on this screen, so a
  /// simple setState is enough (no provider needed).
  IncidentStatus? _statusFilter;

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(currentUserProfileProvider).value;
    final myIncidents = ref.watch(myIncidentsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Reports')),
      body: myIncidents.when(
        loading: () => const LoadingView(),
        error: (error, _) => ErrorView(
          message: 'Could not load your reports.',
          error: error,
          onRetry: () => ref.invalidate(myIncidentsProvider),
        ),
        data: (incidents) => _buildList(profile, incidents),
      ),
    );
  }

  Widget _buildList(AppUser? profile, List<Incident> incidents) {
    final filtered = filterIncidents(incidents, status: _statusFilter);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      children: [
        _ProfileHeader(
          profile: profile,
          counts: IncidentCounts.from(incidents),
        ),
        const SizedBox(height: 20),
        StatusFilterChips(
          selected: _statusFilter,
          onChanged: (status) => setState(() => _statusFilter = status),
        ),
        const SizedBox(height: 12),
        if (filtered.isEmpty)
          _buildEmptyState(hasAnyReports: incidents.isNotEmpty)
        else
          for (final incident in filtered)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: IncidentCard(
                incident: incident,
                onTap: () =>
                    context.push(AppRoutes.incidentDetails(incident.id)),
              ),
            ),
      ],
    );
  }

  Widget _buildEmptyState({required bool hasAnyReports}) {
    if (hasAnyReports) {
      // They have reports, just none with this status.
      return EmptyState(
        icon: Icons.filter_alt_off_outlined,
        title: 'Nothing here',
        message:
            'You have no reports that are '
            '${_statusFilter!.label.toLowerCase()}.',
      );
    }
    return EmptyState(
      icon: Icons.inbox_outlined,
      title: 'No reports yet',
      message: 'When you report an issue it will appear here.',
      action: FilledButton.icon(
        onPressed: () => context.push(AppRoutes.reportIncident),
        icon: const Icon(Icons.add),
        label: const Text('Report an Issue'),
        style: FilledButton.styleFrom(minimumSize: const Size(200, 48)),
      ),
    );
  }
}

/// Avatar, name and three quick stats at the top of My Reports.
class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.profile, required this.counts});

  final AppUser? profile;
  final IncidentCounts counts;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final name = profile?.name ?? '';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: AppColors.primary,
                  child: Text(
                    name.isEmpty ? '?' : name[0].toUpperCase(),
                    style: textTheme.titleLarge?.copyWith(
                      color: AppColors.surface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        profile?.email ?? '',
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _Stat(label: 'Reported', value: counts.total),
                _Stat(
                  label: 'Open',
                  value: counts.submitted + counts.inProgress,
                ),
                _Stat(label: 'Resolved', value: counts.resolved),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Expanded(
      child: Column(
        children: [
          Text(
            '$value',
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          Text(
            label,
            style: textTheme.labelSmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
