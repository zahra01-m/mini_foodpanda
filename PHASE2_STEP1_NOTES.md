# Phase 2 — Step 1: Real Firebase Auth + Firestore user profiles

This replaces the in-memory mock login/signup with real Firebase
Authentication, and stores each user's role/name/phone in a Firestore
`users/{uid}` document (matching the `users` collection in the spec).

## Before you run the app
1. Create a Firebase project (console.firebase.google.com).
2. Authentication → Sign-in method → enable **Email/Password**.
3. Firestore Database → Create database → start in **test mode**.
4. `dart pub global activate flutterfire_cli`
5. From the project root: `flutterfire configure` — this generates a
   real `lib/firebase_options.dart`, overwriting the placeholder in
   this zip (the placeholder just throws a clear error telling you to
   run this if you skip it).
6. `flutter pub get`
7. Optional: paste `firestore.rules` into the Firebase console's
   Firestore Rules tab (or `firebase deploy --only firestore:rules`
   if you have the Firebase CLI set up).

## What changed
- `pubspec.yaml` — added `firebase_core`, `firebase_auth`, `cloud_firestore`.
- `lib/firebase_options.dart` — new placeholder, replaced by `flutterfire configure`.
- `lib/main.dart` — initializes Firebase before `runApp`; shows a clear
  "Firebase isn't configured yet" screen instead of crashing if you
  haven't run `flutterfire configure` yet.
- `lib/models/user_model.dart` — added `toFirestore()` / `fromFirestore()`.
- `lib/services/auth_service.dart` — now calls `FirebaseAuth` for
  sign-in/sign-up and reads/writes the `users/{uid}` Firestore doc for
  the role, name and phone. Same public method names as the mock
  version had, so nothing else in the app needed to change.
- `lib/providers/auth_provider.dart` — passes the password through,
  turns `FirebaseAuthException`s into friendly messages, and restores
  a persisted session on app start (`AuthNotifier._restoreSession`).
- `lib/screens/splash_screen.dart` — if a session was restored, skips
  the role selector and goes straight to that user's home screen.
- `lib/screens/auth/login_screen.dart`, `signup_screen.dart` — now
  send the password to the provider.
- `firestore.rules` — rules for the `users` collection.

## Still on mock data (next step)
Restaurants, menu items, orders, rider locations, and reviews are
still served by `MockDataService` — that's the natural next slice
("Firestore for restaurants & menu", then orders, etc.) whenever
you're ready to continue.

## One thing to know
Since Firebase Auth accounts aren't role-specific, the same email can
only be used for one role. Signing up as a customer, then trying to
log in as "Rider" with that same email, will show a clear
"registered as customer, not rider" error rather than silently
letting you into the wrong dashboard.
