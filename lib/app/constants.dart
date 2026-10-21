import 'package:flutter/material.dart';

class AppConstants {
  static const appName = 'FarmConnect';

  /// Category -> default shelf life in days.
  static const categoryShelfLife = <String, int>{
    'Vegetables': 7,
    'Fruits': 7,
    'Leafy Greens': 3,
    'Dairy': 2,
    'Eggs': 14,
    'Grains': 90,
    'Pulses': 90,
    'Herbs & Spices': 10,
    'Other': 7,
  };

  static const categoryIcons = <String, IconData>{
    'Vegetables': Icons.eco_outlined,
    'Fruits': Icons.local_florist_outlined,
    'Leafy Greens': Icons.grass_outlined,
    'Dairy': Icons.water_drop_outlined,
    'Eggs': Icons.egg_alt_outlined,
    'Grains': Icons.grain_outlined,
    'Pulses': Icons.circle_outlined,
    'Herbs & Spices': Icons.spa_outlined,
    'Other': Icons.shopping_basket_outlined,
  };

  static List<String> get categories => categoryShelfLife.keys.toList();
  static const units = ['kg', 'g', 'dozen', 'piece', 'litre', 'bunch'];

  /// "Ugly but Fresh" items must stay at least this fresh to be listed.
  static const uglyMinFreshness = 50;

  static const baseDeliveryFee = 20.0;
  static const perKmDeliveryFee = 3.0;
  static const defaultLat = 19.0760; // Mumbai
  static const defaultLng = 72.8777;
}
