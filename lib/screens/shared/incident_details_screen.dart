import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../models/incident.dart';
import '../../models/incident_status.dart';
import '../../models/status_change.dart';
import '../../providers/auth_providers.dart';
import '../../providers/incident_providers.dart';
import '../../widgets/app_button.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/status_chip.dart';
import '../../widgets/status_timeline.dart';
import '../staff/update_status_sheet.dart';

class IncidentDetailsScreen extends ConsumerWidget {
  const IncidentDetailsScreen({super.key, required this.incidentId});

  final String incidentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incident = ref.watch(incidentByIdProvider(incidentId));
    final profile = ref.watch(currentUserProfileProvider).value;
    final loadedIncident = incident.value;

    // Staff only. The security rules also block students.
    final showUpdateButton =
        profile != null && profile.isStaff && loadedIncident != null;

    // Reporters can edit or delete until staff start on it.
    final canEditOrDelete =
        profile != null &&
        loadedIncident != null &&
        loadedIncident.reporterId == profile.uid &&
        loadedIncident.status == IncidentStatus.submitted;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Details'),
        actions: [
          if (canEditOrDelete) ...[
            IconButton(
              tooltip: 'Edit report',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => context.push(
                AppRoutes.editIncident(loadedIncident.id),
                extra: loadedIncident,
              ),
            ),
            IconButton(
              tooltip: 'Delete report',
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _confirmDelete(context, ref, loadedIncident),
            ),
          ],
        ],
      ),
      bottomNavigationBar: showUpdateButton
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: AppButton(
                  label: 'Update Status',
                  icon: Icons.edit_note,
                  onPressed: () => showUpdateStatusSheet(
                    context,
                    incident: loadedIncident,
                    staff: profile,
                  ),
                ),
              ),
            )
          : null,
      body: incident.when(
        loading: () => const LoadingView(),
        error: (error, _) => ErrorView(
          message: 'Could not load this report.',
          error: error,
          onRetry: () => ref.invalidate(incidentByIdProvider(incidentId)),
        ),
        data: (incident) {
          if (incident == null) {
            return const EmptyState(
              icon: Icons.search_off,
              title: 'Report not found',
              message: 'This report may have been removed.',
            );
          }
          return _DetailsBody(
            incident: incident,
            showEditHint: canEditOrDelete,
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Incident incident,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete this report?'),
        content: const Text(
          'This removes it for everyone and cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    // Read before the await, while this screen is still mounted.
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    try {
      await ref.read(incidentRepositoryProvider).deleteIncident(incident);
      if (router.canPop()) router.pop();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Report deleted.'),
          backgroundColor: AppColors.resolved,
        ),
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Could not delete. Reports can only be deleted while Submitted.',
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}

class _DetailsBody extends StatelessWidget {
  const _DetailsBody({required this.incident, required this.showEditHint});

  final Incident incident;
  final bool showEditHint;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    // Notes written by staff (anyone other than the reporter).
    final staffNotes = incident.statusHistory
        .where(
          (change) =>
              change.note != null && change.changedBy != incident.reporterId,
        )
        .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        if (incident.hasImage) ...[
          _IncidentPhoto(incident: incident),
          const SizedBox(height: 16),
        ],
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                incident.title,
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: StatusChip(status: incident.status),
            ),
          ],
        ),
        if (showEditHint) ...[
          const SizedBox(height: 8),
          Text(
            'You can edit or delete this report until staff start on it.',
            style: textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
        const SizedBox(height: 16),
        _SectionCard(
          child: Column(
            children: [
              _InfoRow(
                icon: incident.category.icon,
                label: 'Category',
                value: incident.category.label,
              ),
              _InfoRow(
                icon: Icons.location_on_outlined,
                label: 'Location',
                value: incident.location,
              ),
              _InfoRow(
                icon: Icons.person_outline,
                label: 'Reported by',
                value: incident.reporterName,
              ),
              _InfoRow(
                icon: Icons.calendar_today_outlined,
                label: 'Reported on',
                value: Formatters.dateTime(incident.createdAt),
              ),
              _InfoRow(
                icon: Icons.update,
                label: 'Last updated',
                value: Formatters.dateTime(incident.updatedAt),
                isLast: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _SectionCard(
          title: 'Description',
          child: Text(incident.description, style: textTheme.bodyMedium),
        ),
        const SizedBox(height: 16),
        _SectionCard(
          title: 'Status Timeline',
          child: StatusTimeline(incident: incident),
        ),
        const SizedBox(height: 16),
        _SectionCard(
          title: 'Staff Notes',
          child: staffNotes.isEmpty
              ? Text(
                  'No notes from staff yet.',
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                )
              : Column(
                  children: [
                    for (final change in staffNotes.reversed)
                      _StaffNote(change: change),
                  ],
                ),
        ),
      ],
    );
  }
}

/// The full photo, showing the thumbnail while it loads.
class _IncidentPhoto extends ConsumerWidget {
  const _IncidentPhoto({required this.incident});

  final Incident incident;

  static const double height = 220;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final image = ref.watch(incidentImageProvider(incident.id));
    final thumbnail = incident.thumbnailBase64;

    final Widget content = image.when(
      data: (bytes) {
        if (bytes == null) return const _PhotoPlaceholder();
        return Image.memory(bytes, fit: BoxFit.cover, gaplessPlayback: true);
      },
      loading: () {
        if (thumbnail == null) return const LoadingView();
        return Image.memory(base64Decode(thumbnail), fit: BoxFit.cover);
      },
      error: (_, _) => _PhotoPlaceholder(
        onRetry: () => ref.invalidate(incidentImageProvider(incident.id)),
      ),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: height,
        width: double.infinity,
        color: AppColors.primaryLight,
        child: content,
      ),
    );
  }
}

class _PhotoPlaceholder extends StatelessWidget {
  const _PhotoPlaceholder({this.onRetry});

  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.broken_image_outlined,
            size: 40,
            color: AppColors.primary,
          ),
          const SizedBox(height: 8),
          const Text('Photo unavailable'),
          if (onRetry != null)
            TextButton(onPressed: onRetry, child: const Text('Try again')),
        ],
      ),
    );
  }
}

/// A white rounded card with an optional heading.
class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child, this.title});

  final String? title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null) ...[
              Text(
                title!,
                style: Theme.of(context).textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
            ],
            child,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isLast = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: textTheme.labelSmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  value,
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StaffNote extends StatelessWidget {
  const _StaffNote({required this.change});

  final StatusChange change;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.sticky_note_2_outlined,
            size: 20,
            color: AppColors.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(change.note!, style: textTheme.bodyMedium),
                const SizedBox(height: 2),
                Text(
                  '${change.changedByName} · ${change.status.label} · '
                  '${Formatters.dateTime(change.at)}',
                  style: textTheme.labelSmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
