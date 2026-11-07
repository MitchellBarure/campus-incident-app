import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../models/app_user.dart';
import '../../models/incident.dart';
import '../../models/incident_status.dart';
import '../../providers/incident_providers.dart';
import '../../widgets/app_button.dart';

/// Opens the bottom sheet where staff pick a new status and add a note.
Future<void> showUpdateStatusSheet(
  BuildContext context, {
  required Incident incident,
  required AppUser staff,
}) {
  return showModalBottomSheet<void>(
    context: context,
    // Lets the sheet move up above the keyboard when typing a note.
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => UpdateStatusSheet(incident: incident, staff: staff),
  );
}

class UpdateStatusSheet extends ConsumerStatefulWidget {
  const UpdateStatusSheet({
    super.key,
    required this.incident,
    required this.staff,
  });

  final Incident incident;
  final AppUser staff;

  @override
  ConsumerState<UpdateStatusSheet> createState() => _UpdateStatusSheetState();
}

class _UpdateStatusSheetState extends ConsumerState<UpdateStatusSheet> {
  static const _maxNoteLength = 300;

  final _noteController = TextEditingController();
  late IncidentStatus _selected = widget.incident.status.suggestedNext;
  bool _isSaving = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    // Grab these before the await, while the sheet is still on screen.
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      await ref.read(incidentRepositoryProvider).updateStatus(
            incidentId: widget.incident.id,
            newStatus: _selected,
            changedBy: widget.staff,
            note: _noteController.text,
          );
      navigator.pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text('Status updated to ${_selected.label}'),
          backgroundColor: AppColors.resolved,
        ),
      );
    } catch (_) {
      if (mounted) setState(() => _isSaving = false);
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Could not update the status. Please try again.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    // Staff can choose any status except the one it already has.
    final options = IncidentStatus.values
        .where((status) => status != widget.incident.status)
        .toList();

    return Padding(
      // Push the sheet up by the keyboard's height.
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Update Status',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Currently: ${widget.incident.status.label}',
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            for (final status in options)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _StatusOption(
                  status: status,
                  isSelected: status == _selected,
                  onTap: _isSaving
                      ? null
                      : () => setState(() => _selected = status),
                ),
              ),
            const SizedBox(height: 8),
            TextField(
              controller: _noteController,
              enabled: !_isSaving,
              maxLines: 3,
              maxLength: _maxNoteLength,
              decoration: const InputDecoration(
                labelText: 'Note (optional)',
                hintText: 'e.g. Plumber booked for Friday morning',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 8),
            AppButton(
              label: 'Save',
              icon: Icons.check,
              isLoading: _isSaving,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}

/// One selectable status, shown in its own colour.
class _StatusOption extends StatelessWidget {
  const _StatusOption({
    required this.status,
    required this.isSelected,
    required this.onTap,
  });

  final IncidentStatus status;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isSelected,
      child: Material(
        color: isSelected ? status.backgroundColor : AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isSelected ? status.color : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(
                  isSelected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: isSelected ? status.color : AppColors.textSecondary,
                ),
                const SizedBox(width: 12),
                Text(
                  status.label,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isSelected ? status.color : AppColors.textPrimary,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
