# Round 3 — apply AFTER round 1 and round 2
Then run:  flutter pub get      (adds shared_preferences)

NEW   lib/core/utils/pricing.dart                 fee rules: delivery Rs.80 (free over 1500), service 3%, min order Rs.200
NEW   lib/models/saved_address.dart
NEW   lib/providers/address_book_provider.dart    saved addresses, stored on device per user
NEW   lib/widgets/price_breakdown.dart            PriceBreakdownView + FreeDeliveryBar
EDIT  pubspec.yaml                                + shared_preferences
EDIT  lib/models/order_model.dart                 + subtotal, deliveryFee, serviceFee, deliveryAddress, deliveryNote (old orders still load)
EDIT  lib/services/order_service.dart             placeOrder computes fees itself, stores address + note
EDIT  lib/providers/cart_provider.dart           cart persists across restarts; syncWithMenu(); breakdown   (replaces round-2 file)
EDIT  lib/screens/customer/cart_screen.dart       free-delivery bar, breakdown, min order, auto-sync    (replaces round-1 file)
EDIT  lib/screens/customer/checkout_screen.dart   typed address, saved-address chips, rider note, breakdown  (replaces round-2 file)
EDIT  lib/screens/customer/order_tracking_screen.dart  delivery details + breakdown       (replaces round-2 file)
EDIT  lib/screens/customer/profile_screen.dart    logout also clears the saved cart       (replaces round-1 file)
EDIT  lib/screens/rider/active_delivery_screen.dart, rider_home_screen.dart   rider sees address + note
EDIT  lib/screens/admin/order_management_screen.dart   address + fee line in order detail
EDIT  lib/screens/admin/analytics_screen.dart     vendor revenue = food only (excludes our fees)
