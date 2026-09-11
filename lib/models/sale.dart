import 'sale_item.dart';

class Sale {
  final String id;
  final DateTime dateTime;
  final List<SaleItem> items;
  final String? customerId;
  final String? customerName;

  Sale({
    required this.id,
    required this.dateTime,
    required this.items,
    this.customerId,
    this.customerName,
  });

  double get totalAmount => items.fold(0, (sum, item) => sum + item.total);
  double get totalProfit => items.fold(0, (sum, item) => sum + item.profit);
  int get totalQuantity => items.fold(0, (sum, item) => sum + item.quantity);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'dateTime': dateTime.toIso8601String(),
      'items': items.map((e) => e.toMap()).toList(),
      'customerId': customerId,
      'customerName': customerName,
    };
  }

  factory Sale.fromMap(Map<dynamic, dynamic> map) {
    return Sale(
      id: map['id'] as String,
      dateTime: DateTime.parse(map['dateTime'] as String),
      items: (map['items'] as List)
          .map((e) => SaleItem.fromMap(Map<dynamic, dynamic>.from(e as Map)))
          .toList(),
      customerId: map['customerId'] as String?,
      customerName: map['customerName'] as String?,
    );
  }
}
