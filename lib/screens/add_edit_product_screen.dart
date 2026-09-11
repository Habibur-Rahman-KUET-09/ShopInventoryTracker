import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../providers/product_provider.dart';

class AddEditProductScreen extends StatefulWidget {
  final Product? product;

  const AddEditProductScreen({super.key, this.product});

  @override
  State<AddEditProductScreen> createState() => _AddEditProductScreenState();
}

class _AddEditProductScreenState extends State<AddEditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _brandCtrl;
  late final TextEditingController _buyPriceCtrl;
  late final TextEditingController _sellPriceCtrl;
  late final TextEditingController _quantityCtrl;
  late final TextEditingController _lowStockCtrl;

  bool get isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameCtrl = TextEditingController(text: p?.name ?? '');
    _brandCtrl = TextEditingController(text: p?.brand ?? '');
    _buyPriceCtrl = TextEditingController(
        text: p != null ? _trimZero(p.buyPrice) : '');
    _sellPriceCtrl = TextEditingController(
        text: p != null ? _trimZero(p.sellPrice) : '');
    _quantityCtrl = TextEditingController(text: p?.quantity.toString() ?? '');
    _lowStockCtrl =
        TextEditingController(text: (p?.lowStockThreshold ?? 5).toString());
  }

  String _trimZero(double value) {
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value.toString();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _brandCtrl.dispose();
    _buyPriceCtrl.dispose();
    _sellPriceCtrl.dispose();
    _quantityCtrl.dispose();
    _lowStockCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<ProductProvider>();
    final name = _nameCtrl.text.trim();
    final brand = _brandCtrl.text.trim();
    final buyPrice = double.parse(_buyPriceCtrl.text);
    final sellPrice = double.parse(_sellPriceCtrl.text);
    final quantity = int.parse(_quantityCtrl.text);
    final lowStock = int.parse(_lowStockCtrl.text.isEmpty ? '5' : _lowStockCtrl.text);

    if (isEditing) {
      final p = widget.product!;
      p.name = name;
      p.brand = brand;
      p.buyPrice = buyPrice;
      p.sellPrice = sellPrice;
      p.quantity = quantity;
      p.lowStockThreshold = lowStock;
      await provider.updateProduct(p);
    } else {
      await provider.addProduct(
        name: name,
        brand: brand,
        buyPrice: buyPrice,
        sellPrice: sellPrice,
        quantity: quantity,
        lowStockThreshold: lowStock,
      );
    }
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('পণ্য মুছবেন?'),
        content: Text('"${widget.product!.name}" পণ্যটি স্থায়ীভাবে মুছে যাবে।'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('বাতিল'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('মুছুন', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await context.read<ProductProvider>().deleteProduct(widget.product!.id);
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'পণ্য এডিট করুন' : 'নতুন পণ্য যোগ করুন'),
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _confirmDelete,
              tooltip: 'মুছুন',
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'পণ্যের নাম *'),
              textInputAction: TextInputAction.next,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'পণ্যের নাম লিখুন' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _brandCtrl,
              decoration: const InputDecoration(
                labelText: 'ব্র্যান্ড',
                helperText: 'নতুন ব্র্যান্ড লিখলে সেটাও তালিকায় যোগ হয়ে যাবে',
              ),
              textInputAction: TextInputAction.next,
            ),
            Consumer<ProductProvider>(
              builder: (context, provider, _) => ValueListenableBuilder<TextEditingValue>(
                valueListenable: _brandCtrl,
                builder: (context, value, _) {
                  final suggestions = provider.brands
                      .where((b) => b.toLowerCase() != value.text.trim().toLowerCase())
                      .toList();
                  if (suggestions.isEmpty) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: suggestions
                          .map((b) => ActionChip(
                                label: Text(b),
                                onPressed: () =>
                                    setState(() => _brandCtrl.text = b),
                              ))
                          .toList(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _buyPriceCtrl,
                    decoration: const InputDecoration(
                      labelText: 'ক্রয় মূল্য (৳) *',
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: _numberValidator,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _sellPriceCtrl,
                    decoration: const InputDecoration(
                      labelText: 'বিক্রয় মূল্য (৳) *',
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: _numberValidator,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _quantityCtrl,
                    decoration: const InputDecoration(
                      labelText: 'পরিমাণ (স্টক) *',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'পরিমাণ লিখুন';
                      if (int.tryParse(v) == null) return 'সঠিক সংখ্যা দিন';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _lowStockCtrl,
                    decoration: const InputDecoration(
                      labelText: 'লো-স্টক সীমা',
                      helperText: 'এর নিচে নামলে সতর্ক করবে',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return null;
                      if (int.tryParse(v) == null) return 'সঠিক সংখ্যা দিন';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save_outlined),
              label: Text(isEditing ? 'আপডেট করুন' : 'সংরক্ষণ করুন'),
            ),
          ],
        ),
      ),
    );
  }

  String? _numberValidator(String? v) {
    if (v == null || v.trim().isEmpty) return 'মূল্য লিখুন';
    if (double.tryParse(v) == null) return 'সঠিক মূল্য দিন';
    return null;
  }
}
