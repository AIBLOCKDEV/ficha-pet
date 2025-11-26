import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:ficha_pet/models/pet.dart';

import 'package:intl/intl.dart';

class WeightChart extends StatelessWidget {
  final List<WeightHistoryEntry> weightHistory;

  const WeightChart({super.key, required this.weightHistory});

  @override
  Widget build(BuildContext context) {
    if (weightHistory.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No hay datos de peso registrados'),
        ),
      );
    }

    // Ordenar por fecha
    final sortedHistory = List<WeightHistoryEntry>.from(weightHistory)
      ..sort(
          (a, b) => DateTime.parse(a.date).compareTo(DateTime.parse(b.date)));

    final spots = sortedHistory.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.weight);
    }).toList();

    final minWeight =
        sortedHistory.map((e) => e.weight).reduce((a, b) => a < b ? a : b);
    final maxWeight =
        sortedHistory.map((e) => e.weight).reduce((a, b) => a > b ? a : b);
    final weightRange = maxWeight - minWeight;
    final minY = (minWeight - weightRange * 0.1) < 0
        ? 0.0
        : (minWeight - weightRange * 0.1);
    final maxY = maxWeight + weightRange * 0.1;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Evolución del Peso',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toStringAsFixed(1),
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= 0 &&
                              value.toInt() < sortedHistory.length) {
                            final entry = sortedHistory[value.toInt()];
                            final date = DateTime.parse(entry.date);
                            return Text(
                              DateFormat('MM/yy').format(date),
                              style: const TextStyle(fontSize: 10),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: true),
                  minY: minY,
                  maxY: maxY,
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: const Color(0xFF4F46E5),
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(show: false),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
