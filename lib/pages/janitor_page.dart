import 'package:flutter/material.dart';
import 'package:janitor_app/pages/monitoring/monitoring_page.dart';

class JanitorPage extends StatelessWidget {
  final String company;

  const JanitorPage(this.company, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: MonitoringPage(role: 'janitor', company: company),
    );
  }
}
