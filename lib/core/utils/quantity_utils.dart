/// Accepts decimal amounts (0.5) and simple fractions (1/2).
double? parseQuantity(String? input) {
  final text = input?.trim() ?? '';
  if (text.isEmpty) return null;

  final fraction = text.split('/');
  final double value;
  if (fraction.length == 2) {
    final numerator = double.tryParse(fraction[0].trim());
    final denominator = double.tryParse(fraction[1].trim());
    if (numerator == null || denominator == null || denominator == 0) return null;
    value = numerator / denominator;
  } else if (fraction.length == 1) {
    final parsed = double.tryParse(text);
    if (parsed == null) return null;
    value = parsed;
  } else {
    return null;
  }

  if (!value.isFinite || value <= 0) return null;
  final normalized = (value * 1000).round() / 1000;
  return normalized > 0 ? normalized : null;
}

String formatQuantity(num value) {
  final amount = value.toDouble();
  if (!amount.isFinite) return '0';
  if (amount == amount.roundToDouble()) return amount.toInt().toString();
  return amount
      .toStringAsFixed(3)
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '');
}

double quantityStepFor(String unit) =>
    const {'kg', 'litre'}.contains(unit.toLowerCase()) ? 0.5 : 1;
