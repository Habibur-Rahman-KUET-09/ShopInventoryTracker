import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/sale.dart';
import '../providers/due_provider.dart';
import '../providers/product_provider.dart';
import '../providers/sale_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/stat_card.dart';
import 'backup_screen.dart';
import 'customers_screen.dart';
import 'due_screen.dart';
import 'reports_screen.dart';
import 'sales_screen.dart';
import 'stock_screen.dart';

enum _Period { daily, weekly, monthly }

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  _Period _period = _Period.daily;

  List<Sale> _salesInPeriod(List<Sale> all) {
    final now = DateTime.now();
    late DateTime start;
    switch (_period) {
      case _Period.daily:
        start = DateTime(now.year, now.month, now.day);
        break;
      case _Period.weekly:
        start = DateTime(now.year, now.month, now.day)
            .subtract(const Duration(days: 6));
        break;
      case _Period.monthly:
        start = DateTime(now.year, now.month, now.day)
            .subtract(const Duration(days: 29));
        break;
    }
    return all.where((s) => !s.dateTime.isBefore(start)).toList();
  }

  /// Buckets used for the trend chart, independent from the summary period.
  List<_ChartBucket> _chartBuckets(List<Sale> all) {
    final now = DateTime.now();
    switch (_period) {
      case _Period.daily:
        return List.generate(7, (i) {
          final day = DateTime(now.year, now.month, now.day)
              .subtract(Duration(days: 6 - i));
          final total = all
              .where((s) =>
                  s.dateTime.year == day.year &&
                  s.dateTime.month == day.month &&
                  s.dateTime.day == day.day)
              .fold<double>(0, (sum, s) => sum + s.totalAmount);
          return _ChartBucket(Formatters.dayLabel(day), total);
        });
      case _Period.weekly:
        return List.generate(6, (i) {
          final weekStart = DateTime(now.year, now.month, now.day)
              .subtract(Duration(days: (5 - i) * 7 + now.weekday - 1));
          final weekEnd = weekStart.add(const Duration(days: 6));
          final total = all
              .where((s) =>
                  !s.dateTime.isBefore(weekStart) &&
                  s.dateTime.isBefore(weekEnd.add(const Duration(days: 1))))
              .fold<double>(0, (sum, s) => sum + s.totalAmount);
          return _ChartBucket(Formatters.dayLabel(weekStart), total);
        });
      case _Period.monthly:
        return List.generate(6, (i) {
          final month = DateTime(now.year, now.month - (5 - i), 1);
          final nextMonth = DateTime(month.year, month.month + 1, 1);
          final total = all
              .where((s) =>
                  !s.dateTime.isBefore(month) && s.dateTime.isBefore(nextMonth))
              .fold<double>(0, (sum, s) => sum + s.totalAmount);
          return _ChartBucket(_monthLabel(month), total);
        });
    }
  }

  String _monthLabel(DateTime d) {
    const names = [
      'জানু',
      'ফেব্রু',
      'মার্চ',
      'এপ্রিল',
      'মে',
      'জুন',
      'জুলাই',
      'আগস্ট',
      'সেপ্ট',
      'অক্টো',
      'নভে',
      'ডিসে'
    ];
    return names[d.month - 1];
  }

  List<MapEntry<String, int>> _topProducts(List<Sale> periodSales) {
    final Map<String, int> quantities = {};
    for (final sale in periodSales) {
      for (final item in sale.items) {
        quantities[item.productName] =
            (quantities[item.productName] ?? 0) + item.quantity;
      }
    }
    final entries = quantities.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.take(5).toList();
  }

  @override
  Widget build(BuildContext context) {
    final allSales = context.watch<SaleProvider>().sales;
    final products = context.watch<ProductProvider>().products;
    final lowStockCount =
        context.watch<ProductProvider>().lowStockProducts.length;
    final totalDue = context.watch<DueProvider>().totalOutstanding;

    final periodSales = _salesInPeriod(allSales);
    final totalSales =
        periodSales.fold<double>(0, (sum, s) => sum + s.totalAmount);
    final totalProfit =
        periodSales.fold<double>(0, (sum, s) => sum + s.totalProfit);
    final buckets = _chartBuckets(allSales);
    final topProducts = _topProducts(periodSales);
    final maxBucketValue = buckets.isEmpty
        ? 0.0
        : buckets.map((b) => b.value).reduce((a, b) => a > b ? a : b);

    return Scaffold(
      appBar: AppBar(
        title: const Text('দোকান হিসাব'),
        actions: [
          IconButton(
            icon: const Icon(Icons.people_outline),
            tooltip: 'গ্রাহক',
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const CustomersScreen(),
              ));
            },
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart_outlined),
            tooltip: 'রিপোর্ট',
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const ReportsScreen(),
              ));
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'backup',
                child: Text('ডেটা এক্সপোর্ট/ইমপোর্ট'),
              ),
            ],
            onSelected: (_) {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const BackupScreen(),
              ));
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _PeriodSelector(
            period: _period,
            onChanged: (p) => setState(() => _period = p),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const SalesScreen(),
                )),
                child: StatCard(
                  label: 'মোট বিক্রি',
                  value: Formatters.taka(totalSales),
                  icon: Icons.point_of_sale,
                  color: AppTheme.primaryGreen,
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const ReportsScreen(),
                )),
                child: StatCard(
                  label: 'মোট লাভ',
                  value: Formatters.taka(totalProfit),
                  icon: Icons.trending_up,
                  color: AppTheme.accentOrange,
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const DueScreen(),
                )),
                child: StatCard(
                  label: 'মোট বাকি',
                  value: Formatters.taka(totalDue),
                  icon: Icons.receipt_long,
                  color: Colors.blueGrey,
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const StockScreen(lowStockOnly: true),
                )),
                child: StatCard(
                  label: 'লো-স্টক পণ্য',
                  value: '$lowStockCount টি',
                  icon: Icons.warning_amber_rounded,
                  color: AppTheme.dangerRed,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'বিক্রির ট্রেন্ড',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Container(
            height: 220,
            padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: buckets.every((b) => b.value == 0)
                ? Center(
                    child: Text('এখনো কোনো বিক্রি নেই',
                        style: TextStyle(color: Colors.grey.shade500)),
                  )
                : BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: maxBucketValue == 0 ? 10 : maxBucketValue * 1.25,
                      gridData: const FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        leftTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final i = value.toInt();
                              if (i < 0 || i >= buckets.length) {
                                return const SizedBox.shrink();
                              }
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  buckets[i].label,
                                  style: const TextStyle(fontSize: 10.5),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      barGroups: [
                        for (int i = 0; i < buckets.length; i++)
                          BarChartGroupData(
                            x: i,
                            barRods: [
                              BarChartRodData(
                                toY: buckets[i].value,
                                color: AppTheme.primaryGreen,
                                width: 16,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: 20),
          const Text(
            'সবচেয়ে বেশি বিক্রি হওয়া পণ্য',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (topProducts.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text('এই সময়ে কোনো বিক্রি হয়নি',
                  style: TextStyle(color: Colors.grey.shade500)),
            )
          else
            Card(
              child: Column(
                children: [
                  for (int i = 0; i < topProducts.length; i++)
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                            AppTheme.primaryGreen.withValues(alpha: 0.12),
                        foregroundColor: AppTheme.primaryGreen,
                        child: Text('${i + 1}'),
                      ),
                      title: Text(topProducts[i].key),
                      trailing: Text(
                        '${topProducts[i].value} পিস বিক্রি',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      onTap: () {
                        final match = products
                            .where((p) => p.name == topProducts[i].key);
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => ReportsScreen(
                            initialProductId:
                                match.isEmpty ? null : match.first.id,
                          ),
                        ));
                      },
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ChartBucket {
  final String label;
  final double value;
  _ChartBucket(this.label, this.value);
}

class _PeriodSelector extends StatelessWidget {
  final _Period period;
  final ValueChanged<_Period> onChanged;

  const _PeriodSelector({required this.period, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    Widget chip(String label, _Period value) {
      final selected = period == value;
      return Expanded(
        child: GestureDetector(
          onTap: () => onChanged(value),
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: selected ? AppTheme.primaryGreen : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: selected ? AppTheme.primaryGreen : Colors.grey.shade300,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        chip('দৈনিক', _Period.daily),
        const SizedBox(width: 8),
        chip('সাপ্তাহিক', _Period.weekly),
        const SizedBox(width: 8),
        chip('মাসিক', _Period.monthly),
      ],
    );
  }
}
