import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/due_provider.dart';

class AddDueCustomerScreen extends StatefulWidget {
  const AddDueCustomerScreen({super.key});

  @override
  State<AddDueCustomerScreen> createState() => _AddDueCustomerScreenState();
}

class _AddDueCustomerScreenState extends State<AddDueCustomerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    await context.read<DueProvider>().addCustomer(
          name: _nameCtrl.text.trim(),
          phone: _phoneCtrl.text.trim(),
          initialDue: double.tryParse(_amountCtrl.text) ?? 0,
        );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('নতুন বাকি গ্রাহক')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'গ্রাহকের নাম *'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'নাম লিখুন' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _phoneCtrl,
              decoration: const InputDecoration(labelText: 'মোবাইল নম্বর'),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _amountCtrl,
              decoration: const InputDecoration(
                labelText: 'বাকির পরিমাণ (৳)',
                helperText: 'না দিলে ০ ধরা হবে',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return null;
                if (double.tryParse(v) == null) return 'সঠিক পরিমাণ দিন';
                return null;
              },
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save_outlined),
              label: const Text('সংরক্ষণ করুন'),
            ),
          ],
        ),
      ),
    );
  }
}
