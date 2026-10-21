import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:farmconnect/app/theme.dart';
import 'package:farmconnect/core/utils/formatters.dart';
import 'package:farmconnect/core/utils/freshness.dart';
import 'package:farmconnect/models/farm.dart';
import 'package:farmconnect/models/order.dart';
import 'package:farmconnect/models/product.dart';

/// White rounded card with a hairline border - the base surface of the whole app.
class AppCard extends StatelessWidget {
  const AppCard({super.key, required this.child, this.padding = const EdgeInsets.all(14), this.onTap, this.color});
  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(16);
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(color: color ?? Colors.white, borderRadius: r, border: Border.all(color: AppColors.border.withValues(alpha: .48))),
      child: Material(
        color: Colors.transparent,
        child: InkWell(onTap: onTap, child: Padding(padding: padding, child: child)),
      ),
    );
  }
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
    this.icon,
    this.outlined = false,
    this.danger = false,
    this.expand = true,
  });
  final String label;
  final VoidCallback? onPressed;
  final bool loading, outlined, danger, expand;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final child = loading
        ? SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(strokeWidth: 2.4, color: outlined ? AppColors.primary : Colors.white))
        : Row(mainAxisSize: MainAxisSize.min, children: [
            if (icon != null) ...[Icon(icon, size: 18), const SizedBox(width: 8)],
            Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
          ]);
    final cb = loading ? null : onPressed;
    final btn = outlined
        ? OutlinedButton(
            onPressed: cb,
            style: danger ? OutlinedButton.styleFrom(foregroundColor: AppColors.danger) : null,
            child: child)
        : ElevatedButton(
            onPressed: cb,
            style: danger ? ElevatedButton.styleFrom(backgroundColor: AppColors.danger) : null,
            child: child);
    return expand ? SizedBox(width: double.infinity, child: btn) : btn;
  }
}

class AppField extends StatelessWidget {
  const AppField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.keyboardType,
    this.obscure = false,
    this.validator,
    this.maxLines = 1,
    this.prefixIcon,
    this.suffix,
    this.readOnly = false,
    this.onTap,
    this.onChanged,
  });
  final TextEditingController controller;
  final String label;
  final String? hint;
  final TextInputType? keyboardType;
  final bool obscure, readOnly;
  final String? Function(String?)? validator;
  final int maxLines;
  final IconData? prefixIcon;
  final Widget? suffix;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      validator: validator,
      maxLines: obscure ? 1 : maxLines,
      readOnly: readOnly,
      onTap: onTap,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: prefixIcon == null ? null : Icon(prefixIcon, size: 20, color: AppColors.muted),
        suffixIcon: suffix,
      ),
    );
  }
}

String? requiredValidator(String? v, [String msg = 'This field is required']) =>
    (v == null || v.trim().isEmpty) ? msg : null;

class Pill extends StatelessWidget {
  const Pill(this.text, {super.key, this.color = AppColors.primary, this.bg, this.icon});
  final String text;
  final Color color;
  final Color? bg;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(color: bg ?? color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[Icon(icon, size: 13, color: color), const SizedBox(width: 4)],
        Text(text, style: TextStyle(color: color, fontSize: 11.5, fontWeight: FontWeight.w700)),
      ]),
    );
  }
}

class StatusPill extends StatelessWidget {
  const StatusPill(this.status, {super.key});
  final String status;

  @override
  Widget build(BuildContext context) {
    Color c;
    switch (status) {
      case OrderStatus.delivered:
        c = AppColors.primary;
        break;
      case OrderStatus.rejected:
      case OrderStatus.cancelled:
        c = AppColors.danger;
        break;
      case OrderStatus.placed:
        c = AppColors.accent;
        break;
      default:
        c = AppColors.info;
    }
    return Pill(OrderStatus.label(status), color: c);
  }
}

class FreshnessBadge extends StatelessWidget {
  const FreshnessBadge({super.key, required this.score, this.compact = false});
  final int score;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final c = freshnessColor(score);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.eco_rounded, size: 13, color: c),
        const SizedBox(width: 3),
        Text(compact ? '$score%' : '$score% · ${freshnessLabel(score)}',
            style: TextStyle(color: c, fontSize: 11.5, fontWeight: FontWeight.w700)),
      ]),
    );
  }
}

class NetImage extends StatelessWidget {
  const NetImage(this.url, {super.key, this.width, this.height, this.fit = BoxFit.cover, this.radius = 0});
  final String? url;
  final double? width, height, radius;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final ph = Container(
      width: width,
      height: height,
      color: AppColors.primarySoft,
      child: const Icon(Icons.eco_rounded, color: AppColors.primary),
    );
    final r = BorderRadius.circular(radius ?? 0);
    if (url == null || url!.isEmpty) return ClipRRect(borderRadius: r, child: ph);
    return ClipRRect(
      borderRadius: r,
      child: CachedNetworkImage(
        imageUrl: url!,
        width: width,
        height: height,
        fit: fit,
        placeholder: (_, __) => ph,
        errorWidget: (_, __, ___) => ph,
      ),
    );
  }
}

class RatingStars extends StatelessWidget {
  const RatingStars(this.rating, {super.key, this.count, this.size = 15});
  final double rating;
  final int? count;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.star_rounded, size: size, color: AppColors.accent),
      const SizedBox(width: 3),
      Text(rating == 0 ? 'New' : rating.toStringAsFixed(1),
          style: TextStyle(fontSize: size - 2, fontWeight: FontWeight.w700)),
      if (count != null && count! > 0)
        Text(' ($count)', style: TextStyle(fontSize: size - 3, color: AppColors.muted)),
    ]);
  }
}

class RatingInput extends StatelessWidget {
  const RatingInput({super.key, required this.value, required this.onChanged});
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (i) {
        final on = i < value;
        return IconButton(
          onPressed: () => onChanged(i + 1),
          iconSize: 40,
          icon: Icon(on ? Icons.star_rounded : Icons.star_outline_rounded, color: AppColors.accent),
        );
      }),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.title, this.subtitle, this.action});
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: const BoxDecoration(color: AppColors.primarySoft, shape: BoxShape.circle),
            child: Icon(icon, size: 34, color: AppColors.primary),
          ),
          const SizedBox(height: 16),
          Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(subtitle!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.muted)),
          ],
          if (action != null) ...[const SizedBox(height: 18), action!],
        ]),
      ),
    );
  }
}

class LoadingView extends StatelessWidget {
  const LoadingView({super.key});
  @override
  Widget build(BuildContext context) => const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 3),
        ),
      );
}

class ErrorView extends StatelessWidget {
  const ErrorView(this.message, {super.key});
  final String message;
  @override
  Widget build(BuildContext context) =>
      EmptyState(icon: Icons.error_outline_rounded, title: 'Something went wrong', subtitle: message);
}

extension AsyncUi<T> on AsyncValue<T> {
  Widget whenUi(Widget Function(T data) builder) =>
      when(data: builder, loading: () => const LoadingView(), error: (e, _) => ErrorView(e.toString()));
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.action, this.onAction});
  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 22, 0, 12),
      child: Row(children: [
        Expanded(child: Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800))),
        if (action != null)
          GestureDetector(
            onTap: onAction,
            child: Text(action!, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
          ),
      ]),
    );
  }
}

class QtyStepper extends StatelessWidget {
  const QtyStepper({super.key, required this.qty, required this.onChanged, this.max});
  final int qty;
  final int? max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget btn(IconData i, VoidCallback? f) => InkWell(
          onTap: f,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: f == null ? AppColors.bg : AppColors.primarySoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(i, size: 18, color: f == null ? AppColors.muted : AppColors.primary),
          ),
        );
    return Row(mainAxisSize: MainAxisSize.min, children: [
      btn(Icons.remove_rounded, () => onChanged(qty - 1)),
      SizedBox(width: 36, child: Center(child: Text('$qty', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)))),
      btn(Icons.add_rounded, (max != null && qty >= max!) ? null : () => onChanged(qty + 1)),
    ]);
  }
}

class ProductCard extends StatelessWidget {
  const ProductCard({super.key, required this.product, this.distanceKm, this.width});
  final Product product;
  final double? distanceKm, width;

  @override
  Widget build(BuildContext context) {
    final p = product;
    return SizedBox(
      width: width,
      child: AppCard(
        padding: EdgeInsets.zero,
        onTap: () => context.push('/product/${p.id}'),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Stack(children: [
            NetImage(p.imageUrls.isEmpty ? null : p.imageUrls.first, height: 132, width: double.infinity),
            Positioned(left: 8, top: 8, child: FreshnessBadge(score: p.freshness, compact: true)),
            if (p.isUgly && p.uglyDiscountPercent > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Pill('-${p.uglyDiscountPercent}%', color: Colors.white, bg: AppColors.accent),
              ),
          ]),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              const SizedBox(height: 2),
              Text(p.farmName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                  child: Text.rich(
                    TextSpan(children: [
                      TextSpan(text: money(p.effectivePrice), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                      if (p.isUgly && p.uglyDiscountPercent > 0)
                        TextSpan(
                          text: ' ${money(p.price)}',
                          style: const TextStyle(color: AppColors.muted, fontSize: 11.5, decoration: TextDecoration.lineThrough),
                        ),
                      TextSpan(text: ' /${p.unit}', style: const TextStyle(color: AppColors.muted, fontSize: 11.5)),
                    ]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (distanceKm != null) ...[
                  const Icon(Icons.near_me_rounded, size: 12, color: AppColors.muted),
                  const SizedBox(width: 2),
                  Text(fmtDistance(distanceKm), style: const TextStyle(fontSize: 11.5, color: AppColors.muted)),
                ],
              ]),
            ]),
          ),
        ]),
      ),
    );
  }
}

class FarmTile extends StatelessWidget {
  const FarmTile({super.key, required this.farm, this.distanceKm, this.width});
  final Farm farm;
  final double? distanceKm, width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: AppCard(
        onTap: () => context.push('/farm/${farm.id}'),
        child: Row(children: [
          NetImage(farm.photoUrls.isEmpty ? null : farm.photoUrls.first, width: 56, height: 56, radius: 14),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Row(children: [
                Flexible(child: Text(farm.farmName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700))),
                if (farm.isVerified) const Padding(padding: EdgeInsets.only(left: 4), child: Icon(Icons.verified_rounded, size: 16, color: AppColors.info)),
              ]),
              const SizedBox(height: 4),
              RatingStars(farm.ratingAvg, count: farm.ratingCount, size: 14),
              const SizedBox(height: 2),
              Text(
                [if (distanceKm != null) fmtDistance(distanceKm), farm.farmingType].join(' · '),
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

Future<bool> confirmDialog(BuildContext context, String title, String message, {String confirm = 'Confirm', bool danger = false}) async {
  final res = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel', style: TextStyle(color: AppColors.muted))),
        TextButton(
          onPressed: () => Navigator.pop(c, true),
          child: Text(confirm, style: TextStyle(color: danger ? AppColors.danger : AppColors.primary, fontWeight: FontWeight.w700)),
        ),
      ],
    ),
  );
  return res ?? false;
}

void showMsg(BuildContext context, String text) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));
}
