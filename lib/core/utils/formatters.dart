/// Formatting helpers for currency, percentages, etc. Kept dependency-free
/// (no intl NumberFormat) since amounts are simple Taka figures — swap
/// in intl's NumberFormat here if locale-aware formatting is needed later.
class Formatters {
  Formatters._();

  static String currency(double amount) {
    return '৳${amount.toStringAsFixed(0)}';
  }

  static String percentage(double value, {int decimals = 1}) {
    return '${value.toStringAsFixed(decimals)}%';
  }
}
