# Dummy / demo data

## What you get
| Data | Count | Notes |
|---|---|---|
| Restaurants | 4 | Mid City, Fifth Avenue Pizza Co, Sweet Creme, Brew & Bean - the ones that have photos |
| Menu items | 18 | every item has a bundled photo |
| Customers | 8 | Ayesha Khan, Bilal Ahmed, ... (profiles only) |
| Riders | 6 | 4 approved, 2 waiting for approval |
| Orders | 17 | delivered / cancelled / refunded / pending / preparing / out-for-delivery, card + cash, one open dispute |
| Reviews | 8 | feed restaurant ratings and the analytics screen |
| Rider GPS | 2 | riders currently "out for delivery" show on the admin live map |
| Notifications | 15 | customer inbox entries |

All dummy documents use fixed ids starting with `sample-`, so loading twice
overwrites rather than duplicates.

## How to load it (3 steps)
1. **Deploy the new rules** (they let an admin write `sample-` documents):
   `firebase deploy --only firestore:rules`
   (or paste `firestore.rules` into Firebase console -> Firestore -> Rules -> Publish).
2. `flutter pub get` then run the app.
3. Log in as **admin** -> tap the cloud icon (top right, "Load sample data").
   A snackbar reports what was written.

## Good to know
* Dummy customers/riders are **Firestore profiles only, not Firebase Auth
  accounts** - you can't log in as them. They appear in Admin > Riders (approve
  the pending ones), order lists, reviews, analytics and the live map. To test
  the customer or rider apps, sign up normally with an email.
* Dates are relative to when you press the button (e.g. "27 days ago" ... "4 min ago").
* Re-running "Load sample data" also deletes the sample restaurants, items, orders,
  reviews and notifications that older versions created (Dragon Wok, Tikka Junction, ...).
* Add or change pictures in Admin > Vendors > edit (restaurant) or the menu screen
  (item): tap **Upload photo** to pick one from the gallery, or paste a URL.
* Remove demo data: delete documents whose id starts with `sample-` in the
  Firebase console (users, orders, reviews, notifications, riderLocations,
  restaurants, menuItems).

## Files
NEW  `lib/services/demo_data_service.dart`
EDIT `lib/services/mock_data_service.dart` (restaurants + menu)
EDIT `lib/screens/admin/admin_dashboard_screen.dart` (button seeds everything)
EDIT `firestore.rules` (admin may write `sample-` docs)
NEW  `test/services/demo_data_service_test.dart`
