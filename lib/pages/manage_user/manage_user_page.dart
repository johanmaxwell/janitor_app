import 'package:flutter/material.dart';

class ManageUserPage extends StatelessWidget {
  const ManageUserPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage User Page')),
      body: Center(
        child: const Text(
          'This is a dummy user Page',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
