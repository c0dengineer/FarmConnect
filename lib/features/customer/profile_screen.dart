import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:farmconnect/all.dart';
import 'package:farmconnect/features/common/address_sheet.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _editProfile(BuildContext context, WidgetRef ref, AppUser u) async {
    final name = TextEditingController(text: u.name);
    final phone = TextEditingController(text: u.phone);
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Edit profile'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          AppField(controller: name, label: 'Name'),
          const SizedBox(height: 12),
          AppField(controller: phone, label: 'Phone', keyboardType: TextInputType.phone),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel', style: TextStyle(color: AppColors.muted))),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Save')),
        ],
      ),
    );
    if (ok == true && name.text.trim().isNotEmpty) {
      await ref.read(authRepoProvider).updateProfile(u.uid, name: name.text, phone: phone.text);
    }
  }

  void _addresses(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Consumer(builder: (ctx, ref, __) {
        final u = ref.watch(currentUserProvider).valueOrNull;
        if (u == null) return const SizedBox();
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Expanded(child: Text('Saved addresses', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800))),
              TextButton.icon(onPressed: () => showAddAddressSheet(ctx, ref, u), icon: const Icon(Icons.add_rounded), label: const Text('Add')),
            ]),
            if (u.addresses.isEmpty) const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Text('No addresses saved.', style: TextStyle(color: AppColors.muted))),
            for (var i = 0; i < u.addresses.length; i++)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.place_outlined, color: AppColors.primary),
                title: Text(u.addresses[i].label, style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(u.addresses[i].full),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
                  onPressed: () => ref.read(authRepoProvider).saveAddresses(u.uid, [...u.addresses]..removeAt(i)),
                ),
              ),
            const SizedBox(height: 8),
          ]),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final u = ref.watch(currentUserProvider).valueOrNull;
    final orders = ref.watch(customerOrdersProvider).valueOrNull ?? [];
    if (u == null) return const LoadingView();
    final delivered = orders.where((o) => o.status == OrderStatus.delivered).toList();
    final spent = delivered.fold<double>(0, (s, o) => s + o.total);
    final rescued = delivered.expand((o) => o.items).where((i) => i.isUgly).fold<double>(0, (s, i) => s + i.qty);
    final milesKm = delivered.fold<double>(0, (s, o) => s + o.distanceKm);
    final farms = ref.watch(farmsProvider).valueOrNull ?? [];
    final followedFarms = farms.where((f) => u.followedFarmIds.contains(f.id)).toList();
    final harvestAlerts = ref.watch(followedAlertsProvider).valueOrNull ?? [];

    Widget item(IconData icon, String title, VoidCallback onTap, {String? trailing}) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: AppCard(
            onTap: onTap,
            child: Row(children: [
              Icon(icon, color: AppColors.primary),
              const SizedBox(width: 14),
              Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w600))),
              if (trailing != null) Text(trailing, style: const TextStyle(color: AppColors.muted)),
              const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
            ]),
          ),
        );

    return SafeArea(
      child: ListView(padding: const EdgeInsets.fromLTRB(20, 16, 20, 24), children: [
        Row(children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: AppColors.primarySoft,
            child: Text(u.name.isEmpty ? '?' : u.name[0].toUpperCase(), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.primary)),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(u.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            Text(u.email, style: const TextStyle(color: AppColors.muted)),
          ])),
          IconButton(onPressed: () => _editProfile(context, ref, u), icon: const Icon(Icons.edit_outlined)),
        ]),
        const SizedBox(height: 10),
        AppCard(color: AppColors.accentSoft, onTap: () => context.push('/feed'), child: Row(children: [
          const Icon(Icons.notifications_active_outlined, color: AppColors.accent), const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Harvest alert', style: TextStyle(fontWeight: FontWeight.w700)), Text(harvestAlerts.isEmpty ? 'Follow farms to get harvest updates.' : harvestAlerts.first.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12))])),
          Text('${harvestAlerts.length}', style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.w700)),
        ])),
        const SizedBox(height: 12),
        SectionHeader('Subscribed & favourite farms', action: 'Manage (${followedFarms.length})', onAction: () => context.push('/favorites')),
        if (followedFarms.isEmpty)
          AppCard(onTap: () => context.go('/customer?tab=1'), child: const Row(children: [Icon(Icons.favorite_border_rounded, color: AppColors.primary), SizedBox(width: 10), Expanded(child: Text('Follow a local farm to see harvests here.')), Icon(Icons.chevron_right_rounded)]))
        else ...followedFarms.take(4).map((f) => Padding(padding: const EdgeInsets.only(bottom: 8), child: FarmTile(farm: f))),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: _stat('${delivered.length}', 'Orders')),
          const SizedBox(width: 10),
          Expanded(child: _stat(money(spent), 'Spent')),
          const SizedBox(width: 10),
          Expanded(child: _stat(formatQuantity(rescued), 'Items rescued')),
        ]),
        const SizedBox(height: 10),
        AppCard(
          color: AppColors.primarySoft,
          child: Row(children: [
            const Icon(Icons.eco_outlined, color: AppColors.primary, size: 26),
            const SizedBox(width: 12),
            Expanded(child: Text('Your food has travelled only ${milesKm.toStringAsFixed(0)} km in total. Local food means fewer food-miles.', style: const TextStyle(fontSize: 13))),
          ]),
        ),
        const SizedBox(height: 20),
        item(Icons.favorite_border_rounded, 'Favourites', () => context.push('/favorites'), trailing: '${u.favoriteProductIds.length}'),
        item(Icons.notifications_none_rounded, 'Harvest alerts', () => context.push('/feed'), trailing: '${u.followedFarmIds.length} farms'),
        item(Icons.place_outlined, 'Saved addresses', () => _addresses(context, ref), trailing: '${u.addresses.length}'),
        item(Icons.recycling_rounded, 'Ugly but Fresh', () => context.push('/ugly')),
        const SizedBox(height: 10),
        PrimaryButton(label: 'Sign out', outlined: true, icon: Icons.logout_rounded, onPressed: () => ref.read(authRepoProvider).signOut()),
      ]),
    );
  }

  Widget _stat(String v, String l) => AppCard(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        child: Column(children: [
          Text(v, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(l, style: const TextStyle(color: AppColors.muted, fontSize: 11.5)),
        ]),
      );
}
