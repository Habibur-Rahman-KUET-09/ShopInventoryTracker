import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/sale.dart';
import '../providers/product_provider.dart';
import '../providers/sale_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

const List<String> _bnDayNames = [
  'সোম',
  'মঙ্গল',
  'বুধ',
  'বৃহ',
  'শুক্র',
  'শনি',
  'রবি',
];

String _hourRangeLabel(int hour) {
  final start = hour % 12 == 0 ? 12 : hour % 12;
  final period = hour < 12 ? 'AM' : 'PM';
  return '$start$period';
}

class ReportsScreen extends StatelessWidget {
  final String? initialProductId;
  final int initialTabIndex;

  const ReportsScreen({
    super.key,
    this.initialProductId,
    this.initialTabIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      initialIndex: initialTabIndex,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('রিপোর্ট'),
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.center,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            labelStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            tabs: const [
              Tab(text: 'পণ্য'),
              Tab(text: 'সময় বিশ্লেষণ'),
              Tab(text: 'গ্রাহক বিশ্লেষণ'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _ProductReportTab(initialProductId: initialProductId),
            const _TimeAnalysisTab(),
            const _CustomerAnalysisTab(),
          ],
        ),
      ),
    );
  }
}

class _ProductReportTab extends StatefulWidget {
  final String? initialProductId;
  const _ProductReportTab({this.initialProductId});

  @override
  State<_ProductReportTab> createState() => _ProductReportTabState();
}

class _ProductReportTabState extends State<_ProductReportTab> {
  late String? _productId = widget.initialProductId;

  @override
  Widget build(BuildContext context) {
    final products = context.watch<ProductProvider>().products;
    final sales = context.watch<SaleProvider>().sales;

    if (products.isEmpty) {
      return Center(
        child: Text(
          'কোনো পণ্য নেই',
          style: TextStyle(color: Colors.grey.shade500),
        ),
      );
    }

    final selectedId = _productId ?? products.first.id;
    final selected = products.firstWhere(
      (p) => p.id == selectedId,
      orElse: () => products.first,
    );

    final entries = <_ProductSaleEntry>[];
    for (final sale in sales) {
      for (final item in sale.items) {
        if (item.productId == selected.id) {
          entries.add(
            _ProductSaleEntry(sale.dateTime, item.quantity, item.total),
          );
        }
      }
    }
    entries.sort((a, b) => b.dateTime.compareTo(a.dateTime));
    final totalQty = entries.fold<int>(0, (sum, e) => sum + e.quantity);
    final totalRevenue = entries.fold<double>(0, (sum, e) => sum + e.amount);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: DropdownButtonFormField<String>(
            initialValue: selected.id,
            decoration: const InputDecoration(labelText: 'পণ্য নির্বাচন করুন'),
            items: products
                .map((p) => DropdownMenuItem(value: p.id, child: Text(p.name)))
                .toList(),
            onChanged: (v) => setState(() => _productId = v),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Row(
            children: [
              Expanded(
                child: _MiniStat(label: 'মোট বিক্রি', value: '$totalQty পিস'),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniStat(
                  label: 'মোট আয়',
                  value: Formatters.taka(totalRevenue),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: entries.isEmpty
              ? Center(
                  child: Text(
                    'এই পণ্যের কোনো বিক্রি রেকর্ড নেই',
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: entries.length,
                  itemBuilder: (context, index) {
                    final e = entries[index];
                    return Card(
                      child: ListTile(
                        leading: const Icon(
                          Icons.receipt_long_outlined,
                          color: AppTheme.primaryGreen,
                        ),
                        title: Text('${e.quantity} পিস বিক্রি হয়েছে'),
                        subtitle: Text(Formatters.dateTime(e.dateTime)),
                        trailing: Text(
                          Formatters.taka(e.amount),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _ProductSaleEntry {
  final DateTime dateTime;
  final int quantity;
  final double amount;
  _ProductSaleEntry(this.dateTime, this.quantity, this.amount);
}

class _DailyBucket {
  final DateTime day;
  final double total;
  final int count;
  _DailyBucket(this.day, this.total, this.count);
}

class _TimeAnalysisTab extends StatelessWidget {
  const _TimeAnalysisTab();

  @override
  Widget build(BuildContext context) {
    final sales = context.watch<SaleProvider>().sales;

    if (sales.isEmpty) {
      return Center(
        child: Text(
          'বিশ্লেষণের জন্য যথেষ্ট বিক্রি ডেটা নেই',
          style: TextStyle(color: Colors.grey.shade500),
        ),
      );
    }

    final byWeekday = List<double>.filled(7, 0);
    final countByWeekday = List<int>.filled(7, 0);
    final byHour = List<double>.filled(24, 0);
    final countByHour = List<int>.filled(24, 0);
    for (final s in sales) {
      byWeekday[s.dateTime.weekday - 1] += s.totalAmount;
      countByWeekday[s.dateTime.weekday - 1]++;
      byHour[s.dateTime.hour] += s.totalAmount;
      countByHour[s.dateTime.hour]++;
    }
    final maxWeekday = byWeekday.reduce((a, b) => a > b ? a : b);

    final hourRanking = List.generate(24, (h) => h)
      ..sort((a, b) => byHour[b].compareTo(byHour[a]));
    final topHours = hourRanking.where((h) => byHour[h] > 0).take(5).toList();

    final now = DateTime.now();
    final dailyBuckets = List.generate(14, (i) {
      final day = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: 13 - i));
      final daySales = sales.where(
        (s) =>
            s.dateTime.year == day.year &&
            s.dateTime.month == day.month &&
            s.dateTime.day == day.day,
      );
      return _DailyBucket(
        day,
        daySales.fold<double>(0, (sum, s) => sum + s.totalAmount),
        daySales.length,
      );
    });
    final maxDaily = dailyBuckets
        .map((b) => b.total)
        .fold<double>(0, (a, b) => a > b ? a : b);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        const Text(
          'সাম্প্রতিক ১৪ দিনের ট্রেন্ড',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Container(
          height: 200,
          padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxDaily == 0 ? 10 : maxDaily * 1.25,
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final b = dailyBuckets[group.x];
                    return BarTooltipItem(
                      '${Formatters.taka(b.total)}\n${b.count} বিক্রি',
                      const TextStyle(color: Colors.white, fontSize: 11),
                    );
                  },
                ),
              ),
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
                    interval: 2,
                    getTitlesWidget: (value, meta) {
                      final i = value.toInt();
                      if (i < 0 || i >= dailyBuckets.length) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          Formatters.dayLabel(dailyBuckets[i].day),
                          style: const TextStyle(fontSize: 9.5),
                        ),
                      );
                    },
                  ),
                ),
              ),
              barGroups: [
                for (int i = 0; i < dailyBuckets.length; i++)
                  BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: dailyBuckets[i].total,
                        color: AppTheme.accentOrange,
                        width: 12,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'দিনভিত্তিক বিক্রি (সব সময়)',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Container(
          height: 200,
          padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxWeekday == 0 ? 10 : maxWeekday * 1.25,
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
                      if (i < 0 || i >= 7) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          _bnDayNames[i],
                          style: const TextStyle(fontSize: 10.5),
                        ),
                      );
                    },
                  ),
                ),
              ),
              barGroups: [
                for (int i = 0; i < 7; i++)
                  BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: byWeekday[i],
                        color: AppTheme.primaryGreen,
                        width: 18,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Card(
          child: Column(
            children: [
              for (int i = 0; i < 7; i++)
                if (countByWeekday[i] > 0)
                  ListTile(
                    dense: true,
                    leading: Text(
                      '${_bnDayNames[i]}বার',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    title: Text('${countByWeekday[i]} টি বিক্রি'),
                    trailing: Text(
                      Formatters.taka(byWeekday[i]),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'সবচেয়ে ব্যস্ত সময়',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        if (topHours.isEmpty)
          Text('যথেষ্ট ডেটা নেই', style: TextStyle(color: Colors.grey.shade500))
        else
          Card(
            child: Column(
              children: [
                for (int i = 0; i < topHours.length; i++)
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.accentOrange.withValues(
                        alpha: 0.12,
                      ),
                      foregroundColor: AppTheme.accentOrange,
                      child: Text('${i + 1}'),
                    ),
                    title: Text(
                      '${_hourRangeLabel(topHours[i])} - ${_hourRangeLabel((topHours[i] + 1) % 24)}',
                    ),
                    subtitle: Text('${countByHour[topHours[i]]} টি বিক্রি'),
                    trailing: Text(
                      Formatters.taka(byHour[topHours[i]]),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _CustomerAnalysisTab extends StatelessWidget {
  const _CustomerAnalysisTab();

  @override
  Widget build(BuildContext context) {
    final sales = context.watch<SaleProvider>().sales.where(
      (s) => s.customerId != null,
    );

    final Map<String, List<Sale>> byCustomer = {};
    for (final s in sales) {
      byCustomer.putIfAbsent(s.customerId!, () => []).add(s);
    }

    if (byCustomer.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'বিক্রির সময় গ্রাহক যুক্ত করা হলে এখানে তাদের কেনাকাটার ধরণ দেখা যাবে',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ),
      );
    }

    final entries = byCustomer.entries.toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length));

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final customerSales = entries[index].value;
        final name = customerSales.first.customerName ?? 'গ্রাহক';
        final totalSpent = customerSales.fold<double>(
          0,
          (sum, s) => sum + s.totalAmount,
        );

        final weekdayCounts = List<int>.filled(7, 0);
        final hourCounts = List<int>.filled(24, 0);
        for (final s in customerSales) {
          weekdayCounts[s.dateTime.weekday - 1]++;
          hourCounts[s.dateTime.hour]++;
        }
        final busiestDay = List.generate(
          7,
          (i) => i,
        ).reduce((a, b) => weekdayCounts[a] >= weekdayCounts[b] ? a : b);
        final busiestHour = List.generate(
          24,
          (i) => i,
        ).reduce((a, b) => hourCounts[a] >= hourCounts[b] ? a : b);

        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.12),
              foregroundColor: AppTheme.primaryGreen,
              child: Text('${index + 1}'),
            ),
            title: Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              '${customerSales.length} বার এসেছেন  •  সাধারণত ${_bnDayNames[busiestDay]}বার, ${_hourRangeLabel(busiestHour)} এর দিকে',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5),
            ),
            trailing: Text(
              Formatters.taka(totalSpent),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        );
      },
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}
