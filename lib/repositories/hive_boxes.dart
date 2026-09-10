import 'package:hive_flutter/hive_flutter.dart';

/// Central place that opens all Hive boxes used by the app.
/// Data is stored locally on-device only (no backend / cloud sync),
/// matching the v0 demo scope of the product.
class HiveBoxes {
  static const String productsBox = 'products_box';
  static const String salesBox = 'sales_box';
  static const String dueCustomersBox = 'due_customers_box';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox<Map>(productsBox);
    await Hive.openBox<Map>(salesBox);
    await Hive.openBox<Map>(dueCustomersBox);
  }

  static Box<Map> get products => Hive.box<Map>(productsBox);
  static Box<Map> get sales => Hive.box<Map>(salesBox);
  static Box<Map> get dueCustomers => Hive.box<Map>(dueCustomersBox);
}
