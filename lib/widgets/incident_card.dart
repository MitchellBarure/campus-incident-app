import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/utils/formatters.dart';
import '../models/incident.dart';
import 'status_chip.dart';

/// One incident in a list. Tapping it calls [onTap].
class IncidentCard extends StatelessWidget {
  const IncidentCard({super.key, required this.incident, required this.onTap});

  final Incident incident;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Thumbnail(incident: incident),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      incident.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _IconText(
                      icon: Icons.location_on_outlined,
                      text: incident.location,
                    ),
                    const SizedBox(height: 2),
                    _IconText(
                      icon: incident.category.icon,
                      text: incident.category.label,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        StatusChip(status: incident.status),
                        const Spacer(),
                        Text(
                          Formatters.shortDate(incident.createdAt),
                          style: textTheme.labelSmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconText extends StatelessWidget {
  const _IconText({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }
}

/// Decoded thumbnails, so rebuilds don't re-decode them (avoids flicker).
final Map<String, Uint8List> _thumbnailCache = {};

Uint8List _decodeThumbnail(String base64Text) {
  return _thumbnailCache.putIfAbsent(
    base64Text,
    () => base64Decode(base64Text),
  );
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.incident});

  final Incident incident;

  static const double size = 72;

  @override
  Widget build(BuildContext context) {
    final thumbnail = incident.thumbnailBase64;

    if (thumbnail != null && thumbnail.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.memory(
          _decodeThumbnail(thumbnail),
          width: size,
          height: size,
          fit: BoxFit.cover,
          gaplessPlayback: true,
        ),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(incident.category.icon, color: AppColors.primary, size: 30),
    );
  }
}
