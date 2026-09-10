import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/product_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import 'add_edit_product_screen.dart';

class StockScreen extends StatefulWidget {
  const StockScreen({super.key});

  @override
  State<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final products = context.watch<ProductProvider>().products.where((p) {
      if (_query.isEmpty) return true;
      return p.name.toLowerCase().contains(_query.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('স্টক ম্যানেজমেন্ট')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'পণ্য খুঁজুন...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Expanded(
            child: products.isEmpty
                ? const _EmptyStock()
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      return Card(
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          title: Text(
                            product.name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              'ক্রয়: ${Formatters.taka(product.buyPrice)}  •  বিক্রয়: ${Formatters.taka(product.sellPrice)}',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: product.isLowStock
                                      ? AppTheme.dangerRed.withValues(alpha: 0.12)
                                      : AppTheme.primaryGreen
                                          .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '${product.quantity} পিস',
                                  style: TextStyle(
                                    color: product.isLowStock
                                        ? AppTheme.dangerRed
                                        : AppTheme.primaryGreen,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12.5,
                                  ),
                                ),
                              ),
                              if (product.isLowStock)
                                const Padding(
                                  padding: EdgeInsets.only(top: 4),
                                  child: Text(
                                    'স্টক কম!',
                                    style: TextStyle(
                                      color: AppTheme.dangerRed,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          onTap: () {
                            Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) =>
                                  AddEditProductScreen(product: product),
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
            builder: (_) => const AddEditProductScreen(),
          ));
        },
        icon: const Icon(Icons.add),
        label: const Text('নতুন পণ্য'),
      ),
    );
  }
}

class _EmptyStock extends StatelessWidget {
  const _EmptyStock();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inventory_2_outlined,
                size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'কোনো পণ্য যোগ করা হয়নি।\n"নতুন পণ্য" বাটনে চাপ দিয়ে শুরু করুন।',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}
