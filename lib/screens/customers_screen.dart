import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/due_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import 'add_due_customer_screen.dart';
import 'due_customer_detail_screen.dart';

/// Dedicated customer directory: view, search, add, edit and delete
/// customers, independent of the বাকি (due) workflow.
class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final allCustomers = context.watch<DueProvider>().customers;
    final customers = allCustomers.where((c) {
      if (_query.isEmpty) return true;
      final q = _query.toLowerCase();
      return c.name.toLowerCase().contains(q) || c.phone.contains(q);
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('গ্রাহক ব্যবস্থাপনা')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'নাম বা মোবাইল নম্বর খুঁজুন...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Expanded(
            child: customers.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.people_outline,
                              size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text(
                            allCustomers.isEmpty
                                ? 'কোনো গ্রাহক যোগ করা হয়নি।'
                                : 'কোনো মিল পাওয়া যায়নি।',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Colors.grey.shade600, fontSize: 15),
                          ),
                        ],
                      ),
                    ),
                  )
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
                          trailing: customer.totalDue != 0
                              ? Text(
                                  Formatters.taka(customer.totalDue),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: customer.totalDue > 0
                                        ? AppTheme.dangerRed
                                        : AppTheme.primaryGreen,
                                  ),
                                )
                              : null,
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
        heroTag: 'customers_fab',
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
