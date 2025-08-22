import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/expense.dart';
import 'dart:math';

class ExpenseChart extends StatelessWidget {
  final List<Expense> expenses;

  const ExpenseChart({super.key, required this.expenses});

  @override
  Widget build(BuildContext context) {
    final grouped = <String, double>{};

    for (var e in expenses) {
      final month = "${e.date.month}/${e.date.year}";
      grouped[month] = (grouped[month] ?? 0) + e.amount;
    }

    final colors = [
      Colors.purple,
      Colors.teal,
      Colors.blue,
      Colors.orange,
      Colors.green,
      Colors.pink,
      Colors.red,
      Colors.indigo,
    ];

    final entries = grouped.entries.toList();
    final total = grouped.values.fold(0.0, (a, b) => a + b);

    return Card(
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              'Monthly Expense Chart',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 4,
                  centerSpaceRadius: 40,
                  sections: List.generate(entries.length, (i) {
                    final e = entries[i];
                    final color = colors[i % colors.length];
                    return PieChartSectionData(
                      color: color,
                      value: e.value,
                      title: '${(e.value / total * 100).toStringAsFixed(1)}%',
                      radius: 60,
                      titleStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    );
                  }),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              children: List.generate(entries.length, (i) {
                final e = entries[i];
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 12, height: 12, color: colors[i % colors.length]),
                    const SizedBox(width: 4),
                    Text(e.key),
                  ],
                );
              }),
            )
          ],
        ),
      ),
    );
  }
}
