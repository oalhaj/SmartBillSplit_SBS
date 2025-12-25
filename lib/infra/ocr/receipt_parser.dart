class ReceiptLineItem {
  const ReceiptLineItem({
    required this.name,
    required this.quantity,
    required this.unitPrice,
  });

  final String name;
  final int quantity;
  final double unitPrice;

  double get totalPrice => quantity * unitPrice;
}

class ReceiptParseResult {
  const ReceiptParseResult({
    required this.items,
    this.subtotal,
    this.tax,
    this.serviceCharge,
    this.total,
    this.merchantName,
  });

  final List<ReceiptLineItem> items;
  final double? subtotal;
  final double? tax;
  final double? serviceCharge;
  final double? total;
  final String? merchantName;
}

class ReceiptParser {
  static final _priceRegex = RegExp(r'(\d+[.,]\d{2})');
  static final _quantityRegex = RegExp(r'^\s*(\d+)\s*[xX]\s*(.+)');

  ReceiptParseResult parse(String text) {
    final lines = text
        .split(RegExp(r'\n+'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    final items = <ReceiptLineItem>[];
    double? subtotal;
    double? tax;
    double? service;
    double? total;
    String? merchantName;

    for (final line in lines) {
      final lower = line.toLowerCase();
      merchantName ??= _maybeMerchant(lower, line);
      final price = _extractPrice(line);
      if (price == null) {
        continue;
      }
      if (lower.contains('total')) {
        total ??= price;
        continue;
      }
      if (lower.contains('tax')) {
        tax ??= price;
        continue;
      }
      if (lower.contains('service') || lower.contains('svc')) {
        service ??= price;
        continue;
      }
      if (lower.contains('subtotal')) {
        subtotal ??= price;
        continue;
      }

      final quantityMatch = _quantityRegex.firstMatch(line);
      if (quantityMatch != null) {
        final quantity = int.tryParse(quantityMatch.group(1) ?? '1') ?? 1;
        final name = quantityMatch.group(2) ?? 'Item';
        items.add(
          ReceiptLineItem(name: name.trim(), quantity: quantity, unitPrice: price),
        );
      } else {
        items.add(
          ReceiptLineItem(name: line, quantity: 1, unitPrice: price),
        );
      }
    }

    return ReceiptParseResult(
      items: items,
      subtotal: subtotal,
      tax: tax,
      serviceCharge: service,
      total: total,
      merchantName: merchantName,
    );
  }

  double? _extractPrice(String line) {
    final match = _priceRegex.allMatches(line).lastOrNull;
    if (match == null) {
      return null;
    }
    final raw = match.group(1) ?? '';
    return double.tryParse(raw.replaceAll(',', '.'));
  }

  String? _maybeMerchant(String lower, String line) {
    if (lower.contains('receipt') || lower.contains('tax invoice')) {
      return null;
    }
    if (line.length > 3 && line.length < 32 && !line.contains(RegExp(r'\d'))) {
      return line;
    }
    return null;
  }
}

extension _IterableMatch on Iterable<RegExpMatch> {
  RegExpMatch? get lastOrNull => isEmpty ? null : last;
}
