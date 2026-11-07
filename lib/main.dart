import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'firebase_options.dart';

Future<void> main() async {
  // Needed before calling native code (Firebase) ahead of runApp.
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ProviderScope stores the state of every Riverpod provider in the app.
  runApp(
    const ProviderScope(
      retry: _noAutomaticRetry,
      child: CampusIncidentApp(),
    ),
  );
}

/// Riverpod 3 retries failed providers automatically and reports
/// "loading" while it does, so a permanent error (e.g. a missing Firestore
/// index or denied permission) looked like an endless spinner. Returning
/// null turns that off: the error shows at once, and the user retries
/// with the "Try again" button instead.
Duration? _noAutomaticRetry(int retryCount, Object error) => null;
