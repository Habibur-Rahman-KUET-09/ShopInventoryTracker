import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/due_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import 'add_due_customer_screen.dart';
import 'due_customer_detail_screen.dart';

class DueScreen extends StatelessWidget {
  const DueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dueProvider = context.watch<DueProvider>();
    final customers = dueProvider.customers;

    return Scaffold(
      appBar: AppBar(title: const Text('বাকি হিসাব')),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.dangerRed,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('মোট বকেয়া',
                    style: TextStyle(color: Colors.white70, fontSize: 14)),
                Text(
                  Formatters.taka(dueProvider.totalOutstanding),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Expanded(
            child: customers.isEmpty
                ? const _EmptyDue()
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                    itemCount: customers.length,
                    itemBuilder: (context, index) {
                      final customer = customers[index];
                      return Card(
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          leading: CircleAvatar(
                            backgroundColor:
                                AppTheme.primaryGreen.withValues(alpha: 0.12),
                            foregroundColor: AppTheme.primaryGreen,
                            child: Text(
                              customer.name.isNotEmpty
                                  ? customer.name.substring(0, 1)
                                  : '?',
                            ),
                          ),
                          title: Text(customer.name,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: customer.phone.isNotEmpty
                              ? Text(customer.phone)
                              : null,
                          trailing: Text(
                            Formatters.taka(customer.totalDue),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: customer.totalDue > 0
                                  ? AppTheme.dangerRed
                                  : AppTheme.primaryGreen,
                            ),
                          ),
                          onTap: () {
                            Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) => DueCustomerDetailScreen(
                                  customerId: customer.id),
                            ));
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => const AddDueCustomerScreen(),
          ));
        },
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('নতুন গ্রাহক'),
      ),
    );
  }
}

class _EmptyDue extends StatelessWidget {
  const _EmptyDue();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt_long_outlined,
                size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'কোনো বাকির হিসাব নেই।',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}
