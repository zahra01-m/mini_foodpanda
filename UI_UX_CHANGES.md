# UI/UX update — changed files only

Unzip over your project root (paths match `lib/...`). No new packages, no
pubspec / ARB / Firebase changes. 39 files edited, 4 new
(`role_pill.dart`, `error_banner.dart`, `confirm_logout.dart`, `saved_addresses_screen.dart`).

## Bugs fixed
- **Dark mode was half-broken**: role selector (first screen), restaurant card,
  status badges, shimmer skeletons, notifications, rider + admin screens used
  hard-coded light colours (e.g. cream card + near-white title). All now use
  the brightness-aware palette.
- **Disabled primary button had no background** (looked like floating text on
  Checkout / Cart). Rebuilt `CustomButton` with a visible disabled state, real
  ripple and press-scale.
- **Payment screen overflowed when the keyboard opened** (fixed Column + Spacer).
  Now scrollable with a pinned Pay button.
- **Review submit hung forever on failure**; now shows an error, re-enables the
  button, disposes its controller, and confirms with a snackbar.
- **Order cards showed no tap ripple** (painted under an opaque Container).
- **Admin: editing a restaurant wiped its photo** (imageUrl wasn't carried
  into the saved object). Photo URL field added to the form.
- Restaurant detail info row could overflow on narrow phones -> wraps.
- Checkout errors appeared at the bottom of the scrolled form -> now sit above
  the action button. Raw exception text (`$e`) no longer shown to users.
- Map legend said "You" on the rider's screen and omitted the rider marker.

## UX improvements
- Home: shorter app bar (title was truncated), labelled **Favorites** filter
  chip, "track your active order" banner, greeting, cart badge caps at 99+.
- Restaurant page: richer cart bar (count · View cart · total); section chips
  now follow scrolling.
- Cart: free-delivery progress moved above the list (bottom bar was too tall).
- Login/Signup show which role you're signing in as.
- Profile: settings controls stacked full-width (labels were squeezed).
- Notifications highlight what was new when opened.
- Admin: confirm before deleting a menu item; stat cards no longer overflow.
- Touch targets raised to 44dp (menu/cart steppers, favorite heart).
- Theme: chips, snackbars (floating), dialogs, bottom sheets, nav bar,
  switches, checkboxes, segmented buttons, list tiles, focus/error input
  states are now styled for both light and dark.
- Accessibility: header semantics, live-region error banners, labelled
  favorite/rating controls, RTL-safe positioning on the card & badge.

## Round 2 additions
- **Forgot password?** on login (emails a reset link; needs the email typed first).
- **Admin could not log out at all** — added a logout button; rider logout now asks first.
- **Saved addresses screen** (Profile -> Saved addresses): add / edit / delete.
- Cart shows "Ordering from <restaurant>"; light haptic tick when adding a dish.

## Round 3 additions
- Home: **sort menu** (Recommended / Top rated / Fastest delivery) in the search field.
- Order history: **All / Active / Past** filter.
- New tests: `test/widgets/custom_button_test.dart`, `test/widgets/error_banner_test.dart`.

## Round 4: Firestore permission-denied
- `lib/core/utils/error_text.dart` (new): error screens now say *why* a load failed
  (permission denied / offline / missing index) instead of always "check your connection".
- Fixed 4 places that read `AsyncValue.value` (throws on error in Riverpod 2.x) —
  profile, checkout, restaurant detail, rider home. A failed Firestore query now
  shows a message instead of the red crash screen.
- The permission error itself is a Firebase setup issue: deploy `firestore.rules`
  (`firebase deploy --only firestore:rules,firestore:indexes`).

## Round 5: web / desktop
- Wide windows: app stays in a centred 760px column (no more edge-to-edge stretching).
- Mouse drag now scrolls horizontal chip rows in Chrome/desktop.
- Pointer cursor on tappable cards, buttons and the favorite heart.

## Round 6
- Empty cart / empty order history now offer a "Browse restaurants" button.
- System text scaling capped at 0.9x-1.3x to prevent overflow in tight rows.

## Round 7
- Restaurant page: "Search this menu" box (shown for menus with 8+ dishes) + "No dishes found" state.
- New test: test/core/error_text_test.dart.

## Round 8: web map crash
- "TypeError: Cannot read properties of undefined (reading 'maps')" on web: the Google
  Maps JS script was never loaded. On web the maps now show a placeholder unless enabled.
- To enable: see the "Web (Chrome)" section in MAPS_SETUP.md (+ web/index.html comment)
  and run with --dart-define=WEB_MAPS=true.

## Round 9: more professional + interactive
- Home: gradient hero banner (time-of-day greeting + free-delivery pill), horizontal
  "Top rated" photo carousel, cuisine icons on the filter chips, result count heading.
- Checkout: animated "Order placed!" success moment before tracking.
- Add-to-cart: count pill "pops" in the cart bar; quantity digits animate in the stepper.
- New files: core/utils/cuisine_icon.dart, widgets/order_placed_dialog.dart.

## Round 10: your restaurant + menu images
- assets/images/: 3 restaurant covers + 12 menu photos (renamed, borders cropped, upscaled).
- RestaurantImage / FoodThumb now load bundled `assets/...` images (restaurant `imageAsset`,
  menu `imageUrl`). Network URLs still work.
- Sample data = Mid City, Fifth Avenue Pizza Co, Sweet Creme with their menus.
  Prices are placeholders except the Rs. 380 burger. Edit them in Admin.
- Admin > Vendors: delete-restaurant button (to remove the old sample restaurants).
- test/assets/sample_assets_test.dart checks every referenced image file exists.

## Round 11: new features
- **Cancel order** (customer): button on the tracking screen while the order is still
  "pending". Needs `firestore.rules` redeployed:  firebase deploy --only firestore:rules
  (service: OrderService.cancelOrder, test: test/services/order_cancel_test.dart).
- **Dish details sheet**: tap a dish's photo/text for a large photo, description and a live
  quantity control (widgets/dish_sheet.dart).
- **Onboarding**: 3-page intro on first launch while logged out (screens/onboarding_screen.dart).

## Round 12
- Rider: "Navigate to restaurant / customer" button opens Google Maps directions
  (core/utils/maps_launcher.dart, uses the existing url_launcher dependency).
- Home: "Order again" card for the last delivered order (reuses the reorder logic).
- Restaurant page: skeleton loading instead of a spinner.
- Respects the system "remove animations" setting (FadeSlideIn).
- Tests: maps_launcher_test.dart, cuisine_icon_test.dart.

## Round 13
- Profile: **Edit profile** (name + phone) and phone shown in the header
  (AuthService.updateProfile / AuthNotifier.updateProfile; no rules change needed).
- Restaurant page: delivery fee / minimum order / free-delivery info pills.
- Order tracking: short order number with a copy-ID button.
- Test: test/services/auth_profile_test.dart.

## Round 14: promo codes
- Checkout: "Promo code" card (type a code or tap a suggestion) + a "Discount (CODE)" row.
  Codes: WELCOME10 (10% up to Rs.300, min Rs.500), FOODIE15 (15% up to Rs.250, min Rs.800),
  FREESHIP (free delivery, min Rs.300). Edit them in lib/core/utils/promo.dart.
- The UI sends only the code; OrderService.placeOrder recomputes the discount (like fees),
  stores `discount` + `promoCode` on the order; tracking shows the discount row.
- Tests: test/core/promo_test.dart, test/services/order_promo_test.dart.
- No firestore.rules change needed. Codes live in the app (demo); validate server-side for production.

## Please verify (I couldn't run Flutter here)
I had no Dart/Flutter SDK, so I syntax-checked every file with a Dart parser
and manually reviewed APIs, but did not run `flutter analyze` or the tests.
Please run:  `flutter analyze && flutter test`
Existing widget tests were read and their expectations preserved
(skeleton box counts, single AnimatedContainer in the badge, heart icons,
role-selector texts).
