import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/validators.dart';
import '../../models/incident_category.dart';
import '../../providers/auth_providers.dart';
import '../../providers/incident_providers.dart';
import '../../services/image_service.dart';
import '../../services/incident_repository.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/category_selector.dart';
import '../../widgets/photo_picker_field.dart';

class ReportIncidentScreen extends ConsumerStatefulWidget {
  const ReportIncidentScreen({super.key});

  @override
  ConsumerState<ReportIncidentScreen> createState() =>
      _ReportIncidentScreenState();
}

class _ReportIncidentScreenState extends ConsumerState<ReportIncidentScreen> {
  final _formKey = GlobalKey<FormState>();

  /// Errors are only checked when the user taps Submit at first. After
  /// that, each field re-checks as it is edited, so an error disappears
  /// as soon as it is fixed.
  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();

  IncidentCategory? _category;
  CompressedImage? _image;

  /// True after a submit attempt with no category, to show the error.
  bool _showCategoryError = false;
  bool _isProcessingPhoto = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto(ImageSource source) async {
    setState(() => _isProcessingPhoto = true);
    try {
      final image = await ref.read(imageServiceProvider).pickImage(source);
      // image is null if the user closed the camera/gallery without picking.
      if (image != null && mounted) {
        setState(() => _image = image);
      }
    } on ImageProcessingException catch (e) {
      _showSnackBar(e.message, isError: true);
    } catch (_) {
      // e.g. the user denied camera permission.
      _showSnackBar('Could not open the camera or gallery.', isError: true);
    } finally {
      if (mounted) setState(() => _isProcessingPhoto = false);
    }
  }

  Future<void> _submit() async {
    setState(() => _autovalidateMode = AutovalidateMode.onUserInteraction);
    // Validate both the text fields and the category, so every problem
    // is shown at once rather than one at a time.
    final fieldsAreValid = _formKey.currentState!.validate();
    setState(() => _showCategoryError = _category == null);
    if (!fieldsAreValid || _category == null) return;

    final reporter = ref.read(currentUserProfileProvider).value;
    if (reporter == null) {
      _showSnackBar(
        'Please wait, your profile is still loading.',
        isError: true,
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await ref
          .read(incidentRepositoryProvider)
          .createIncident(
            title: _titleController.text,
            description: _descriptionController.text,
            category: _category!,
            location: _locationController.text,
            reporter: reporter,
            image: _image,
          );
      _showSnackBar('Report submitted. Thank you!');
      _close();
    } on PhotoUploadFailure catch (e) {
      // The report itself was saved, so we still leave the screen.
      _showSnackBar(e.toString(), isError: true);
      _close();
    } catch (_) {
      _showSnackBar(
        'Could not submit your report. Check your connection and try again.',
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  /// Goes back to wherever the user opened this screen from.
  void _close() {
    if (!mounted) return;
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.home);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    // The messenger belongs to the whole app, so the message stays
    // visible even after this screen closes.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.resolved,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Watching keeps the profile loaded, so it is ready when we submit.
    ref.watch(currentUserProfileProvider);
    final isBusy = _isSubmitting || _isProcessingPhoto;

    return Scaffold(
      appBar: AppBar(title: const Text('Report an Issue')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          autovalidateMode: _autovalidateMode,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const _SectionLabel('Category'),
              const SizedBox(height: 8),
              CategorySelector(
                selected: _category,
                errorText: _showCategoryError
                    ? 'Please choose a category'
                    : null,
                onSelected: (category) => setState(() {
                  _category = category;
                  _showCategoryError = false;
                }),
              ),
              const SizedBox(height: 20),
              AppTextField(
                controller: _titleController,
                label: 'Title',
                hint: 'e.g. Leaking tap in washroom',
                textInputAction: TextInputAction.next,
                validator: Validators.incidentTitle,
                enabled: !_isSubmitting,
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _descriptionController,
                label: 'Description',
                hint: 'What is wrong? Since when?',
                maxLines: 4,
                keyboardType: TextInputType.multiline,
                validator: Validators.description,
                enabled: !_isSubmitting,
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _locationController,
                label: 'Location',
                hint: 'e.g. Block B - Room 204',
                icon: Icons.location_on_outlined,
                textInputAction: TextInputAction.done,
                validator: Validators.location,
                enabled: !_isSubmitting,
              ),
              const SizedBox(height: 20),
              const _SectionLabel('Photo'),
              const SizedBox(height: 8),
              PhotoPickerField(
                imageBytes: _image?.fullBytes,
                isProcessing: _isProcessingPhoto,
                onPick: _isSubmitting ? (_) {} : _pickPhoto,
                onRemove: () => setState(() => _image = null),
              ),
              const SizedBox(height: 28),
              AppButton(
                label: 'Submit Report',
                icon: Icons.send_outlined,
                isLoading: _isSubmitting,
                // Disabled while a photo is still being prepared.
                onPressed: isBusy ? null : _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.labelLarge
          ?.copyWith(fontWeight: FontWeight.w600),
    );
  }
}
