import '../models/product.dart';
import 'hive_boxes.dart';

class ProductRepository {
  List<Product> getAll() {
    return HiveBoxes.products.values
        .map((e) => Product.fromMap(e))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  Future<void> save(Product product) async {
    await HiveBoxes.products.put(product.id, product.toMap());
  }

  Future<void> delete(String id) async {
    await HiveBoxes.products.delete(id);
  }
}
