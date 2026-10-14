String money(num v) {
  final r = v.roundToDouble();
  return '₹${v == r ? v.toStringAsFixed(0) : v.toStringAsFixed(2)}';
}

const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

String fmtDate(DateTime d) => '${d.day} ${_months[d.month - 1]} ${d.year}';

String fmtDateTime(DateTime d) {
  final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
  final m = d.minute.toString().padLeft(2, '0');
  return '${fmtDate(d)}, $h:$m ${d.hour >= 12 ? 'PM' : 'AM'}';
}

String fmtDistance(double? km) {
  if (km == null) return '--';
  if (km < 1) return '${(km * 1000).round()} m';
  return '${km.toStringAsFixed(1)} km';
}

String harvestedAgo(DateTime d) {
  final diff = DateTime.now().difference(d);
  if (diff.isNegative) return 'Harvest on ${fmtDate(d)}';
  if (diff.inHours < 1) return 'Harvested just now';
  if (diff.inHours < 24) return 'Harvested ${diff.inHours}h ago';
  final days = diff.inDays;
  return 'Harvested $days day${days == 1 ? '' : 's'} ago';
}

bool sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
