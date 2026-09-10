import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/product.dart';
import '../repositories/product_repository.dart';

class ProductProvider extends ChangeNotifier {
  final ProductRepository _repository;
  final _uuid = const Uuid();
  List<Product> _products = [];

  ProductProvider(this._repository) {
    _load();
  }

  List<Product> get products => List.unmodifiable(_products);

  List<Product> get lowStockProducts =>
      _products.where((p) => p.isLowStock).toList();

  void _load() {
    _products = _repository.getAll();
    notifyListeners();
  }

  Product? byId(String id) {
    for (final p in _products) {
      if (p.id == id) return p;
    }
    return null;
  }

  Future<void> addProduct({
    required String name,
    required double buyPrice,
    required double sellPrice,
    required int quantity,
    int lowStockThreshold = 5,
  }) async {
    final product = Product(
      id: _uuid.v4(),
      name: name,
      buyPrice: buyPrice,
      sellPrice: sellPrice,
      quantity: quantity,
      lowStockThreshold: lowStockThreshold,
    );
    await _repository.save(product);
    _load();
  }

  Future<void> updateProduct(Product product) async {
    await _repository.save(product);
    _load();
  }

  Future<void> deleteProduct(String id) async {
    await _repository.delete(id);
    _load();
  }

  /// Decrements stock after a sale. Called by SaleProvider.
  Future<void> decrementStock(String productId, int quantitySold) async {
    final product = byId(productId);
    if (product == null) return;
    product.quantity = (product.quantity - quantitySold).clamp(0, 1 << 31);
    await _repository.save(product);
    _load();
  }

  /// Restores stock, used when a sale is deleted/reverted.
  Future<void> incrementStock(String productId, int quantity) async {
    final product = byId(productId);
    if (product == null) return;
    product.quantity += quantity;
    await _repository.save(product);
    _load();
  }
}
