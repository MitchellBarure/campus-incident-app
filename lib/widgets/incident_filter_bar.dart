import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_colors.dart';
import '../providers/filter_providers.dart';
import 'category_filter_chips.dart';
import 'status_filter_chips.dart';

/// Search box and filter chips, shared by Browse and the Staff dashboard.
class IncidentFilterBar extends ConsumerStatefulWidget {
  const IncidentFilterBar({super.key});

  @override
  ConsumerState<IncidentFilterBar> createState() => _IncidentFilterBarState();
}

class _IncidentFilterBarState extends ConsumerState<IncidentFilterBar> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    // Keep text typed earlier, e.g. when returning to the tab.
    _searchController = TextEditingController(
      text: ref.read(searchTextProvider),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _clearSearch() {
    _searchController.clear();
    ref.read(searchTextProvider.notifier).set('');
  }

  @override
  Widget build(BuildContext context) {
    // Stay in sync when "Clear filters" empties the search.
    ref.listen(searchTextProvider, (_, text) {
      if (text != _searchController.text) _searchController.text = text;
    });

    final status = ref.watch(statusFilterProvider);
    final category = ref.watch(categoryFilterProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _searchController,
          textInputAction: TextInputAction.search,
          onChanged: (text) => ref.read(searchTextProvider.notifier).set(text),
          decoration: InputDecoration(
            hintText: 'Search title, location, reporter...',
            hintStyle: const TextStyle(color: AppColors.textSecondary),
            prefixIcon: const Icon(
              Icons.search,
              color: AppColors.textSecondary,
            ),
            // Rebuilds so the clear button only shows when there is text.
            suffixIcon: ValueListenableBuilder<TextEditingValue>(
              valueListenable: _searchController,
              builder: (context, value, _) {
                if (value.text.isEmpty) return const SizedBox.shrink();
                return IconButton(
                  tooltip: 'Clear search',
                  icon: const Icon(Icons.close),
                  onPressed: _clearSearch,
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 12),
        StatusFilterChips(
          selected: status,
          onChanged: (value) =>
              ref.read(statusFilterProvider.notifier).set(value),
        ),
        const SizedBox(height: 4),
        CategoryFilterChips(
          selected: category,
          onChanged: (value) =>
              ref.read(categoryFilterProvider.notifier).set(value),
        ),
      ],
    );
  }
}
