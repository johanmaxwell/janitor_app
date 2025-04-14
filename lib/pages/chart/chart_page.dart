import 'package:flutter/material.dart';

class ChartPage extends StatelessWidget {
  const ChartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chart Page')),
      body: Center(
        child: const Text(
          'This is a dummy Chart Page',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
