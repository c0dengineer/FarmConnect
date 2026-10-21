import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:farmconnect/all.dart';

/// Used by both customers and farmers. Buttons shown depend on the signed-in role.
class OrderDetailScreen extends ConsumerWidget {
  const OrderDetailScreen({super.key, required this.id});
  final String id;

  Future<void> _change(BuildContext context, WidgetRef ref, FarmOrder o, String status, bool destructive) async {
    if (destructive) {
      final ok = await confirmDialog(context, status == OrderStatus.cancelled ? 'Cancel this order?' : 'Reject this order?',
          'The reserved stock will be released.', confirm: 'Yes', danger: true);
      if (!ok) return;
    }
    try {
      await ref.read(orderRepoProvider).updateStatus(o, status);
    } catch (e) {
      if (context.mounted) showMsg(context, e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _showDirectUpi(BuildContext context, FarmOrder o) async {
    final uri = Uri(scheme: 'upi', host: 'pay', queryParameters: {
      'pa': o.paymentUpiId,
      'pn': o.farmName,
      'am': o.total.toStringAsFixed(2),
      'cu': 'INR',
      'tn': 'FarmConnect order ${o.id}',
      'tr': o.id,
    });
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('Pay ${money(o.total)} to ${o.farmName}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(o.paymentUpiId, style: const TextStyle(color: AppColors.muted)),
            const SizedBox(height: 12),
            QrImageView(data: uri.toString(), size: 220, backgroundColor: Colors.white),
            const SizedBox(height: 8),
            const Text('Scan this QR with any UPI app. Payment stays pending until the farmer confirms receipt.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.muted)),
            const SizedBox(height: 14),
            PrimaryButton(label: 'Open a UPI app', icon: Icons.open_in_new_rounded, onPressed: () async {
              try {
                final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
                if (!opened && sheetContext.mounted) showMsg(sheetContext, 'No UPI app opened. Scan the QR from another device.');
              } catch (_) {
                if (sheetContext.mounted) showMsg(sheetContext, 'No UPI app opened. Scan the QR from another device.');
              }
            }),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(orderProvider(id));
    final user = ref.watch(currentUserProvider).valueOrNull;
    final isFarmer = user?.role == Roles.farmer;

    return Scaffold(
      appBar: AppBar(title: const Text('Order tracking')),
      body: async.whenUi((o) {
        if (o == null) return const EmptyState(icon: Icons.receipt_long_outlined, title: 'Order not found');
        final actions = isFarmer ? OrderStatus.farmerActions(o) : <(String, String, bool)>[];
        final canCancel = !isFarmer && o.status == OrderStatus.placed;
        final canReview = !isFarmer && o.status == OrderStatus.delivered && !o.reviewed;

        return ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 28), children: [
          AppCard(
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('#${o.id.substring(0, o.id.length < 6 ? o.id.length : 6).toUpperCase()}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  const SizedBox(height: 2),
                  Text(fmtDateTime(o.createdAt), style: const TextStyle(color: AppColors.muted, fontSize: 12.5)),
                ]),
              ),
              StatusPill(o.status),
            ]),
          ),
          const SectionHeader('Field-to-fork timeline'),
          AppCard(
            child: Column(children: [
              for (var i = 0; i < o.history.length; i++)
                _TimelineRow(entry: o.history[i], last: i == o.history.length - 1),
            ]),
          ),
          SectionHeader('Items from ${o.farmName}'),
          AppCard(
            child: Column(children: [
              for (final it in o.items)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(children: [
                    NetImage(it.imageUrl, width: 44, height: 44, radius: 10),
                    const SizedBox(width: 12),
                    Expanded(child: Text('${formatQuantity(it.qty)} × ${it.name}', style: const TextStyle(fontWeight: FontWeight.w600))),
                    Text(money(it.total), style: const TextStyle(fontWeight: FontWeight.w700)),
                  ]),
                ),
              const Divider(height: 22),
              _kv('Subtotal', money(o.subtotal)),
              const SizedBox(height: 6),
              _kv('Delivery fee', o.fulfillment == 'delivery' ? money(o.deliveryFee) : 'Free'),
              const SizedBox(height: 6),
              _kv('Total', money(o.total), bold: true),
            ]),
          ),
          const SectionHeader('Details'),
          AppCard(
            child: Column(children: [
              _kv(isFarmer ? 'Customer' : 'Farm', isFarmer ? o.customerName : o.farmName),
              if (isFarmer && o.customerPhone.isNotEmpty) ...[const SizedBox(height: 8), _kv('Phone', o.customerPhone)],
              if (!isFarmer && o.farmPhone.isNotEmpty) ...[const SizedBox(height: 8), _kv('Farm contact', o.farmPhone)],
              const SizedBox(height: 8),
              _kv(o.fulfillment == 'delivery' ? 'Deliver to' : 'Pickup', o.address),
              const SizedBox(height: 8),
              _kv('Payment', '${o.paymentMethod == 'cod' ? 'Cash' : o.paymentMethod.toUpperCase()} · ${o.paymentStatus}'),
              if (o.distanceKm > 0) ...[const SizedBox(height: 8), _kv('Distance', fmtDistance(o.distanceKm))],
              if (o.note.isNotEmpty) ...[const SizedBox(height: 8), _kv('Note', o.note)],
            ]),
          ),
          if (!isFarmer && o.paymentMethod == 'upi' && o.paymentStatus != 'paid' &&
              ![OrderStatus.cancelled, OrderStatus.rejected].contains(o.status)) ...[
            const SizedBox(height: 12),
            PrimaryButton(label: 'Pay with UPI / Show QR', icon: Icons.qr_code_2_rounded, onPressed: () => _showDirectUpi(context, o)),
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text('Direct UPI does not send an automatic payment confirmation. Contact the farm with your UPI transaction reference; the farmer verifies it manually.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.muted, fontSize: 12)),
            ),
          ],
          if (isFarmer && o.paymentMethod == 'upi' && o.paymentStatus != 'paid' &&
              ![OrderStatus.cancelled, OrderStatus.rejected].contains(o.status)) ...[
            const SizedBox(height: 12),
            PrimaryButton(label: 'Confirm UPI received', icon: Icons.verified_outlined, onPressed: () async {
              final ok = await confirmDialog(context, 'Confirm payment received?', 'Check your bank or UPI app statement before marking this order as paid.', confirm: 'Confirm payment');
              if (!ok) return;
              try {
                await ref.read(orderRepoProvider).confirmDirectUpiPayment(o.id);
                if (context.mounted) showMsg(context, 'UPI payment marked as received');
              } catch (e) {
                if (context.mounted) showMsg(context, 'Could not update payment: $e');
              }
            }),
          ],
          const SizedBox(height: 20),
          for (final a in actions) ...[
            PrimaryButton(label: a.$1, danger: a.$3, outlined: a.$3, onPressed: () => _change(context, ref, o, a.$2, a.$3)),
            const SizedBox(height: 10),
          ],
          if (canCancel) PrimaryButton(label: 'Cancel order', outlined: true, danger: true, onPressed: () => _change(context, ref, o, OrderStatus.cancelled, true)),
          if (canReview) PrimaryButton(label: 'Rate this order', icon: Icons.star_rounded, onPressed: () => context.push('/review/${o.id}')),
        ]);
      }),
    );
  }

  Widget _kv(String k, String v, {bool bold = false}) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 96, child: Text(k, style: TextStyle(color: bold ? AppColors.text : AppColors.muted, fontWeight: bold ? FontWeight.w800 : FontWeight.w500))),
        Expanded(child: Text(v, textAlign: TextAlign.right, style: TextStyle(fontWeight: bold ? FontWeight.w800 : FontWeight.w600, fontSize: bold ? 16 : 14))),
      ]);
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.entry, required this.last});
  final StatusEntry entry;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Column(children: [
          Container(width: 12, height: 12, margin: const EdgeInsets.only(top: 4), decoration: BoxDecoration(color: last ? AppColors.primary : AppColors.border, shape: BoxShape.circle)),
          if (!last) Expanded(child: Container(width: 2, color: AppColors.border)),
        ]),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(OrderStatus.label(entry.status), style: TextStyle(fontWeight: last ? FontWeight.w800 : FontWeight.w600)),
              Text(fmtDateTime(entry.at), style: const TextStyle(color: AppColors.muted, fontSize: 12)),
            ]),
          ),
        ),
      ]),
    );
  }
}
