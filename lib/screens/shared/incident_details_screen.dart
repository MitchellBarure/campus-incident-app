import 'package:flutter/material.dart';

// Placeholder - the real screen is built in Milestone 7.
class IncidentDetailsScreen extends StatelessWidget {
  const IncidentDetailsScreen({super.key, required this.incidentId});

  final String incidentId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Incident Details')),
      body: Center(child: Text('Details for incident $incidentId')),
    );
  }
}
