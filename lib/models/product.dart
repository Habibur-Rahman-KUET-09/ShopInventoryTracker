class Product {
  final String id;
  String name;
  String brand;
  double buyPrice;
  double sellPrice;
  int quantity;
  int lowStockThreshold;
  final DateTime createdAt;

  Product({
    required this.id,
    required this.name,
    this.brand = '',
    required this.buyPrice,
    required this.sellPrice,
    required this.quantity,
    this.lowStockThreshold = 5,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isLowStock => quantity <= lowStockThreshold;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'brand': brand,
      'buyPrice': buyPrice,
      'sellPrice': sellPrice,
      'quantity': quantity,
      'lowStockThreshold': lowStockThreshold,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Product.fromMap(Map<dynamic, dynamic> map) {
    return Product(
      id: map['id'] as String,
      name: map['name'] as String,
      brand: (map['brand'] as String?) ?? '',
      buyPrice: (map['buyPrice'] as num).toDouble(),
      sellPrice: (map['sellPrice'] as num).toDouble(),
      quantity: map['quantity'] as int,
      lowStockThreshold: (map['lowStockThreshold'] as int?) ?? 5,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }
}
