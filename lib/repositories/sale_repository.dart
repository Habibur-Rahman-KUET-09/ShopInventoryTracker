import '../models/sale.dart';
import 'hive_boxes.dart';

class SaleRepository {
  List<Sale> getAll() {
    final sales = HiveBoxes.sales.values.map((e) => Sale.fromMap(e)).toList()
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
    return sales;
  }

  Future<void> save(Sale sale) async {
    await HiveBoxes.sales.put(sale.id, sale.toMap());
  }

  Future<void> delete(String id) async {
    await HiveBoxes.sales.delete(id);
  }
}
