class SaleItem {
  final String productId;
  final String productName;
  final int quantity;
  final double sellPrice;
  final double buyPrice;

  SaleItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.sellPrice,
    required this.buyPrice,
  });

  double get total => sellPrice * quantity;
  double get profit => (sellPrice - buyPrice) * quantity;

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'sellPrice': sellPrice,
      'buyPrice': buyPrice,
    };
  }

  factory SaleItem.fromMap(Map<dynamic, dynamic> map) {
    return SaleItem(
      productId: map['productId'] as String,
      productName: map['productName'] as String,
      quantity: map['quantity'] as int,
      sellPrice: (map['sellPrice'] as num).toDouble(),
      buyPrice: (map['buyPrice'] as num).toDouble(),
    );
  }
}
