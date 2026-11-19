# UI animation upgrade

NEW  lib/widgets/count_up.dart                    numbers count up (admin + rider stats)
EDIT lib/widgets/fade_slide_in.dart              + `horizontal: true` (slides in from the side, RTL-aware)
EDIT lib/core/theme/app_theme.dart               side-slide page transition with parallax; native swipe-back on iOS/macOS
EDIT lib/screens/admin/admin_dashboard_screen.dart   count-up stats, tiles slide in one by one
EDIT lib/screens/admin/{vendor,rider,order}_management_screen.dart   list rows slide in
EDIT lib/screens/customer/notifications_screen.dart  rows slide in
EDIT lib/screens/rider/rider_home_screen.dart    incoming request cards slide in
EDIT lib/screens/rider/delivery_history_screen.dart  count-up earnings, history rows slide in
EDIT lib/widgets/cart_item_tile.dart             quantity pops, line total slides when it changes
EDIT lib/widgets/menu_item_tile.dart             haptic tick on add/remove
EDIT lib/screens/customer/rate_review_screen.dart    stars pop + haptic

Already in your app (unchanged): hero image restaurant -> detail, tap-bounce,
cart badge bounce, pulsing live-status dot, order-placed check animation,
swipe-to-remove cart rows, shimmer loaders. All new animations respect the
system "remove animations" setting.
