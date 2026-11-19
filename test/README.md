# Tests

Run everything:
```
flutter test
```

## What's covered, and where

| Feature | Test file(s) |
|---|---|
| Cart (add/remove/total) | `providers/cart_provider_test.dart` |
| Restaurant & menu CRUD, approval, sample-data seeding | `services/restaurant_service_test.dart` |
| Placing an order, GPS/fallback delivery point | `services/order_service_test.dart` |
| Order status flow + notifications on each change | `services/order_service_test.dart`, `services/notification_service_test.dart` |
| Disputes & refunds | `services/order_service_test.dart` |
| Rider request queue, accept/claim race, pickup/deliver, earnings | `services/rider_service_test.dart` |
| Reviews (one per order, average rating) | `services/review_service_test.dart` |
| Rider/user approval | `services/user_service_test.dart` |
| Auth: signup (rider starts unapproved), login, wrong-role guard | `services/auth_service_test.dart` |
| Mock Stripe test-card payment flow | `services/payment_service_test.dart` |
| Route line parsing (OSRM) | `services/route_service_test.dart` |
| Every model's Firestore (de)serialization + business logic (`countsAsRevenue`, `isPaid`, etc.) | `models/*_test.dart` |
| Order status badge, empty state | `widgets/*_test.dart` |
| App boots to role selector → login | `widget_test.dart` |

## How the Firestore/Auth tests work

Every service already takes its `FirebaseFirestore`/`FirebaseAuth` as an
optional constructor argument (`RestaurantService({FirebaseFirestore? firestore})`,
etc.) — that was built in from the start so tests can swap in a fake
instead of hitting a real project:

- **`fake_cloud_firestore`** — an in-memory Firestore that supports the
  same queries, `snapshots()` streams, batches and transactions the real
  one does, so `RiderService.acceptOrder`'s claim-race transaction and
  every `.where(...)` query gets exercised for real, just without a
  network call.
- **`firebase_auth_mocks`** — same idea for `FirebaseAuth`, used in
  `auth_service_test.dart`.

Nothing here talks to your actual Firebase project, so these are safe
and fast to run in CI or before every commit.

## Maps

`route_service_test.dart` injects a fake `http.Client` (see `RouteService.fetchRoute`'s
new optional `client` parameter) rather than hitting the real OSRM
server — no network needed. The Google Maps widgets themselves
(`live_tracking_map.dart`, `admin_live_map.dart`) aren't unit tested,
since `GoogleMap` needs native platform bindings that don't exist in
the plain `flutter_test` environment; they're best checked by running
the app.

## If `flutter pub get` fails to resolve the new dev dependencies

`fake_cloud_firestore` and `firebase_auth_mocks` are versioned to track
the real `cloud_firestore`/`firebase_auth` plugins. If the pinned
versions in `pubspec.yaml` don't resolve against this project's Firebase
plugin versions, run:
```
flutter pub upgrade fake_cloud_firestore firebase_auth_mocks --major-versions
```
