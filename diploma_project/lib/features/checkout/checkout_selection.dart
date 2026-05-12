/// Данные выбранного предложения для экранов доставки и оплаты.
class CheckoutSelection {
  const CheckoutSelection({
    required this.medicineId,
    required this.medicineName,
    this.imageUrl,
    required this.sellerName,
    required this.price,
    required this.deliveryText,
  });

  final String medicineId;
  final String medicineName;
  final String? imageUrl;
  final String sellerName;
  final double price;
  final String deliveryText;

  /// Подзаголовок под «Доставка» (без префикса «Доставка», если он есть в тексте API).
  String get deliverySubtitle {
    final t = deliveryText.trim();
    final lower = t.toLowerCase();
    if (lower.startsWith('доставка')) {
      final i = t.indexOf(',');
      if (i >= 0 && i + 1 < t.length) {
        return t.substring(i + 1).trim();
      }
    }
    return t.isEmpty ? '—' : t;
  }

  String get priceLabel => '${price.toStringAsFixed(0)} тг';
}
