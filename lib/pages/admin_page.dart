import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:janitor_app/dummy.dart';
import 'package:janitor_app/pages/chart/chart_page.dart';
import 'package:janitor_app/pages/manage_janitor/manage_janitor_page.dart';
import 'package:janitor_app/pages/monitoring/monitoring_page.dart';

class AdminPage extends StatefulWidget {
  final String company;

  const AdminPage(this.company, {super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  int _selectedIndex = 0;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      MonitoringPage(role: 'admin', company: widget.company),
      MyWidget(),
      ManageJanitorPage(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: Colors.white,
        elevation: 10,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        selectedFontSize: 14,
        unselectedFontSize: 12,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(FontAwesomeIcons.toilet),
            label: 'Monitoring',
          ),
          BottomNavigationBarItem(
            icon: Icon(FontAwesomeIcons.chartBar),
            label: 'Chart',
          ),
          BottomNavigationBarItem(
            icon: Icon(FontAwesomeIcons.peopleGroup),
            label: 'Users',
          ),
        ],
      ),
    );
  }
}
