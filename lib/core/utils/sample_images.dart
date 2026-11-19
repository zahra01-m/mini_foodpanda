/// Bundled photos for the built-in sample data.
///
/// Restaurants and dishes are read from Firestore, and documents seeded
/// before these photos existed (or edited in the admin panel) carry an empty
/// or stale image path. For the fixed `sample-` ids we always know the right
/// bundled file, so the models use it whenever the stored value is empty or
/// points at a bundled asset. A real https URL entered by an admin wins.
const Map<String, String> sampleRestaurantImages = {
  'sample-midcity': 'assets/images/restaurant_midcity.jpg',
  'sample-fifth-avenue': 'assets/images/restaurant_fifth_avenue.jpg',
  'sample-sweet-creme': 'assets/images/restaurant_sweet_creme.jpg',
  'sample-brew-bean': 'assets/images/restaurant_brew_bean.jpg',
};

const Map<String, String> sampleMenuImages = {
  'sample-midcity-1': 'assets/images/menu_midcity_fresh_pizza.jpg',
  'sample-midcity-2': 'assets/images/menu_midcity_malai_boti.jpg',
  'sample-midcity-3': 'assets/images/menu_midcity_chicken_karahi.jpg',
  'sample-fifth-1': 'assets/images/menu_fifth_avenue_supreme_pizza.jpg',
  'sample-fifth-2': 'assets/images/menu_fifth_avenue_crispy_chicken.jpg',
  'sample-fifth-3': 'assets/images/menu_fifth_avenue_chicken_fillet_burger.jpg',
  'sample-fifth-4': 'assets/images/menu_fifth_avenue_grilled_wrap.jpg',
  'sample-fifth-5': 'assets/images/menu_fifth_avenue_wrap_with_fries.jpg',
  'sample-sweet-1': 'assets/images/menu_sweet_creme_blizzard.jpg',
  'sample-sweet-2': 'assets/images/menu_sweet_creme_brownie_with_ice_cream.jpg',
  'sample-sweet-3': 'assets/images/menu_sweet_creme_brownie_box.jpg',
  'sample-sweet-4': 'assets/images/menu_sweet_creme_ice_cream_rolls.jpg',
  'sample-brew-1': 'assets/images/menu_brew_bean_cappuccino.jpg',
  'sample-brew-2': 'assets/images/menu_brew_bean_iced_latte.jpg',
  'sample-brew-3': 'assets/images/menu_brew_bean_flat_white.jpg',
  'sample-brew-4': 'assets/images/menu_brew_bean_club_sandwich.jpg',
  'sample-brew-5': 'assets/images/menu_brew_bean_blueberry_muffin.jpg',
  'sample-brew-6': 'assets/images/menu_brew_bean_chocolate_croissant.jpg',
};

/// [stored] is what Firestore holds; [sample] is the bundled file for this id.
String resolveBundledImage(String stored, String? sample) {
  final s = stored.trim();
  if (sample == null) return s;
  if (s.isEmpty || s.startsWith('assets/')) return sample;
  return s;
}
