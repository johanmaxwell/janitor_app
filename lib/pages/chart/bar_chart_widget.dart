import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BarChartWidget extends StatelessWidget {
  final Map<String, int> data;
  final Color color;
  final String mode;

  const BarChartWidget({
    super.key,
    required this.data,
    required this.color,
    required this.mode,
  });

  @override
  Widget build(BuildContext context) {
    final sortedKeys = data.keys.toList()..sort((a, b) => a.compareTo(b));
    final values = sortedKeys.map((key) => data[key] ?? 0).toList();

    final maxY =
        values.isEmpty
            ? 10
            : (values.reduce((a, b) => a > b ? a : b) * 1.1).ceil();

    // Determine Y-axis step
    int step;
    if (maxY <= 10) {
      step = 2;
    } else if (maxY <= 50) {
      step = 10;
    } else if (maxY <= 100) {
      step = 20;
    } else if (maxY <= 500) {
      step = 50;
    } else {
      step = 100;
    }

    int labelInterval = (sortedKeys.length / 6).ceil();
    labelInterval = labelInterval == 0 ? 1 : labelInterval;

    final barGroups = List.generate(sortedKeys.length, (index) {
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: values[index].toDouble(),
            color: color,
            width: 16,
            borderRadius: BorderRadius.zero,
          ),
        ],
      );
    });

    return BarChart(
      BarChartData(
        maxY: maxY.toDouble(),
        barGroups: barGroups,
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: step.toDouble(),
              getTitlesWidget: (value, meta) {
                if (value % step == 0) {
                  return Text(
                    value.toInt().toString(),
                    style: const TextStyle(fontSize: 10),
                  );
                } else {
                  return const SizedBox.shrink();
                }
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: labelInterval.toDouble(),
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < sortedKeys.length) {
                  if (index % labelInterval != 0) {
                    return const SizedBox.shrink();
                  }

                  final label = sortedKeys[index];
                  String displayLabel;
                  try {
                    switch (mode) {
                      case 'Daily':
                        displayLabel = DateFormat(
                          'MM-dd',
                        ).format(DateTime.parse(label));
                        break;
                      case 'Monthly':
                        displayLabel = DateFormat(
                          'MMM',
                        ).format(DateTime.parse('$label-01'));
                        break;
                      case 'Weekly':
                        displayLabel = 'W${label.split('-W').last}';
                        break;
                      case 'Yearly':
                        displayLabel = label;
                        break;
                      default:
                        displayLabel = label;
                    }
                  } catch (e) {
                    displayLabel = '';
                  }

                  return Text(
                    displayLabel,
                    style: const TextStyle(fontSize: 10),
                    textAlign: TextAlign.center,
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(show: true, drawVerticalLine: false),
        borderData: FlBorderData(show: true),
        alignment: BarChartAlignment.spaceAround,

        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            tooltipBgColor: Colors.black87,
            tooltipPadding: const EdgeInsets.all(8),
            tooltipMargin: 8,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final index = group.x;
              final label = sortedKeys[index];
              String displayLabel;
              try {
                switch (mode) {
                  case 'Daily':
                    displayLabel = DateFormat(
                      'yyyy-MM-dd',
                    ).format(DateTime.parse(label));
                    break;
                  case 'Monthly':
                    displayLabel = DateFormat(
                      'MMMM yyyy',
                    ).format(DateTime.parse('$label-01'));
                    break;
                  case 'Weekly':
                    displayLabel =
                        'Week ${label.split('-W').last}, ${label.split('-W').first}';
                    break;
                  case 'Yearly':
                    displayLabel = label;
                    break;
                  default:
                    displayLabel = label;
                }
              } catch (e) {
                displayLabel = 'Invalid';
              }

              return BarTooltipItem(
                '$displayLabel\nValue: ${rod.toY.toInt()}',
                const TextStyle(color: Colors.white, fontSize: 12),
              );
            },
          ),
        ),
      ),
    );
  }
}
