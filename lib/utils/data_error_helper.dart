import 'package:firebase_core/firebase_core.dart';

/// Turns Firestore / Realtime Database errors into text a user can act on,
/// without exposing backend details. Works for both databases because both
/// throw [FirebaseException].
class DataErrorHelper {
  DataErrorHelper._();

  static bool isPermissionDenied(Object error) =>
      error is FirebaseException &&
      (error.code == 'permission-denied' || error.code == 'unauthenticated');

  static bool isNetworkProblem(Object error) {
    if (error is! FirebaseException) return false;
    switch (error.code) {
      case 'unavailable':
      case 'network-error':
      case 'disconnected':
      case 'deadline-exceeded':
        return true;
      default:
        return false;
    }
  }

  static String friendlyMessage(Object error) {
    if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
          return "You don't have access to this data. "
              'Try signing out and back in.';
        case 'unauthenticated':
          return 'Your session has expired. Please sign in again.';
        case 'unavailable':
        case 'network-error':
        case 'disconnected':
          return "Can't reach the server. Check your connection and try again.";
        case 'deadline-exceeded':
          return 'The request took too long. Please try again.';
        case 'not-found':
          return 'That item no longer exists.';
        case 'resource-exhausted':
          return 'Too many requests right now. Please try again shortly.';
        default:
          return 'Something went wrong loading your data. Please try again.';
      }
    }
    if (error is ArgumentError) {
      return 'Something went wrong. Please try again.';
    }
    return 'Something went wrong. Please try again.';
  }
}