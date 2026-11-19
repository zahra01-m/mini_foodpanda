/// Named-route constants for future migration to a router package
/// (go_router) once the app grows past Navigator.push chains.
class AppRoutes {
  AppRoutes._();

  static const roleSelector = '/';
  static const login = '/login';
  static const signup = '/signup';
  static const restaurantList = '/restaurants';
  static const restaurantDetail = '/restaurants/detail';
  static const cart = '/cart';
  static const checkout = '/checkout';
  static const orderTracking = '/orders/track';
  static const orderHistory = '/orders';
  static const profile = '/profile';
  static const adminDashboard = '/admin';
  static const adminVendors = '/admin/vendors';
  static const adminOrders = '/admin/orders';
  static const adminAnalytics = '/admin/analytics';
}
