import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/sale.dart';
import '../models/sale_item.dart';
import '../repositories/sale_repository.dart';
import 'product_provider.dart';

class SaleProvider extends ChangeNotifier {
  final SaleRepository _repository;
  final ProductProvider _productProvider;
  final _uuid = const Uuid();
  List<Sale> _sales = [];

  SaleProvider(this._repository, this._productProvider) {
    _load();
  }

  List<Sale> get sales => List.unmodifiable(_sales);

  List<Sale> salesOn(DateTime day) {
    return _sales
        .where((s) =>
            s.dateTime.year == day.year &&
            s.dateTime.month == day.month &&
            s.dateTime.day == day.day)
        .toList();
  }

  List<Sale> salesBetween(DateTime start, DateTime endInclusive) {
    final startOfDay = DateTime(start.year, start.month, start.day);
    final endOfDay =
        DateTime(endInclusive.year, endInclusive.month, endInclusive.day, 23, 59, 59);
    return _sales
        .where((s) => !s.dateTime.isBefore(startOfDay) && !s.dateTime.isAfter(endOfDay))
        .toList();
  }

  void _load() {
    _sales = _repository.getAll();
    notifyListeners();
  }

  Future<void> addSale(List<SaleItem> items) async {
    if (items.isEmpty) return;
    final sale = Sale(id: _uuid.v4(), dateTime: DateTime.now(), items: items);
    await _repository.save(sale);
    for (final item in items) {
      await _productProvider.decrementStock(item.productId, item.quantity);
    }
    _load();
  }

  Future<void> deleteSale(String id) async {
    final sale = _sales.firstWhere((s) => s.id == id);
    for (final item in sale.items) {
      await _productProvider.incrementStock(item.productId, item.quantity);
    }
    await _repository.delete(id);
    _load();
  }
}
