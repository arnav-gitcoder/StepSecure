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

  User? get currentUser => _auth.currentUser;

  /// Fires on sign-in, sign-out, and token refresh.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<User?> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await credential.user?.sendEmailVerification();
    return credential.user;
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

  Future<void> sendEmailVerification() async {
    await _auth.currentUser?.sendEmailVerification();
  }

  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  /// Refreshes the cached user from Firebase's servers, since
  /// emailVerified on the local User object is stale until reload().
  Future<bool> reloadAndCheckVerified() async {
    await _auth.currentUser?.reload();
    return _auth.currentUser?.emailVerified ?? false;
  }

  Future<void> signOut() async {
    // Best-effort: if the user never used Google sign-in this just
    // no-ops rather than throwing.
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    await _auth.signOut();
  }

  /// Turns a FirebaseAuthException into copy a user should see. Keep
  /// this exhaustive-ish — an unmapped code falls back to e.message,
  /// which is usually readable but not always friendly.
  String friendlyError(Object e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'email-already-in-use':
          return 'An account already exists for that email.';
        case 'invalid-email':
          return 'That email address looks invalid.';
        case 'weak-password':
          return 'Password should be at least 6 characters.';
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
        default:
          return e.message ?? 'Authentication error. Please try again.';
      }
    }
    return 'Something went wrong. Please try again.';
  }
}