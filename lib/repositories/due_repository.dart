import '../models/due_customer.dart';
import 'hive_boxes.dart';

class DueRepository {
  List<DueCustomer> getAll() {
    return HiveBoxes.dueCustomers.values
        .map((e) => DueCustomer.fromMap(e))
        .toList()
      ..sort((a, b) => b.totalDue.compareTo(a.totalDue));
  }

  Future<void> save(DueCustomer customer) async {
    await HiveBoxes.dueCustomers.put(customer.id, customer.toMap());
  }

  Future<void> delete(String id) async {
    await HiveBoxes.dueCustomers.delete(id);
  }
}
