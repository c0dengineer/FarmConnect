import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:farmconnect/all.dart';

/// Harvest alerts from farms the customer follows.
class AlertsFeedScreen extends ConsumerWidget {
  const AlertsFeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final async = ref.watch(followedAlertsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Harvest alerts')),
      body: (user?.followedFarmIds.isEmpty ?? true)
          ? const EmptyState(icon: Icons.notifications_none_rounded, title: 'Follow farms to get alerts', subtitle: 'Open any farm and tap "Follow" to hear when new harvests arrive.')
          : async.whenUi((alerts) {
              if (alerts.isEmpty) return const EmptyState(icon: Icons.notifications_none_rounded, title: 'No alerts yet');
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: alerts.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) {
                  final a = alerts[i];
                  return AppCard(
                    onTap: () => context.push('/farm/${a.farmerUid}'),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const CircleAvatar(backgroundColor: AppColors.primarySoft, child: Text('🌾')),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(a.farmName, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                        const SizedBox(height: 2),
                        Text(a.title, style: const TextStyle(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 4),
                        Text(a.message),
                        const SizedBox(height: 6),
                        Text(fmtDateTime(a.createdAt), style: const TextStyle(color: AppColors.muted, fontSize: 11.5)),
                      ])),
                    ]),
                  );
                },
              );
            }),
    );
  }
}
