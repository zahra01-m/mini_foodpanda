import '../models/menu_item_model.dart';
import '../models/restaurant_model.dart';
import '../models/user_model.dart';

/// Sample data only. Everything the app shows now lives in Firestore;
/// this is what the admin's "Load sample data" button writes there so a
/// fresh project isn't empty. Fixed ids mean loading it twice never
/// creates duplicates.
class MockDataService {
  MockDataService._();

  static const List<Restaurant> restaurants = [
    Restaurant(
      id: 'sample-midcity',
      name: 'Mid City Hotel & Restaurant',
      category: 'Pakistani',
      imageAsset: 'assets/images/restaurant_midcity.jpg',
      rating: 4.6,
      etaMinutes: 30,
      lat: 30.0431,
      lng: 72.3512,
    ),
    Restaurant(
      id: 'sample-fifth-avenue',
      name: 'Fifth Avenue Pizza Co',
      category: 'Fast Food',
      imageAsset: 'assets/images/restaurant_fifth_avenue.jpg',
      rating: 4.4,
      etaMinutes: 25,
      lat: 30.0468,
      lng: 72.3437,
    ),
    Restaurant(
      id: 'sample-sweet-creme',
      name: 'Sweet Creme',
      category: 'Desserts',
      imageAsset: 'assets/images/restaurant_sweet_creme.jpg',
      rating: 4.8,
      etaMinutes: 20,
      lat: 30.0409,
      lng: 72.3555,
    ),
    Restaurant(
      id: 'sample-brew-bean',
      name: 'Brew & Bean Cafe',
      category: 'Cafe',
      imageAsset: 'assets/images/restaurant_brew_bean.jpg',
      rating: 4.7,
      etaMinutes: 18,
      lat: 30.0441,
      lng: 72.3399,
    ),
  ];

  // Prices are placeholders — edit them in Admin > Vendors > (restaurant) > menu.
  static const List<MenuItem> menuItems = [
    // Mid City
    MenuItem(id: 'sample-midcity-1', restaurantId: 'sample-midcity', name: 'Fresh Pizza', description: 'Loaded pan pizza with olives, peppers and creamy drizzle', price: 1200, category: 'Pizza', imageUrl: 'assets/images/menu_midcity_fresh_pizza.jpg'),
    MenuItem(id: 'sample-midcity-2', restaurantId: 'sample-midcity', name: 'Malai Boti', description: 'Creamy, tender chicken boti served on a sizzling platter', price: 1100, category: 'BBQ', imageUrl: 'assets/images/menu_midcity_malai_boti.jpg'),
    MenuItem(id: 'sample-midcity-3', restaurantId: 'sample-midcity', name: 'Chicken Karahi', description: 'Wok-cooked chicken karahi with fresh ginger and green chilli', price: 1450, category: 'Karahi', imageUrl: 'assets/images/menu_midcity_chicken_karahi.jpg'),
    // Fifth Avenue
    MenuItem(id: 'sample-fifth-1', restaurantId: 'sample-fifth-avenue', name: 'Supreme Pizza', description: 'Loaded with chicken, peppers, olives and extra cheese', price: 1100, category: 'Pizza', imageUrl: 'assets/images/menu_fifth_avenue_supreme_pizza.jpg'),
    MenuItem(id: 'sample-fifth-2', restaurantId: 'sample-fifth-avenue', name: 'Crispy Fried Chicken (2 pc)', description: 'Golden, crunchy fried chicken pieces', price: 450, category: 'Chicken', imageUrl: 'assets/images/menu_fifth_avenue_crispy_chicken.jpg'),
    MenuItem(id: 'sample-fifth-3', restaurantId: 'sample-fifth-avenue', name: 'Chicken Fillet Burger', description: 'Crispy fillet, creamy slaw, toasted bun', price: 380, category: 'Burgers', imageUrl: 'assets/images/menu_fifth_avenue_chicken_fillet_burger.jpg'),
    MenuItem(id: 'sample-fifth-4', restaurantId: 'sample-fifth-avenue', name: 'Grilled Chicken Wrap', description: 'Flame-grilled chicken, fresh veggies and cheese sauce', price: 420, category: 'Wraps', imageUrl: 'assets/images/menu_fifth_avenue_grilled_wrap.jpg'),
    MenuItem(id: 'sample-fifth-5', restaurantId: 'sample-fifth-avenue', name: 'Wrap with Fries', description: 'Loaded wrap served with a side of crispy fries', price: 520, category: 'Wraps', imageUrl: 'assets/images/menu_fifth_avenue_wrap_with_fries.jpg'),
    // Sweet Creme
    MenuItem(id: 'sample-sweet-1', restaurantId: 'sample-sweet-creme', name: 'Blizzard', description: 'Thick creamy blend with chocolate candy bar pieces', price: 450, category: 'Blizzards', imageUrl: 'assets/images/menu_sweet_creme_blizzard.jpg'),
    MenuItem(id: 'sample-sweet-2', restaurantId: 'sample-sweet-creme', name: 'Brownie with Ice Cream', description: 'Warm fudge brownie with soft-serve and chocolate sauce', price: 380, category: 'Brownies', imageUrl: 'assets/images/menu_sweet_creme_brownie_with_ice_cream.jpg'),
    MenuItem(id: 'sample-sweet-3', restaurantId: 'sample-sweet-creme', name: 'Brownie Delight Box', description: 'Brownie and ice cream swirl, packed to share', price: 420, category: 'Brownies', imageUrl: 'assets/images/menu_sweet_creme_brownie_box.jpg'),
    MenuItem(id: 'sample-sweet-4', restaurantId: 'sample-sweet-creme', name: 'Ice Cream Rolls', description: 'Hand-rolled ice cream with chocolate chips and wafer', price: 500, category: 'Ice Cream', imageUrl: 'assets/images/menu_sweet_creme_ice_cream_rolls.jpg'),
    // Brew & Bean
    MenuItem(id: 'sample-brew-1', restaurantId: 'sample-brew-bean', name: "Cappuccino", description: "Double espresso with steamed milk foam", price: 420, category: 'Coffee', imageUrl: 'assets/images/menu_brew_bean_cappuccino.jpg'),
    MenuItem(id: 'sample-brew-2', restaurantId: 'sample-brew-bean', name: "Iced Caramel Latte", description: "Cold espresso, milk and caramel drizzle", price: 490, category: 'Coffee', imageUrl: 'assets/images/menu_brew_bean_iced_latte.jpg'),
    MenuItem(id: 'sample-brew-3', restaurantId: 'sample-brew-bean', name: "Flat White", description: "Smooth espresso with velvety milk", price: 450, category: 'Coffee', imageUrl: 'assets/images/menu_brew_bean_flat_white.jpg'),
    MenuItem(id: 'sample-brew-4', restaurantId: 'sample-brew-bean', name: "Club Sandwich", description: "Grilled chicken, egg, cheese and fries", price: 650, category: 'Food', imageUrl: 'assets/images/menu_brew_bean_club_sandwich.jpg'),
    MenuItem(id: 'sample-brew-5', restaurantId: 'sample-brew-bean', name: "Blueberry Muffin", description: "Freshly baked blueberry muffin", price: 260, category: 'Bakery', imageUrl: 'assets/images/menu_brew_bean_blueberry_muffin.jpg'),
    MenuItem(id: 'sample-brew-6', restaurantId: 'sample-brew-bean', name: "Chocolate Croissant", description: "Buttery croissant with chocolate filling", price: 310, category: 'Bakery', imageUrl: 'assets/images/menu_brew_bean_chocolate_croissant.jpg'),
  ];

  /// Sample documents from earlier versions of the seed. Re-running "Load
  /// sample data" deletes these so removed restaurants disappear from
  /// Firestore too.
  static const List<String> retiredRestaurantIds = [
    'sample-karachi-biryani',
    'sample-burger-lab',
    'sample-dragon-wok',
    'sample-green-bowl',
    'sample-tikka-junction',
    'sample-bella-napoli',
    'sample-pending-shawarma',
  ];

  static const List<String> retiredMenuItemIds = [
    'sample-kbh-1',
    'sample-kbh-2',
    'sample-kbh-3',
    'sample-kbh-4',
    'sample-kbh-5',
    'sample-kbh-6',
    'sample-burger-1',
    'sample-burger-2',
    'sample-burger-3',
    'sample-burger-4',
    'sample-burger-5',
    'sample-burger-6',
    'sample-burger-7',
    'sample-wok-1',
    'sample-wok-2',
    'sample-wok-3',
    'sample-wok-4',
    'sample-wok-5',
    'sample-wok-6',
    'sample-greenbowl-1',
    'sample-greenbowl-2',
    'sample-greenbowl-3',
    'sample-greenbowl-4',
    'sample-greenbowl-5',
    'sample-tikka-1',
    'sample-tikka-2',
    'sample-tikka-3',
    'sample-tikka-4',
    'sample-tikka-5',
    'sample-tikka-6',
    'sample-tikka-7',
    'sample-napoli-1',
    'sample-napoli-2',
    'sample-napoli-3',
    'sample-napoli-4',
    'sample-napoli-5',
    'sample-napoli-6',
    'sample-napoli-7',
    'sample-shawarma-1',
    'sample-shawarma-2',
  ];
}
