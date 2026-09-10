import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/due_customer.dart';
import '../models/due_transaction.dart';
import '../repositories/due_repository.dart';

class DueProvider extends ChangeNotifier {
  final DueRepository _repository;
  final _uuid = const Uuid();
  List<DueCustomer> _customers = [];

  DueProvider(this._repository) {
    _load();
  }

  List<DueCustomer> get customers => List.unmodifiable(_customers);

  double get totalOutstanding =>
      _customers.fold(0, (sum, c) => sum + c.totalDue);

  void _load() {
    _customers = _repository.getAll();
    notifyListeners();
  }

  DueCustomer? byId(String id) {
    for (final c in _customers) {
      if (c.id == id) return c;
    }
    return null;
  }

  Future<DueCustomer> addCustomer({
    required String name,
    String phone = '',
    double initialDue = 0,
  }) async {
    final customer = DueCustomer(id: _uuid.v4(), name: name, phone: phone);
    if (initialDue > 0) {
      customer.transactions.add(DueTransaction(
        id: _uuid.v4(),
        amount: initialDue,
        type: DueTransactionType.added,
      ));
    }
    await _repository.save(customer);
    _load();
    return customer;
  }

  Future<void> addTransaction(
    String customerId,
    double amount,
    DueTransactionType type, {
    String note = '',
  }) async {
    final customer = byId(customerId);
    if (customer == null) return;
    customer.transactions.add(DueTransaction(
      id: _uuid.v4(),
      amount: amount,
      type: type,
      note: note,
    ));
    await _repository.save(customer);
    _load();
  }

  Future<void> deleteCustomer(String id) async {
    await _repository.delete(id);
    _load();
  }
}
