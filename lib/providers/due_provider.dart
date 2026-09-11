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

  /// Re-reads all customers from storage. Used after a data import.
  void refresh() => _load();

  DueCustomer? byId(String id) {
    for (final c in _customers) {
      if (c.id == id) return c;
    }
    return null;
  }

  /// Exact (case-insensitive) name match — used to auto-fill an existing
  /// customer's details as soon as their name is typed elsewhere in the app.
  DueCustomer? findByName(String name) {
    final target = name.trim().toLowerCase();
    if (target.isEmpty) return null;
    for (final c in _customers) {
      if (c.name.trim().toLowerCase() == target) return c;
    }
    return null;
  }

  /// Customers whose name contains [query] — powers the name autocomplete
  /// used on the sale and বাকি entry screens.
  List<DueCustomer> searchByName(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const [];
    return _customers
        .where((c) => c.name.toLowerCase().contains(q))
        .toList();
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

  Future<void> updateCustomerInfo(
    String id, {
    required String name,
    required String phone,
  }) async {
    final customer = byId(id);
    if (customer == null) return;
    customer.name = name;
    customer.phone = phone;
    await _repository.save(customer);
    _load();
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

  /// Adds a বাকি entry by customer name: if an existing customer matches
  /// [name], the due is added to their account; otherwise a brand-new
  /// customer is created with [phone] and this as their opening due.
  Future<DueCustomer> addDueByName({
    required String name,
    String phone = '',
    required double amount,
  }) async {
    final existing = findByName(name);
    if (existing != null) {
      if (amount > 0) {
        await addTransaction(existing.id, amount, DueTransactionType.added);
      }
      return existing;
    }
    return addCustomer(name: name, phone: phone, initialDue: amount);
  }

  Future<void> deleteCustomer(String id) async {
    await _repository.delete(id);
    _load();
  }
}
