import 'package:uuid/uuid.dart';

class BillItem {
  BillItem({
    String? id,
    required this.name,
    required this.quantity,
    required this.unitPrice,
  })  : id = id ?? const Uuid().v4(),
        totalPrice = quantity * unitPrice;

  final String id;
  final String name;
  final int quantity;
  final double unitPrice;
  final double totalPrice;

  BillItem copyWith({
    String? id,
    String? name,
    int? quantity,
    double? unitPrice,
  }) {
    final updatedQuantity = quantity ?? this.quantity;
    final updatedUnitPrice = unitPrice ?? this.unitPrice;
    return BillItem(
      id: id ?? this.id,
      name: name ?? this.name,
      quantity: updatedQuantity,
      unitPrice: updatedUnitPrice,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'quantity': quantity,
        'unitPrice': unitPrice,
      };

  factory BillItem.fromJson(Map<String, dynamic> json) {
    return BillItem(
      id: json['id'] as String?,
      name: json['name'] as String? ?? '',
      quantity: json['quantity'] as int? ?? 1,
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0,
    );
  }
}
