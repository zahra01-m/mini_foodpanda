import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/notification_service.dart';
import 'auth_provider.dart';

final notificationServiceProvider = Provider((ref) => NotificationService());

/// The signed-in user's notification inbox, live from Firestore.
final notificationsStreamProvider = StreamProvider<List<AppNotification>>((ref) {
  final uid = ref.watch(authProvider.select((s) => s.user?.id));
  if (uid == null) return Stream.value(const <AppNotification>[]);
  return ref.watch(notificationServiceProvider).watchFor(uid);
});
