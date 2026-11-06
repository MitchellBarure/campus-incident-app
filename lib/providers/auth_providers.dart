import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_user.dart';
import '../services/auth_repository.dart';

// The Firebase objects are wrapped in providers so tests can swap them for
// fakes (e.g. fake_cloud_firestore) with ProviderScope(overrides: [...]).

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

/// The signed-in Firebase user, or null when signed out.
///
/// A StreamProvider listens to a stream and exposes its latest value as an
/// AsyncValue, which is either loading, data, or error.
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges();
});

/// The signed-in user's profile from users/{uid} (name, email, role).
///
/// Emits null when signed out, or for a moment right after sign up before
/// the profile document has been written.
final currentUserProfileProvider = StreamProvider<AppUser?>((ref) {
  // ref.watch means: when the auth state changes (login/logout), rebuild
  // this provider so it listens to the new user's document.
  final user = ref.watch(authStateProvider).value;
  if (user == null) {
    return Stream.value(null);
  }
  return ref.watch(authRepositoryProvider).watchUserProfile(user.uid);
});
