import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:dokan_hisab/models/due_customer.dart';
import 'package:dokan_hisab/models/product.dart';
import 'package:dokan_hisab/models/sale.dart';
import 'package:dokan_hisab/models/sale_item.dart';
import 'package:dokan_hisab/repositories/backup_repository.dart';
import 'package:dokan_hisab/repositories/due_repository.dart';
import 'package:dokan_hisab/repositories/hive_boxes.dart';
import 'package:dokan_hisab/repositories/product_repository.dart';
import 'package:dokan_hisab/repositories/sale_repository.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('dokan_hisab_backup_test');
    Hive.init(tempDir.path);
    await Hive.openBox<Map>(HiveBoxes.productsBox);
    await Hive.openBox<Map>(HiveBoxes.salesBox);
    await Hive.openBox<Map>(HiveBoxes.dueCustomersBox);
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  test('export then import restores every product, sale and due customer',
      () async {
    final productRepo = ProductRepository();
    final saleRepo = SaleRepository();
    final dueRepo = DueRepository();

    await productRepo.save(Product(
      id: 'p1',
      name: 'চাল',
      brand: 'নাম-ব্র্যান্ড',
      buyPrice: 50,
      sellPrice: 60,
      quantity: 10,
    ));
    await saleRepo.save(Sale(
      id: 's1',
      dateTime: DateTime(2026, 1, 1, 10, 30),
      items: [
        SaleItem(
          productId: 'p1',
          productName: 'চাল',
          quantity: 2,
          sellPrice: 60,
          buyPrice: 50,
        ),
      ],
      customerId: 'c1',
      customerName: 'রহিম',
    ));
    final customer = DueCustomer(id: 'c1', name: 'রহিম', phone: '017xxxxxxx');
    await dueRepo.save(customer);

    final json = BackupRepository().exportJson();

    // Wipe everything, then restore from the exported JSON.
    await HiveBoxes.products.clear();
    await HiveBoxes.sales.clear();
    await HiveBoxes.dueCustomers.clear();
    expect(productRepo.getAll(), isEmpty);

    await BackupRepository().importJson(json);

    final restoredProducts = productRepo.getAll();
    expect(restoredProducts, hasLength(1));
    expect(restoredProducts.single.name, 'চাল');
    expect(restoredProducts.single.brand, 'নাম-ব্র্যান্ড');

    final restoredSales = saleRepo.getAll();
    expect(restoredSales, hasLength(1));
    expect(restoredSales.single.customerName, 'রহিম');

    final restoredCustomers = dueRepo.getAll();
    expect(restoredCustomers, hasLength(1));
    expect(restoredCustomers.single.name, 'রহিম');
  });

  test('importJson rejects a file that is not a দোকান হিসাব backup', () async {
    expect(
      () => BackupRepository().importJson('{"hello": "world"}'),
      throwsFormatException,
    );
  });
}
