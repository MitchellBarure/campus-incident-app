import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';

// Placeholder - the real dashboard is built in Milestone 8.
class StaffDashboardScreen extends StatelessWidget {
  const StaffDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff Dashboard'),
        actions: [
          IconButton(
            tooltip: 'Profile',
            icon: const Icon(Icons.person_outline),
            onPressed: () => context.push(AppRoutes.profile),
          ),
        ],
      ),
      body: Center(
        child: TextButton(
          // Temporary link to check that the details route works.
          onPressed: () => context.push(AppRoutes.incidentDetails('demo-123')),
          child: const Text('Open a sample incident'),
        ),
      ),
    );
  }
}
