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
String friendlyAuthMessage(String code) {
  switch (code) {
    case 'invalid-email':
      return 'That email address is not valid.';
    case 'user-disabled':
      return 'This account has been disabled.';
    // Covers wrong password and unknown email (hides which emails exist).
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

/// All auth and profile calls, so screens never touch Firebase directly.
class AuthRepository {
  // `this._auth` sets the private field; callers still write `auth:`.
  AuthRepository({required this._auth, required this._firestore});

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  /// Like authStateChanges, but also emits after reload(), so the app
  /// notices when the email has been verified.
  Stream<User?> userChanges() => _auth.userChanges();

  /// The profile at users/{uid}, or null until it exists.
  Stream<AppUser?> watchUserProfile(String uid) {
    return _users.doc(uid).snapshots().map((snapshot) {
      final data = snapshot.data();
      if (data == null) return null;
      return AppUser.fromMap(snapshot.id, data);
    });
  }

  /// Creates the account and its users/{uid} profile, always as a student.
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

      // If this fails, the verify screen has a Resend button.
      try {
        await credential.user!.sendEmailVerification();
      } on FirebaseAuthException catch (_) {}
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(friendlyAuthMessage(e.code));
    } on FirebaseException catch (_) {
      // Account created but profile not saved (rules or connection).
      throw const AuthFailure(
        'Your account was created but your profile could not be saved. '
        'Please try again.',
      );
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(friendlyAuthMessage(e.code));
    }
  }

  Future<void> sendVerificationEmail() async {
    try {
      await _auth.currentUser?.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(friendlyAuthMessage(e.code));
    }
  }

  /// Checks with Firebase whether the email is now verified.
  Future<bool> checkEmailVerified() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    await user.reload();
    final refreshed = _auth.currentUser;
    if (refreshed == null || !refreshed.emailVerified) return false;
    // A fresh token carries email_verified = true to the security rules.
    await refreshed.getIdToken(true);
    return true;
  }

  Future<void> signOut() => _auth.signOut();
}
