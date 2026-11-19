import '../../core/utils/error_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_palette.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../widgets/skeleton_list.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/fade_slide_in.dart';

/// Shows what would arrive as push notifications in a real build — see
/// [NotificationService] for how order-status changes land here.
class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  /// Ids that were unread when the inbox was opened. Everything is marked
  /// read straight away, so without this snapshot the screen could never
  /// show which items were new.
  Set<String> _newIds = const {};

  @override
  void initState() {
    super.initState();
    // Mark as read once the person actually opens the inbox.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final current = ref.read(notificationsStreamProvider).valueOrNull ?? const [];
      setState(() => _newIds = {for (final n in current) if (!n.read) n.id});
      final uid = ref.read(authProvider).user?.id;
      if (uid != null) ref.read(notificationServiceProvider).markAllRead(uid);
    });
  }

  @override
  Widget build(BuildContext context) {
    final notifications = ref.watch(notificationsStreamProvider);
    final dateFmt = DateFormat('MMM d, h:mm a');
    final p = context.palette;

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: notifications.when(
        loading: () => const SkeletonTileList(),
        error: (e, _) => EmptyState(
          icon: Icons.error_outline,
          title: 'Could not load notifications',
          subtitle: friendlyError(e),
          onRetry: () => ref.invalidate(notificationsStreamProvider),
        ),
        data: (list) => list.isEmpty
            ? const EmptyState(
                icon: Icons.notifications_none,
                title: 'Nothing yet',
                subtitle: 'Updates about your orders will show up here.',
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: list.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (context, i) {
                  final n = list[i];
                  final isNew = _newIds.contains(n.id);
                  return FadeSlideIn(
index: i < 8 ? i : 0,
horizontal: true,
child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: p.redTint,
                      child: Icon(Icons.notifications_outlined, color: p.redDeep),
                    ),
                    title: Row(
                      children: [
                        Flexible(
                          child: Text(n.title,
                              style: TextStyle(fontWeight: isNew ? FontWeight.w800 : FontWeight.w600)),
                        ),
                        if (isNew) ...[
                          const SizedBox(width: 8),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(color: p.red, shape: BoxShape.circle),
                          ),
                        ],
                      ],
                    ),
                    subtitle: Text(n.body),
                    trailing: Text(dateFmt.format(n.createdAt), style: TextStyle(fontSize: 11, color: p.inkSoft)),
                    isThreeLine: true,
                  ),
);
                },
              ),
      ),
    );
  }
}
