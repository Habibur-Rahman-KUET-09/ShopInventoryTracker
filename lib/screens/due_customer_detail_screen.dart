import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/due_customer.dart';
import '../models/due_transaction.dart';
import '../providers/due_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

class DueCustomerDetailScreen extends StatelessWidget {
  final String customerId;

  const DueCustomerDetailScreen({super.key, required this.customerId});

  Future<void> _addTransaction(
    BuildContext context,
    DueTransactionType type,
  ) async {
    final amountCtrl = TextEditingController();
    final result = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          type == DueTransactionType.added ? 'বাকি যোগ করুন' : 'পরিশোধ যোগ করুন',
        ),
        content: TextField(
          controller: amountCtrl,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'পরিমাণ (৳)'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('বাতিল'),
          ),
          TextButton(
            onPressed: () {
              final amount = double.tryParse(amountCtrl.text);
              Navigator.of(ctx).pop(amount);
            },
            child: const Text('সংরক্ষণ করুন'),
          ),
        ],
      ),
    );
    if (result != null && result > 0 && context.mounted) {
      await context
          .read<DueProvider>()
          .addTransaction(customerId, result, type);
    }
  }

  Future<void> _confirmDeleteCustomer(
      BuildContext context, DueCustomer customer) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('গ্রাহক মুছবেন?'),
        content: Text('"${customer.name}" এর সব হিসাব মুছে যাবে।'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('বাতিল')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('মুছুন', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<DueProvider>().deleteCustomer(customer.id);
      if (context.mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final customer = context.watch<DueProvider>().byId(customerId);
    if (customer == null) {
      return const Scaffold(body: Center(child: Text('গ্রাহক পাওয়া যায়নি')));
    }
    final transactions = customer.transactions.reversed.toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(customer.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _confirmDeleteCustomer(context, customer),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: customer.totalDue > 0
                  ? AppTheme.dangerRed
                  : AppTheme.primaryGreen,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                const Text('মোট বাকি',
                    style: TextStyle(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 4),
                Text(
                  Formatters.taka(customer.totalDue),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold),
                ),
                if (customer.phone.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(customer.phone,
                      style: const TextStyle(color: Colors.white70)),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        _addTransaction(context, DueTransactionType.added),
                    icon: const Icon(Icons.add),
                    label: const Text('বাকি যোগ'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        _addTransaction(context, DueTransactionType.paid),
                    icon: const Icon(Icons.check),
                    label: const Text('পরিশোধ'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: transactions.isEmpty
                ? Center(
                    child: Text('কোনো লেনদেন নেই',
                        style: TextStyle(color: Colors.grey.shade500)),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: transactions.length,
                    itemBuilder: (context, index) {
                      final t = transactions[index];
                      final isAdded = t.type == DueTransactionType.added;
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: (isAdded
                                    ? AppTheme.dangerRed
                                    : AppTheme.primaryGreen)
                                .withValues(alpha: 0.12),
                            foregroundColor: isAdded
                                ? AppTheme.dangerRed
                                : AppTheme.primaryGreen,
                            child: Icon(
                                isAdded ? Icons.arrow_upward : Icons.arrow_downward),
                          ),
                          title: Text(isAdded ? 'বাকি যোগ হয়েছে' : 'পরিশোধ হয়েছে'),
                          subtitle: Text(Formatters.dateTime(t.date)),
                          trailing: Text(
                            '${isAdded ? '+' : '-'}${Formatters.taka(t.amount)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isAdded
                                  ? AppTheme.dangerRed
                                  : AppTheme.primaryGreen,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
