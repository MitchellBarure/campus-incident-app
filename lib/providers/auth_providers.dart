import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_user.dart';
import '../services/auth_repository.dart';

// Wrapped in providers so tests can swap in fakes.

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    auth: ref.watch(firebaseAuthProvider),
    firestore: ref.watch(firestoreProvider),
  );
});

/// The signed-in Firebase user, or null.
/// A StreamProvider exposes a stream's latest value as loading/data/error.
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges();
});

/// The signed-in user's profile (users/{uid}), or null while signed out.
final currentUserProfileProvider = StreamProvider<AppUser?>((ref) {
  // ref.watch rebuilds this provider when the user logs in or out.
  final user = ref.watch(authStateProvider).value;
  if (user == null) {
    return Stream.value(null);
  }
  return ref.watch(authRepositoryProvider).watchUserProfile(user.uid);
});
