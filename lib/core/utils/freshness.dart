import 'package:flutter/material.dart';
import 'package:farmconnect/app/theme.dart';

/// 100 = harvested just now, 0 = shelf life over. Future harvest (pre-order) = 100.
int freshnessScore(DateTime harvestDate, int shelfLifeDays) {
  if (shelfLifeDays <= 0) return 0;
  final ageDays = DateTime.now().difference(harvestDate).inMinutes / (60 * 24);
  final score = 100 * (1 - ageDays / shelfLifeDays);
  return score.clamp(0, 100).round();
}

String freshnessLabel(int s) {
  if (s >= 90) return 'Just harvested';
  if (s >= 70) return 'Very fresh';
  if (s >= 40) return 'Fresh';
  return 'Use soon';
}

Color freshnessColor(int s) {
  if (s >= 70) return AppColors.primary;
  if (s >= 40) return AppColors.accent;
  return AppColors.danger;
}

/// Suggested automatic discount (%) as freshness drops.
int suggestedDiscount(int s) {
  if (s < 40) return 25;
  if (s < 60) return 10;
  return 0;
}
