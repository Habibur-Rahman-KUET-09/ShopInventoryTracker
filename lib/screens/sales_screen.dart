import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/sale.dart';
import '../providers/sale_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import 'add_sale_screen.dart';

class SalesScreen extends StatelessWidget {
  const SalesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sales = context.watch<SaleProvider>().sales;
    final today = DateTime.now();
    final todaySales = sales.where((s) =>
        s.dateTime.year == today.year &&
        s.dateTime.month == today.month &&
        s.dateTime.day == today.day);
    final todayTotal =
        todaySales.fold<double>(0, (sum, s) => sum + s.totalAmount);

    return Scaffold(
      appBar: AppBar(title: const Text('বিক্রি')),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('আজকের মোট বিক্রি',
                    style: TextStyle(color: Colors.white70, fontSize: 14)),
                Text(
                  Formatters.taka(todayTotal),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Expanded(
            child: sales.isEmpty
                ? const _EmptySales()
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                    itemCount: sales.length,
                    itemBuilder: (context, index) {
                      final sale = sales[index];
                      return _SaleCard(sale: sale);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'sales_fab',
        onPressed: () {
          Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => const AddSaleScreen()));
        },
        icon: const Icon(Icons.add_shopping_cart),
        label: const Text('নতুন বিক্রি'),
      ),
    );
  }
}

class _SaleCard extends StatelessWidget {
  final Sale sale;
  const _SaleCard({required this.sale});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 14),
        title: Text(
          Formatters.taka(sale.totalAmount),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text(
          '${Formatters.dateTime(sale.dateTime)}  •  ${sale.totalQuantity} আইটেম'
          '${sale.customerName != null ? '  •  ${sale.customerName}' : ''}',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: () async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('বিক্রি মুছবেন?'),
                content: const Text(
                    'এই বিক্রিটি মুছে ফেললে সংশ্লিষ্ট পণ্যের স্টক ফিরিয়ে দেওয়া হবে।'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: const Text('বাতিল'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(true),
                    child:
                        const Text('মুছুন', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            );
            if (confirmed == true && context.mounted) {
              await context.read<SaleProvider>().deleteSale(sale.id);
            }
          },
        ),
        children: sale.items
            .map((item) => Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text('${item.productName} × ${item.quantity}'),
                      ),
                      Text(Formatters.taka(item.total)),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }
}

class _EmptySales extends StatelessWidget {
  const _EmptySales();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.point_of_sale_outlined,
                size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'আজ এখনো কোনো বিক্রি এন্ট্রি করা হয়নি।',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}
