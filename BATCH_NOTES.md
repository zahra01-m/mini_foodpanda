# Phase 4 — Batch 3: Analytics charts, ratings & reviews, notifications

12 files — the last roadmap phase. Unzip and copy `lib/` and
`pubspec.yaml` over your project, then run `flutter pub get` to fetch
the new `fl_chart` dependency.

## New files
- `lib/services/notification_service.dart` — mock FCM inbox; any
  order-status change (admin panel or rider pickup/delivered) pushes a
  notification here.
- `lib/services/review_service.dart`
- `lib/providers/notification_provider.dart`, `lib/providers/review_provider.dart`
- `lib/screens/customer/rate_review_screen.dart` — 1–5 stars + optional
  comment, shown from a delivered order.
- `lib/screens/customer/notifications_screen.dart` — the notification
  inbox, marks everything read on open.

## Modified files
- `pubspec.yaml` — added `fl_chart: ^0.69.0`.
- `lib/services/mock_data_service.dart` — added a `reviews` store, and
  `updateOrderStatus` (the single choke point every status change
  already runs through) now also fires a notification.
- `lib/screens/admin/analytics_screen.dart` — the Phase 1 placeholder
  bars are now a real fl_chart `BarChart` for revenue by vendor, plus
  an orders-by-status breakdown and a top-5 selling items list.
- `lib/screens/customer/restaurant_detail_screen.dart` — shows the
  average rating and review count at the top; tapping it opens a
  bottom sheet listing every review.
- `lib/screens/customer/order_history_screen.dart` — delivered orders
  without a review yet get a "Rate this order" link.
- `lib/screens/customer/profile_screen.dart` — added a Notifications
  row with an unread-count badge.

## How it fits together
1. Order status changes (Preparing → Out for delivery → Delivered,
   from the admin panel or the rider app) each push a notification —
   check the badge on Profile.
2. Once an order shows Delivered in order history, "Rate this order"
   appears — submit a rating and it immediately shows up on that
   restaurant's detail page and its average rating.
3. Analytics now charts real revenue per vendor from `allOrdersProvider`,
   the same data source as before — just visualized properly.

That closes out every phase on the original roadmap (MVP → live
tracking → payments → polish). Let me know if you'd like anything
refined further, or a fresh pass once you've wired in real Firebase/
Stripe/Maps credentials.
