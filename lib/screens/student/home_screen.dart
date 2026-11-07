import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/incident_filters.dart';
import '../../models/incident.dart';
import '../../providers/auth_providers.dart';
import '../../providers/incident_providers.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_view.dart';
import '../../widgets/incident_card.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/summary_card.dart';

/// How many reports to show under "Recent Reports".
const _recentCount = 3;

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentUserProfileProvider).value;
    final myIncidents = ref.watch(myIncidentsProvider);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
          children: [
            _Greeting(name: profile?.name ?? ''),
            const SizedBox(height: 20),
            const _ReportBanner(),
            const SizedBox(height: 24),
            // One AsyncValue drives both the summary and the recent list.
            ...myIncidents.when(
              loading: () => [
                const SizedBox(height: 160, child: LoadingView()),
              ],
              error: (error, _) => [
                ErrorView(
                  message: 'Could not load your reports.',
                  error: error,
                  onRetry: () => ref.invalidate(myIncidentsProvider),
                ),
              ],
              data: (incidents) => _buildContent(context, incidents),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildContent(BuildContext context, List<Incident> incidents) {
    return [
      const _SectionTitle(title: 'Report Summary'),
      const SizedBox(height: 12),
      SummaryGrid(
        counts: IncidentCounts.from(incidents),
        totalLabel: 'My Reports',
      ),
      const SizedBox(height: 24),
      _SectionTitle(
        title: 'Recent Reports',
        actionLabel: incidents.isEmpty ? null : 'See all',
        onAction: () => context.go(AppRoutes.myReports),
      ),
      const SizedBox(height: 12),
      if (incidents.isEmpty)
        const EmptyState(
          icon: Icons.inbox_outlined,
          title: 'No reports yet',
          message: 'Issues you report will show up here so you can '
              'follow their progress.',
        )
      else
        for (final incident in incidents.take(_recentCount))
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: IncidentCard(
              incident: incident,
              onTap: () =>
                  context.push(AppRoutes.incidentDetails(incident.id)),
            ),
          ),
    ];
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hello, ${Formatters.firstName(name)}',
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                "Let's keep our campus in great shape.",
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        InkWell(
          customBorder: const CircleBorder(),
          onTap: () => context.go(AppRoutes.profile),
          child: CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.primary,
            child: Text(
              name.isEmpty ? '?' : name[0].toUpperCase(),
              style: textTheme.titleMedium?.copyWith(
                color: AppColors.surface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// The navy hero banner with the "Report an Issue" button.
class _ReportBanner extends StatelessWidget {
  const _ReportBanner();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'See an issue on campus?',
                  style: textTheme.titleMedium?.copyWith(
                    color: AppColors.surface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Report it in under a minute and track it until '
                  "it's fixed.",
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.primaryLight,
                  ),
                ),
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: () => context.push(AppRoutes.reportIncident),
                  icon: const Icon(Icons.add_circle_outline, size: 20),
                  label: const Text('Report an Issue'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.surface,
                    foregroundColor: AppColors.primary,
                    minimumSize: const Size(0, 44),
                    textStyle: textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.campaign_outlined,
            size: 72,
            color: AppColors.surface.withValues(alpha: 0.25),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.actionLabel, this.onAction});

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        if (actionLabel != null)
          TextButton(onPressed: onAction, child: Text(actionLabel!)),
      ],
    );
  }
}
