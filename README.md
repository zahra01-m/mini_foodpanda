# Mini FoodPanda

A three-role Flutter food delivery app — Customer, Rider, Admin — built as a portfolio
project. This is the Phase 1 (MVP) skeleton: auth, browsing, cart, checkout, and an
admin panel, all running on an in-memory mock data service so it runs with zero backend
setup. Firebase, live location tracking, and Stripe payments plug in at Phase 2–3.

## Structure
- `lib/core` — theme, constants, routes, utils
- `lib/models` — data classes (User, Restaurant, MenuItem, Order, CartItem, Review)
- `lib/services` — MockDataService (swap for Firebase later) + service wrappers
- `lib/providers` — Riverpod state (auth, cart, restaurants, orders)
- `lib/screens/auth` — login, signup, role selector
- `lib/screens/customer` — restaurant list/detail, cart, checkout, tracking, history
- `lib/screens/admin` — dashboard, vendor management, order management, analytics
- `lib/widgets` — shared UI components

## Run
```
flutter pub get
flutter run
```

## Roadmap
- Phase 1 (this skeleton): core order flow on mock data
- Phase 2: Firebase Auth + Firestore, live rider location on Google Maps
- Phase 3: Stripe checkout
- Phase 4: analytics charts, ratings, push notifications, polish
