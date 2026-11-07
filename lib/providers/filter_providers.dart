import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/utils/incident_filters.dart';
import '../models/incident.dart';
import '../models/incident_category.dart';
import '../models/incident_status.dart';
import 'auth_providers.dart';
import 'incident_providers.dart';

// A Notifier holds a value plus the methods allowed to change it.
// Each one watches the auth state, so filters reset when the user changes.

class SearchTextNotifier extends Notifier<String> {
  @override
  String build() {
    ref.watch(authStateProvider);
    return '';
  }

  void set(String text) => state = text;
}

class StatusFilterNotifier extends Notifier<IncidentStatus?> {
  @override
  IncidentStatus? build() {
    ref.watch(authStateProvider);
    return null; // null = All
  }

  void set(IncidentStatus? status) => state = status;
}

class CategoryFilterNotifier extends Notifier<IncidentCategory?> {
  @override
  IncidentCategory? build() {
    ref.watch(authStateProvider);
    return null; // null = All
  }

  void set(IncidentCategory? category) => state = category;
}

final searchTextProvider = NotifierProvider<SearchTextNotifier, String>(
  SearchTextNotifier.new,
);

final statusFilterProvider =
    NotifierProvider<StatusFilterNotifier, IncidentStatus?>(
      StatusFilterNotifier.new,
    );

final categoryFilterProvider =
    NotifierProvider<CategoryFilterNotifier, IncidentCategory?>(
      CategoryFilterNotifier.new,
    );

/// All incidents with the search and filters applied.
/// whenData keeps loading/error states and only transforms the data.
final filteredIncidentsProvider = Provider<AsyncValue<List<Incident>>>((ref) {
  final incidents = ref.watch(allIncidentsProvider);
  final query = ref.watch(searchTextProvider);
  final status = ref.watch(statusFilterProvider);
  final category = ref.watch(categoryFilterProvider);

  return incidents.whenData(
    (list) =>
        filterIncidents(list, query: query, status: status, category: category),
  );
});

final hasActiveFiltersProvider = Provider<bool>((ref) {
  return ref.watch(searchTextProvider).trim().isNotEmpty ||
      ref.watch(statusFilterProvider) != null ||
      ref.watch(categoryFilterProvider) != null;
});

void clearAllFilters(WidgetRef ref) {
  ref.read(searchTextProvider.notifier).set('');
  ref.read(statusFilterProvider.notifier).set(null);
  ref.read(categoryFilterProvider.notifier).set(null);
}
