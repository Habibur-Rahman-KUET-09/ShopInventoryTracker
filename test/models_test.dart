import 'package:flutter_test/flutter_test.dart';

import 'package:dokan_hisab/models/due_customer.dart';
import 'package:dokan_hisab/models/due_transaction.dart';
import 'package:dokan_hisab/models/product.dart';
import 'package:dokan_hisab/models/sale.dart';
import 'package:dokan_hisab/models/sale_item.dart';

void main() {
  group('Product', () {
    test('isLowStock respects threshold', () {
      final product = Product(
        id: '1',
        name: 'চাল',
        buyPrice: 50,
        sellPrice: 60,
        quantity: 4,
        lowStockThreshold: 5,
      );
      expect(product.isLowStock, isTrue);

      product.quantity = 10;
      expect(product.isLowStock, isFalse);
    });

    test('round-trips through map', () {
      final product = Product(
        id: '1',
        name: 'তেল',
        buyPrice: 150,
        sellPrice: 170,
        quantity: 20,
      );
      final restored = Product.fromMap(product.toMap());
      expect(restored.id, product.id);
      expect(restored.name, product.name);
      expect(restored.buyPrice, product.buyPrice);
      expect(restored.sellPrice, product.sellPrice);
      expect(restored.quantity, product.quantity);
    });
  });

  group('Sale', () {
    test('computes total amount and profit across items', () {
      final sale = Sale(
        id: 's1',
        dateTime: DateTime(2026, 1, 1),
        items: [
          SaleItem(
            productId: 'p1',
            productName: 'চাল',
            quantity: 2,
            sellPrice: 60,
            buyPrice: 50,
          ),
          SaleItem(
            productId: 'p2',
            productName: 'ডাল',
            quantity: 3,
            sellPrice: 100,
            buyPrice: 80,
          ),
        ],
      );

      expect(sale.totalAmount, 2 * 60 + 3 * 100);
      expect(sale.totalProfit, 2 * (60 - 50) + 3 * (100 - 80));
      expect(sale.totalQuantity, 5);
    });
  });

  group('DueCustomer', () {
    test('totalDue nets added and paid transactions', () {
      final customer = DueCustomer(id: 'c1', name: 'রহিম');
      customer.transactions.addAll([
        DueTransaction(
          id: 't1',
          amount: 500,
          type: DueTransactionType.added,
        ),
        DueTransaction(
          id: 't2',
          amount: 200,
          type: DueTransactionType.paid,
        ),
      ]);

      expect(customer.totalDue, 300);
    });
  });
}
