# Build Roadmap

## Phase 1 — MVP
- [x] Auth flow (mock), role selection: customer / rider / admin
- [x] Restaurant list, menu, cart, checkout (cash on delivery placeholder)
- [x] Order status lifecycle, order history
- [x] Admin: vendor approval, order status updates, basic revenue view

## Phase 2 — Live tracking
- [x] Rider app: accept/decline requests, one active delivery at a time
- [x] Simulated live location feed (swap-in point for Firestore + real GPS)
- [x] Customer: live tracking map on the order-tracking screen

## Phase 3 — Payments
- [x] Mock Stripe-style PaymentSheet on checkout (test card numbers included)
- [x] Payment success/failure states; order confirmed only after charge succeeds
- [ ] Swap PaymentService for a real Stripe PaymentSheet + secret key when going live

## Phase 4 — Polish
- [x] fl_chart on AnalyticsScreen — revenue by vendor, orders by status, top sellers
- [x] Ratings & reviews — rate delivered orders, average rating + review sheet on restaurant page
- [x] Mock FCM notification inbox, fed by every order-status change
- [x] Error/loading/empty states audited across every screen — every FutureProvider/StreamProvider
      now has a proper loading spinner, a friendly empty state, and a retry-capable error state

## Left for going live (not portfolio-blocking)
- [ ] Real Firebase Auth + Firestore in place of MockDataService
- [ ] Real Stripe keys + webhook handling
- [ ] Real Google Maps SDK key in place of the in-app custom-painted map
- [ ] Real FCM project + device push registration
