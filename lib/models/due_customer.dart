import 'due_transaction.dart';

class DueCustomer {
  final String id;
  String name;
  String phone;
  final List<DueTransaction> transactions;

  DueCustomer({
    required this.id,
    required this.name,
    this.phone = '',
    List<DueTransaction>? transactions,
  }) : transactions = transactions ?? [];

  double get totalDue =>
      transactions.fold(0, (sum, t) => sum + t.signedAmount);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'transactions': transactions.map((e) => e.toMap()).toList(),
    };
  }

  factory DueCustomer.fromMap(Map<dynamic, dynamic> map) {
    return DueCustomer(
      id: map['id'] as String,
      name: map['name'] as String,
      phone: (map['phone'] as String?) ?? '',
      transactions: (map['transactions'] as List)
          .map((e) =>
              DueTransaction.fromMap(Map<dynamic, dynamic>.from(e as Map)))
          .toList(),
    );
  }
}
