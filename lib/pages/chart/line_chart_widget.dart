import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class LineChartWidget extends StatelessWidget {
  final Map<String, int> data;
  final Color color;
  final String mode;

  const LineChartWidget({
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

    // Determine Y-axis step (interval)
    int step;
    if (maxY <= 10) {
      step = 2;
    } else if (maxY <= 50) {
      step = 10;
    } else if (maxY <= 100) {
      step = 20;
    } else if (maxY <= 500) {
      step = 50;
    } else if (maxY <= 1000) {
      step = 100;
    } else if (maxY <= 2500) {
      step = 250;
    } else {
      step = 500;
    }

    // Limit bottom labels (interval)
    int labelInterval = (sortedKeys.length / 6).ceil();
    labelInterval = labelInterval == 0 ? 1 : labelInterval;

    final spots = List.generate(sortedKeys.length, (index) {
      return FlSpot(index.toDouble(), values[index].toDouble());
    });

    return AspectRatio(
      aspectRatio: 1.7,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: maxY.toDouble(),
          gridData: FlGridData(show: true, drawVerticalLine: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
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
          borderData: FlBorderData(show: true),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: color,
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(show: false),
            ),
          ],
          lineTouchData: LineTouchData(
            // Add tooltips
            enabled: true,
            touchTooltipData: LineTouchTooltipData(
              tooltipBgColor: Colors.black87,
              tooltipPadding: const EdgeInsets.all(8),
              tooltipMargin: 8,
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((lineBarSpot) {
                  final index = lineBarSpot.x.toInt();
                  final label = sortedKeys[index];
                  final value = values[index];
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
                  return LineTooltipItem(
                    '$displayLabel\nValue: $value',
                    const TextStyle(color: Colors.white, fontSize: 12),
                  );
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }
}
