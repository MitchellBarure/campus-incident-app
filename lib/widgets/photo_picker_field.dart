import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../core/theme/app_colors.dart';

/// Photo area on the report form. The parent does the picking via [onPick].
class PhotoPickerField extends StatelessWidget {
  const PhotoPickerField({
    super.key,
    required this.imageBytes,
    required this.isProcessing,
    required this.onPick,
    required this.onRemove,
  });

  /// The chosen photo, or null if none yet.
  final Uint8List? imageBytes;

  /// True while the photo is being compressed.
  final bool isProcessing;
  final ValueChanged<ImageSource> onPick;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    if (isProcessing) {
      return const _PhotoBox(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text('Preparing photo...'),
          ],
        ),
      );
    }

    if (imageBytes != null) {
      return _PhotoPreview(bytes: imageBytes!, onRemove: onRemove);
    }

    return _PhotoBox(
      onTap: () => _showSourceSheet(context),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.add_a_photo_outlined,
            size: 32,
            color: AppColors.primary,
          ),
          const SizedBox(height: 8),
          Text(
            'Add a photo (optional)',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// Asks the user whether to use the camera or the gallery.
  void _showSourceSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Take a photo'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  onPick(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Choose from gallery'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  onPick(ImageSource.gallery);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}

class _PhotoBox extends StatelessWidget {
  const _PhotoBox({required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: SizedBox(
          height: 140,
          width: double.infinity,
          child: Center(child: child),
        ),
      ),
    );
  }
}

class _PhotoPreview extends StatelessWidget {
  const _PhotoPreview({required this.bytes, required this.onRemove});

  final Uint8List bytes;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        children: [
          Image.memory(
            bytes,
            height: 200,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
          Positioned(
            top: 8,
            right: 8,
            child: IconButton.filled(
              tooltip: 'Remove photo',
              style: IconButton.styleFrom(
                backgroundColor: AppColors.textPrimary.withValues(alpha: 0.6),
                foregroundColor: AppColors.surface,
              ),
              icon: const Icon(Icons.close),
              onPressed: onRemove,
            ),
          ),
        ],
      ),
    );
  }
}
