import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class ChartPage extends StatefulWidget {
  const ChartPage({super.key});

  @override
  State<ChartPage> createState() => _ChartPageState();
}

class _ChartPageState extends State<ChartPage> {
  String _selectedMode = 'Monthly';
  final List<String> modes = ['Daily', 'Weekly', 'Monthly', 'Yearly'];

  Stream<Map<String, int>> getLogsGroupedByMode(String mode) {
    return FirebaseFirestore.instance
        .collection('logs')
        .where('status', isEqualTo: 'occupied')
        .snapshots()
        .map((snapshot) {
          final Map<String, int> groupedData = {};

          for (var doc in snapshot.docs) {
            final timestamp = (doc['timestamp'] as Timestamp).toDate();
            String key;

            switch (mode) {
              case 'Daily':
                key = DateFormat('yyyy-MM-dd').format(timestamp);
                break;
              case 'Weekly':
                final week = weekNumber(timestamp);
                key = '${timestamp.year}-W$week';
                break;
              case 'Monthly':
                key = DateFormat('yyyy-MM').format(timestamp);
                break;
              case 'Yearly':
                key = DateFormat('yyyy').format(timestamp);
                break;
              default:
                key = '';
            }

            groupedData[key] = (groupedData[key] ?? 0) + 1;
          }

          return groupedData;
        });
  }

  int weekNumber(DateTime date) {
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final daysOffset = date.difference(firstDayOfYear).inDays;
    return ((daysOffset + firstDayOfYear.weekday) / 7).ceil();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // 🔽 Dropdown for selecting mode
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Occupied Logs',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              DropdownButton<String>(
                value: _selectedMode,
                items:
                    modes.map((mode) {
                      return DropdownMenuItem(value: mode, child: Text(mode));
                    }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedMode = value!;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 📊 Real-time chart based on selected mode
          StreamBuilder<Map<String, int>>(
            stream: getLogsGroupedByMode(_selectedMode),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final data = snapshot.data!;
              return AspectRatio(
                aspectRatio: 1.7,
                child: buildDynamicBarChart(data, _selectedMode),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget buildDynamicBarChart(Map<String, int> data, String mode) {
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

    final barGroups = List.generate(sortedKeys.length, (index) {
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: values[index].toDouble(),
            color: Colors.green,
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
              interval: 1,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < sortedKeys.length) {
                  final label = sortedKeys[index];
                  // Simplify label based on mode
                  if (mode == 'Daily') {
                    return Text(
                      label.substring(5),
                      style: const TextStyle(fontSize: 10),
                    );
                  }
                  if (mode == 'Monthly') {
                    return Text(
                      label.substring(5),
                      style: const TextStyle(fontSize: 10),
                    );
                  }
                  if (mode == 'Weekly') {
                    return Text(
                      label.split('-W').last,
                      style: const TextStyle(fontSize: 10),
                    );
                  }
                  if (mode == 'Yearly') {
                    return Text(label, style: const TextStyle(fontSize: 10));
                  }
                  return Text(label, style: const TextStyle(fontSize: 10));
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
      ),
    );
  }
}
