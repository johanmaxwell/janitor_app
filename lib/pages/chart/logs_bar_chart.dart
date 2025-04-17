import 'package:flutter/material.dart';
import 'package:janitor_app/pages/chart/bar_chart_widget.dart';

class LogsBarChart extends StatelessWidget {
  final String title;
  final Stream<Map<String, int>> stream;
  final Color color;
  final String mode;

  const LogsBarChart({
    super.key,
    required this.title,
    required this.stream,
    required this.color,
    required this.mode,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        AspectRatio(
          aspectRatio: 1.7,
          child: StreamBuilder<Map<String, int>>(
            stream: stream,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final data = snapshot.data!;
              return BarChartWidget(data: data, color: color, mode: mode);
            },
          ),
        ),
      ],
    );
  }
}
