import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Single place for all Firebase Auth calls. Screens should never touch
/// FirebaseAuth directly — go through this so error handling and
/// verification logic stay consistent.
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  /// Don't let a slow network hold the splash screen hostage.
  static const Duration _reloadTimeout = Duration(seconds: 8);

  /// reload() errors that mean the session is really over (account deleted,
  /// disabled or token revoked), as opposed to "we're offline".
  static const Set<String> _sessionEndedCodes = {
    'user-not-found',
    'user-disabled',
    'user-token-expired',
    'invalid-user-token',
  };

  User? get currentUser => _auth.currentUser;

  /// Fires on sign-in, sign-out, and token refresh.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Creates the account. The verification email and display name are
  /// best-effort: if either fails, the account still exists and the user can
  /// resend from the verification screen, instead of seeing an error and
  /// then "email already in use" on retry.
  Future<User?> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final user = credential.user;
    if (user != null) {
      final name = displayName?.trim();
      if (name != null && name.isNotEmpty) {
        try {
          await user.updateDisplayName(name);
        } catch (_) {}
      }
      await trySendEmailVerification();
    }
    return user;
  }

  Future<User?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    return credential.user;
  }

  /// Returns null if the user cancels the Google picker — that's not
  /// an error, just no result.
  Future<User?> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null;

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential = await _auth.signInWithCredential(credential);
    return userCredential.user;
  }

  /// Sends the verification email and throws on failure. Use this where the
  /// user asked for it (the Resend button) so they see the error.
  Future<void> sendEmailVerification() async {
    await _auth.currentUser?.sendEmailVerification();
  }

  /// Same, but never throws. Returns true only if an email was requested.
  Future<bool> trySendEmailVerification() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    try {
      await user.sendEmailVerification();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Sends a password-reset email.
  ///
  /// `user-not-found` is swallowed on purpose: the UI must show the same
  /// neutral message whether or not an account exists for the address.
  /// Other errors (invalid email, offline, rate limit) still throw.
  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') return;
      rethrow;
    }
  }

  /// Asks Firebase's servers for the current verified state.
  ///
  /// * true / false  – fresh answer from the server.
  /// * null          – couldn't find out (offline, timeout, no user). Callers
  ///                   should fall back to the cached value or retry; this is
  ///                   NOT "unverified".
  ///
  /// If the account was deleted/disabled or the token revoked, the user is
  /// signed out here, so callers should re-check [currentUser] afterwards.
  Future<bool?> refreshEmailVerified() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      await user.reload().timeout(_reloadTimeout);
      return _auth.currentUser?.emailVerified ?? false;
    } on FirebaseAuthException catch (e) {
      if (_sessionEndedCodes.contains(e.code)) {
        await signOut();
      }
      return null;
    } on TimeoutException {
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Kept for older callers. Falls back to the cached value when offline.
  Future<bool> reloadAndCheckVerified() async {
    final fresh = await refreshEmailVerified();
    return fresh ?? (_auth.currentUser?.emailVerified ?? false);
  }

  Future<void> signOut() async {
    // Best-effort: if the user never used Google sign-in this just
    // no-ops rather than throwing.
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    await _auth.signOut();
  }

  /// Turns an error into copy a user should see. Unmapped errors get a
  /// generic message rather than the raw backend text.
  String friendlyError(Object e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'email-already-in-use':
          return 'An account already exists for that email.';
        case 'invalid-email':
          return 'That email address looks invalid.';
        case 'weak-password':
          return 'That password is too weak. Choose a stronger one.';
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          return 'Incorrect email or password.';
        case 'user-disabled':
          return 'This account has been disabled.';
        case 'too-many-requests':
          return 'Too many attempts. Please try again later.';
        case 'network-request-failed':
          return 'Network error. Check your connection and try again.';
        case 'operation-not-allowed':
          return "This sign-in method isn't enabled yet.";
        case 'account-exists-with-different-credential':
          return 'An account already exists with a different sign-in method.';
        case 'requires-recent-login':
        case 'user-token-expired':
        case 'invalid-user-token':
          return 'Your session has expired. Please sign in again.';
        default:
          return 'Authentication error. Please try again.';
      }
    }
    return 'Something went wrong. Please try again.';
  }
}