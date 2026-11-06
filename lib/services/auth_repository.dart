import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/app_user.dart';

/// An auth error with a message that is safe to show to the user.
class AuthFailure implements Exception {
  const AuthFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Turns a Firebase Auth error code into a friendly message.
/// Kept as a plain function so it can be unit tested.
String friendlyAuthMessage(String code) {
  switch (code) {
    case 'invalid-email':
      return 'That email address is not valid.';
    case 'user-disabled':
      return 'This account has been disabled.';
    // Newer Firebase versions return 'invalid-credential' for both a wrong
    // password and an unknown email (so attackers can't guess emails).
    case 'user-not-found':
    case 'wrong-password':
    case 'invalid-credential':
      return 'Incorrect email or password.';
    case 'email-already-in-use':
      return 'An account with this email already exists.';
    case 'weak-password':
      return 'Password is too weak. Use at least 6 characters.';
    case 'too-many-requests':
      return 'Too many attempts. Please wait a moment and try again.';
    case 'network-request-failed':
      return 'No internet connection. Please check your network.';
    default:
      return 'Something went wrong. Please try again.';
  }
}

/// Everything to do with signing in and the user's profile document.
///
/// Screens never talk to Firebase directly; they go through this class.
/// That keeps Firebase code in one place and makes screens easier to test.
class AuthRepository {
  // `this._auth` fills the private field directly. Callers still pass it
  // without the underscore: AuthRepository(auth: ..., firestore: ...).
  AuthRepository({
    required this._auth,
    required this._firestore,
  });

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  /// Emits the signed-in Firebase user, or null when signed out.
  Stream<User?> authStateChanges() => _auth.authStateChanges();

  /// Emits the profile at users/{uid} every time it changes.
  /// Emits null while the document does not exist yet (just after sign up).
  Stream<AppUser?> watchUserProfile(String uid) {
    return _users.doc(uid).snapshots().map((snapshot) {
      final data = snapshot.data();
      if (data == null) return null;
      return AppUser.fromMap(snapshot.id, data);
    });
  }

  /// Creates the Firebase account, then the users/{uid} profile document.
  /// Everyone signs up as a student; staff are promoted in the Console.
  Future<void> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final newUser = AppUser(
        uid: credential.user!.uid,
        name: name.trim(),
        email: email.trim(),
        role: UserRole.student,
      );

      await _users.doc(newUser.uid).set({
        ...newUser.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(friendlyAuthMessage(e.code));
    } on FirebaseException catch (_) {
      // The account was created but the profile could not be saved
      // (e.g. Firestore rules or no connection).
      throw const AuthFailure(
        'Your account was created but your profile could not be saved. '
        'Please try again.',
      );
    }
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(friendlyAuthMessage(e.code));
    }
  }

  Future<void> signOut() => _auth.signOut();
}
