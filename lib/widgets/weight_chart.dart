import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:ficha_pet/models/pet.dart';
import 'package:intl/intl.dart';

class WeightChart extends StatelessWidget {
  final List<WeightHistoryEntry> weightHistory;

  const WeightChart({super.key, required this.weightHistory});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (weightHistory.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'No hay datos de peso registrados',
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
        ),
      );
    }

    // Ordenar por fecha (descartando fechas inválidas)
    final sortedHistory = weightHistory
        .where((e) => DateTime.tryParse(e.date) != null && e.weight > 0)
        .toList()
      ..sort((a, b) => DateTime.parse(a.date).compareTo(DateTime.parse(b.date)));

    if (sortedHistory.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No hay datos de peso válidos'),
        ),
      );
    }

    final spots = sortedHistory.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.weight);
    }).toList();

    final minWeight = sortedHistory.map((e) => e.weight).reduce((a, b) => a < b ? a : b);
    final maxWeight = sortedHistory.map((e) => e.weight).reduce((a, b) => a > b ? a : b);
    // Con un solo valor (o todos iguales) se usa un margen fijo para que
    // el gráfico no colapse (minY == maxY).
    final padding = (maxWeight - minWeight) == 0 ? 1.0 : (maxWeight - minWeight) * 0.15;
    final minY = (minWeight - padding) < 0 ? 0.0 : (minWeight - padding);
    final maxY = maxWeight + padding;

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
                            style: TextStyle(
                              fontSize: 10,
                              color: scheme.onSurfaceVariant,
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= 0 &&
                              value.toInt() < sortedHistory.length) {
                            final entry = sortedHistory[value.toInt()];
                            final date = DateTime.parse(entry.date);
                            return Text(
                              DateFormat('MM/yy').format(date),
                              style: TextStyle(
                                fontSize: 10,
                                color: scheme.onSurfaceVariant,
                              ),
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
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(
                      color: scheme.outlineVariant.withValues(alpha: 0.7),
                    ),
                  ),
                  minY: minY,
                  maxY: maxY,
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: scheme.primary,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: scheme.primary.withValues(alpha: 0.12),
                      ),
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

