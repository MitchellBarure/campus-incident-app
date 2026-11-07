import 'package:campus_incident_app/models/incident.dart';
import 'package:campus_incident_app/models/incident_category.dart';
import 'package:campus_incident_app/models/incident_status.dart';
import 'package:campus_incident_app/providers/auth_providers.dart';
import 'package:campus_incident_app/providers/filter_providers.dart';
import 'package:campus_incident_app/providers/incident_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Incident makeIncident(
  String id,
  IncidentStatus status,
  IncidentCategory category,
) {
  return Incident(
    id: id,
    title: 'Issue $id',
    description: 'Details',
    category: category,
    location: 'Campus',
    status: status,
    reporterId: 'u1',
    reporterName: 'Amina',
    hasImage: false,
    createdAt: DateTime(2026, 11, 6),
    updatedAt: DateTime(2026, 11, 6),
    statusHistory: const [],
  );
}

void main() {
  final incidents = [
    makeIncident('a', IncidentStatus.submitted, IncidentCategory.water),
    makeIncident('b', IncidentStatus.resolved, IncidentCategory.water),
    makeIncident('c', IncidentStatus.resolved, IncidentCategory.safety),
  ];

  /// A ProviderContainer is a ProviderScope without widgets: it lets us
  /// read and change providers directly in a test.
  Future<ProviderContainer> makeContainer() async {
    final container = ProviderContainer.test(
      overrides: [
        authStateProvider.overrideWith((ref) => Stream.value(null)),
        allIncidentsProvider.overrideWith((ref) => Stream.value(incidents)),
      ],
    );
    // Riverpod 3 pauses providers that nobody listens to, so we listen
    // (like a screen would) before waiting for the first list.
    container.listen(filteredIncidentsProvider, (_, _) {});
    await container.read(allIncidentsProvider.future);
    return container;
  }

  List<String> filteredIds(ProviderContainer container) {
    final result = container.read(filteredIncidentsProvider).value!;
    return result.map((incident) => incident.id).toList();
  }

  test('starts with no filters and shows everything', () async {
    final container = await makeContainer();

    expect(filteredIds(container), ['a', 'b', 'c']);
    expect(container.read(hasActiveFiltersProvider), isFalse);
  });

  test('status and category filters update the list', () async {
    final container = await makeContainer();

    container.read(statusFilterProvider.notifier).set(IncidentStatus.resolved);
    expect(filteredIds(container), ['b', 'c']);

    container.read(categoryFilterProvider.notifier).set(IncidentCategory.water);
    expect(filteredIds(container), ['b']);
    expect(container.read(hasActiveFiltersProvider), isTrue);
  });

  test('search text filters the list', () async {
    final container = await makeContainer();

    container.read(searchTextProvider.notifier).set('issue c');
    expect(filteredIds(container), ['c']);
  });
}
