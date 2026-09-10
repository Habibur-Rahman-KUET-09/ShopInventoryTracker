import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/due_provider.dart';
import 'providers/product_provider.dart';
import 'providers/sale_provider.dart';
import 'repositories/due_repository.dart';
import 'repositories/hive_boxes.dart';
import 'repositories/product_repository.dart';
import 'repositories/sale_repository.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveBoxes.init();
  runApp(const DokanHisabApp());
}

class DokanHisabApp extends StatelessWidget {
  const DokanHisabApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ProductProvider(ProductRepository()),
        ),
        ChangeNotifierProxyProvider<ProductProvider, SaleProvider>(
          create: (context) => SaleProvider(
            SaleRepository(),
            context.read<ProductProvider>(),
          ),
          update: (context, productProvider, previous) =>
              previous ?? SaleProvider(SaleRepository(), productProvider),
        ),
        ChangeNotifierProvider(
          create: (_) => DueProvider(DueRepository()),
        ),
      ],
      child: MaterialApp(
        title: 'দোকান হিসাব',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        locale: const Locale('bn', 'BD'),
        home: const HomeScreen(),
      ),
    );
  }
}
