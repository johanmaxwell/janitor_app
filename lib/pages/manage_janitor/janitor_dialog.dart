import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:janitor_app/models/janitor_account.dart';
import 'package:janitor_app/utils/firebase_usage_monitor.dart';
import 'package:janitor_app/utils/string_util.dart';

class JanitorDialog {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final usageMonitor = FirestoreUsageMonitor();

  Future<void> addJanitor(BuildContext context) async {
    await showDialog(
      context: context,
      builder:
          (context) => _buildAddEditDialog(context, 'Add New Janitor', null),
    );
    _clearControllers();
  }

  Future<void> editJanitor(BuildContext context, JanitorAccount janitor) async {
    _fullNameController.text = janitor.fullName;
    _usernameController.text = janitor.username;
    await showDialog(
      context: context,
      builder:
          (context) => _buildAddEditDialog(context, 'Edit Janitor', janitor),
    );
    _clearControllers();
  }

  Future<void> deleteJanitor(BuildContext context, String janitorId) async {
    final confirm = await _showConfirmationDialog(
      context,
      'Confirm Delete',
      'Apakah anda yakin ingin menghapus akun?',
    );
    if (confirm == true) {
      await _firestore.collection('users').doc(janitorId).delete();
      usageMonitor.incrementWrites();
    }
  }

  AlertDialog _buildAddEditDialog(
    BuildContext context,
    String title,
    JanitorAccount? janitor,
  ) {
    return AlertDialog(
      title: Text(title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _fullNameController,
            decoration: InputDecoration(
              labelText: 'Full Name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _usernameController,
            decoration: InputDecoration(
              labelText: 'Username',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: InputDecoration(
              labelText:
                  janitor != null
                      ? 'Password (biarkan kosong jika tetap)'
                      : 'Password',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            _clearControllers();
          },
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            if (_fullNameController.text.isNotEmpty &&
                _usernameController.text.isNotEmpty) {
              final confirm = await _showConfirmationDialog(
                context,
                janitor != null ? 'Confirm Edit' : 'Confirm Add',
                janitor != null
                    ? 'Apakah anda yakin ingin mengubah data akun?'
                    : 'Apakah anda yakin ingin menambahkan akun?',
              );
              if (confirm == true) {
                if (janitor != null) {
                  Map<String, dynamic> updateData = {
                    'full_name': _fullNameController.text,
                    'username': _usernameController.text,
                    'last_updated': Timestamp.now(),
                  };
                  if (_passwordController.text.isNotEmpty) {
                    updateData['password'] = StringUtil.hashPassword(
                      _passwordController.text,
                    );
                  }
                  await _firestore
                      .collection('users')
                      .doc(janitor.id)
                      .update(updateData);

                  usageMonitor.incrementWrites();
                } else {
                  await _firestore.collection('users').add({
                    'full_name': _fullNameController.text,
                    'username': _usernameController.text,
                    'password': StringUtil.hashPassword(
                      _passwordController.text,
                    ),
                    'role': 'janitor',
                    'added_at': Timestamp.now(),
                  });

                  usageMonitor.incrementWrites();
                }
                Navigator.pop(context);
              }
            }
          },
          child: const Text('Submit'),
        ),
      ],
    );
  }

  Future<bool?> _showConfirmationDialog(
    BuildContext context,
    String title,
    String content,
  ) async {
    return showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(title),
            content: Text(content),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('No'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Yes'),
              ),
            ],
          ),
    );
  }

  void _clearControllers() {
    _fullNameController.clear();
    _usernameController.clear();
    _passwordController.clear();
  }
}
