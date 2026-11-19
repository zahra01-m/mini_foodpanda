import 'package:firebase_core/firebase_core.dart';

/// Turns a thrown error into a short message that tells the person (or the
/// developer running the app) what actually went wrong. A blanket "check
/// your connection" hid real problems such as Firestore security rules
/// that were never deployed.
String friendlyError(Object error) {
  if (error is FirebaseException) {
    switch (error.code) {
      case 'permission-denied':
        return 'The database refused this request (permission denied). '
            'If you are the developer, deploy firestore.rules to your Firebase project.';
      case 'unavailable':
      case 'network-request-failed':
        return 'Cannot reach the server. Check your connection and try again.';
      case 'failed-precondition':
        return 'A Firestore index is missing for this query. '
            'Run: firebase deploy --only firestore:indexes';
      case 'unauthenticated':
        return 'Your session has expired. Please log in again.';
    }
  }
  return 'Something went wrong. Please try again.';
}
