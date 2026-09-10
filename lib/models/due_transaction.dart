enum DueTransactionType { added, paid }

class DueTransaction {
  final String id;
  final double amount;
  final DueTransactionType type;
  final DateTime date;
  final String note;

  DueTransaction({
    required this.id,
    required this.amount,
    required this.type,
    DateTime? date,
    this.note = '',
  }) : date = date ?? DateTime.now();

  /// Signed amount: positive for বাকি যোগ, negative for পরিশোধ.
  double get signedAmount => type == DueTransactionType.added ? amount : -amount;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'type': type.name,
      'date': date.toIso8601String(),
      'note': note,
    };
  }

  factory DueTransaction.fromMap(Map<dynamic, dynamic> map) {
    return DueTransaction(
      id: map['id'] as String,
      amount: (map['amount'] as num).toDouble(),
      type: DueTransactionType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => DueTransactionType.added,
      ),
      date: DateTime.parse(map['date'] as String),
      note: (map['note'] as String?) ?? '',
    );
  }
}
