import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore collection names — matches the data model in the project spec.
class Col {
  Col._();
  static const users = 'users';
  static const restaurants = 'restaurants';
  static const menuItems = 'menuItems';
  static const orders = 'orders';
  static const riderLocations = 'riderLocations';
  static const reviews = 'reviews';
  static const notifications = 'notifications';
}

/// Reads a Firestore date field defensively. A just-written server
/// timestamp can be null in a local snapshot, so fall back to "now".
DateTime readDate(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  return DateTime.now();
}

double readDouble(dynamic value, [double fallback = 0]) =>
    value is num ? value.toDouble() : fallback;
