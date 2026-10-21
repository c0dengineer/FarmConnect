import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:farmconnect/all.dart';

/// Farmer posts harvest alerts; followers get a push notification (via Cloud Function).
class FarmerAlertsScreen extends ConsumerWidget {
  const FarmerAlertsScreen({super.key});

  void _compose(BuildContext context, WidgetRef ref) {
    final farm = ref.read(myFarmProvider).valueOrNull;
    if (farm == null) {
      showMsg(context, 'Create your farm profile first.');
      context.push('/farm-edit');
      return;
    }
    final title = TextEditingController();
    final msg = TextEditingController();
    final form = GlobalKey<FormState>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Form(
          key: form,
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('New harvest alert', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            const Text('Everyone following your farm will be notified.', style: TextStyle(color: AppColors.muted)),
            const SizedBox(height: 16),
            AppField(controller: title, label: 'Title (e.g. Fresh tomatoes tomorrow)', validator: requiredValidator),
            const SizedBox(height: 12),
            AppField(controller: msg, label: 'Message', maxLines: 3, validator: requiredValidator),
            const SizedBox(height: 18),
            PrimaryButton(
              label: 'Send alert',
              icon: Icons.send_rounded,
              onPressed: () async {
                if (!form.currentState!.validate()) return;
                try {
                  await ref.read(alertRepoProvider).post(HarvestAlert(
                        id: '',
                        farmerUid: farm.id,
                        farmName: farm.farmName,
                        title: title.text.trim(),
                        message: msg.text.trim(),
                        createdAt: DateTime.now(),
                      ));
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (context.mounted) showMsg(context, 'Alert posted');
                } catch (e) {
                  if (ctx.mounted) showMsg(ctx, e.toString());
                }
              },
            ),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myAlertsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Harvest alerts')),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: () => _compose(context, ref),
        icon: const Icon(Icons.campaign_rounded),
        label: const Text('New alert'),
      ),
      body: async.whenUi((alerts) {
        if (alerts.isEmpty) {
          return const EmptyState(icon: Icons.campaign_outlined, title: 'No alerts yet', subtitle: 'Tell followers about a fresh or upcoming harvest.');
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
          itemCount: alerts.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) {
            final a = alerts[i];
            return AppCard(
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(a.title, style: const TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text(a.message),
                    const SizedBox(height: 6),
                    Text(fmtDateTime(a.createdAt), style: const TextStyle(color: AppColors.muted, fontSize: 11.5)),
                  ]),
                ),
                IconButton(icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger), onPressed: () => ref.read(alertRepoProvider).delete(a.id)),
              ]),
            );
          },
        );
      }),
    );
  }
}
