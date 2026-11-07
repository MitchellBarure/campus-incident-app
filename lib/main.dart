import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'firebase_options.dart';

Future<void> main() async {
  // Required before Firebase.initializeApp.
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // ProviderScope stores the state of every provider.
  runApp(
    const ProviderScope(retry: _noAutomaticRetry, child: CampusIncidentApp()),
  );
}

/// Turns off Riverpod's auto-retry, which showed an endless spinner on
/// permanent errors (e.g. a missing index). Users tap Try again instead.
Duration? _noAutomaticRetry(int retryCount, Object error) => null;
