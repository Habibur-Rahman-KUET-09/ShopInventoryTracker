import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/due_customer.dart';
import '../models/product.dart';
import '../models/sale_item.dart';
import '../providers/product_provider.dart';
import '../providers/sale_provider.dart';
import '../utils/formatters.dart';
import '../widgets/customer_picker_field.dart';

class AddSaleScreen extends StatefulWidget {
  const AddSaleScreen({super.key});

  @override
  State<AddSaleScreen> createState() => _AddSaleScreenState();
}

class _AddSaleScreenState extends State<AddSaleScreen> {
  final Map<String, int> _cart = {}; // productId -> quantity
  String _query = '';
  DueCustomer? _customer;

  double get _cartTotal {
    final products = context.read<ProductProvider>().products;
    double total = 0;
    _cart.forEach((id, qty) {
      final p = products.firstWhere((e) => e.id == id);
      total += p.sellPrice * qty;
    });
    return total;
  }

  int get _cartItemCount => _cart.values.fold(0, (a, b) => a + b);

  void _incrementItem(Product product) {
    if (product.quantity <= (_cart[product.id] ?? 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('স্টকে যথেষ্ট "${product.name}" নেই')),
      );
      return;
    }
    setState(() {
      _cart[product.id] = (_cart[product.id] ?? 0) + 1;
    });
  }

  void _decrementItem(Product product) {
    setState(() {
      final current = _cart[product.id] ?? 0;
      if (current <= 1) {
        _cart.remove(product.id);
      } else {
        _cart[product.id] = current - 1;
      }
    });
  }

  Future<void> _completeSale() async {
    final products = context.read<ProductProvider>().products;
    final items = _cart.entries.map((entry) {
      final p = products.firstWhere((e) => e.id == entry.key);
      return SaleItem(
        productId: p.id,
        productName: p.name,
        quantity: entry.value,
        sellPrice: p.sellPrice,
        buyPrice: p.buyPrice,
      );
    }).toList();

    await context.read<SaleProvider>().addSale(
          items,
          customerId: _customer?.id,
          customerName: _customer?.name,
        );
    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('বিক্রি সফলভাবে সংরক্ষণ হয়েছে')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final allProducts = context.watch<ProductProvider>().products;
    final products = allProducts
        .where((p) =>
            _query.isEmpty ||
            p.name.toLowerCase().contains(_query.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('নতুন বিক্রি')),
      body: allProducts.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'বিক্রি করার আগে স্টকে অন্তত একটি পণ্য যোগ করুন।',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
                ),
              ),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: CustomerPickerField(
                    selected: _customer,
                    onChanged: (c) => setState(() => _customer = c),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'পণ্য খুঁজুন...',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (v) => setState(() => _query = v),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      final inCart = _cart[product.id] ?? 0;
                      return Card(
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 4),
                          title: Text(product.name,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text(
                            '${Formatters.taka(product.sellPrice)} / পিস  •  স্টকে ${product.quantity}',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                          trailing: product.quantity == 0
                              ? const Text('স্টক নেই',
                                  style: TextStyle(color: Colors.red))
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                          Icons.remove_circle_outline),
                                      onPressed: inCart > 0
                                          ? () => _decrementItem(product)
                                          : null,
                                    ),
                                    SizedBox(
                                      width: 24,
                                      child: Text(
                                        '$inCart',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                          Icons.add_circle_outline),
                                      onPressed: () => _incrementItem(product),
                                    ),
                                  ],
                                ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
      bottomNavigationBar: _cartItemCount == 0
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton(
                  onPressed: _completeSale,
                  child: Text(
                    '$_cartItemCount আইটেম • মোট ${Formatters.taka(_cartTotal)} — বিক্রি সম্পন্ন করুন',
                  ),
                ),
              ),
            ),
    );
  }
}
