import '../../core/utils/error_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_palette.dart';
import '../../providers/user_provider.dart';
import '../../widgets/skeleton_list.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/fade_slide_in.dart';

/// Riders sign up unapproved (see [AuthService.signUp]) and can't accept
/// deliveries until an admin flips this switch — this is that screen.
class RiderManagementScreen extends ConsumerWidget {
  const RiderManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final riders = ref.watch(ridersProvider);
    final p = context.palette;

    return Scaffold(
      appBar: AppBar(title: const Text('Riders')),
      body: riders.when(
        loading: () => const SkeletonTileList(showTrailing: true),
        error: (e, _) => EmptyState(
          icon: Icons.error_outline,
          title: 'Could not load riders',
          subtitle: friendlyError(e),
          onRetry: () => ref.invalidate(ridersProvider),
        ),
        data: (list) => list.isEmpty
            ? const EmptyState(
                icon: Icons.two_wheeler_outlined,
                title: 'No riders yet',
                subtitle: 'Riders who sign up will appear here for approval.',
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: list.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (context, i) {
                  final r = list[i];
                  return FadeSlideIn(
index: i < 8 ? i : 0,
horizontal: true,
child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: r.isApproved ? p.success.withValues(alpha: 0.15) : p.redTint,
                      child: Icon(Icons.two_wheeler,
                          color: r.isApproved ? p.success : p.redDeep),
                    ),
                    title: Text(r.name),
                    subtitle: Text('${r.email} · ${r.phone}'),
                    trailing: FilterChip(
                      label: Text(r.isApproved ? 'Approved' : 'Approve'),
                      selected: r.isApproved,
                      selectedColor: p.success.withValues(alpha: 0.2),
                      onSelected: (v) => ref.read(userServiceProvider).setApproved(r.id, v),
                    ),
                  ),
);
                },
              ),
      ),
    );
  }
}
