import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:janitor_app/models/janitor_account.dart';
import 'package:janitor_app/pages/manage_janitor/header.dart';
import 'package:janitor_app/utils/string_util.dart';

class ManageJanitorPage extends StatefulWidget {
  const ManageJanitorPage({super.key});

  @override
  State<ManageJanitorPage> createState() => _ManageJanitorPageState();
}

class _ManageJanitorPageState extends State<ManageJanitorPage> {
  // Firestore collection reference
  final _usersCollection = FirebaseFirestore.instance.collection('users');

  // TextEditingControllers for dialogs
  late final TextEditingController _fullNameController;
  late final TextEditingController _usernameController;
  late final TextEditingController _passwordController;

  @override
  void initState() {
    super.initState();
    // Initialize controllers
    _fullNameController = TextEditingController();
    _usernameController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    // Dispose of controllers to prevent memory leaks
    _fullNameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _addJanitor(BuildContext context) async {
    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Add New Janitor'),
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
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  _fullNameController.clear();
                  _usernameController.clear();
                  _passwordController.clear();
                  if (!mounted) return;
                  Navigator.pop(context);
                },
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (_fullNameController.text.isNotEmpty &&
                      _usernameController.text.isNotEmpty &&
                      _passwordController.text.isNotEmpty) {
                    // Show confirmation dialog
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder:
                          (context) => AlertDialog(
                            title: const Text('Confirm Add'),
                            content: const Text(
                              'Are you sure you want to add this janitor?',
                            ),
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

                    if (confirm == true) {
                      // Proceed with adding the janitor
                      await _usersCollection.add({
                        'full_name': _fullNameController.text,
                        'username': _usernameController.text,
                        'password': StringUtil.hashPassword(
                          _passwordController.text,
                        ),
                        'role': 'janitor',
                        'added_at': Timestamp.now(),
                      });
                      _fullNameController.clear();
                      _usernameController.clear();
                      _passwordController.clear();
                      Navigator.pop(context);
                    }
                  }
                },
                child: const Text('Submit'),
              ),
            ],
          ),
    );
  }

  Future<void> _editJanitor(
    BuildContext context,
    JanitorAccount janitor,
  ) async {
    _fullNameController.text = janitor.fullName;
    _usernameController.text = janitor.username;
    _passwordController.text = '';

    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Edit Janitor'),
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
                    labelText: 'Password (leave blank to keep current)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  _fullNameController.clear();
                  _usernameController.clear();
                  _passwordController.clear();
                  Navigator.pop(context);
                },
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (_fullNameController.text.isNotEmpty &&
                      _usernameController.text.isNotEmpty) {
                    // Show confirmation dialog
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder:
                          (context) => AlertDialog(
                            title: const Text('Confirm Edit'),
                            content: const Text(
                              'Are you sure you want to edit this janitor?',
                            ),
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

                    if (confirm == true) {
                      // Proceed with editing the janitor
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
                      await _usersCollection.doc(janitor.id).update(updateData);
                      _fullNameController.clear();
                      _usernameController.clear();
                      _passwordController.clear();
                      Navigator.pop(context);
                    }
                  }
                },
                child: const Text('Submit'),
              ),
            ],
          ),
    );
  }

  Future<void> _deleteJanitor(String janitorId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirm Delete'),
            content: const Text(
              'Are you sure you want to delete this janitor?',
            ),
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

    if (confirm == true) {
      // Proceed with deleting the janitor
      await _usersCollection.doc(janitorId).delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          ManageJanitorHeader(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  _usersCollection
                      .where('role', isEqualTo: 'janitor')
                      .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                List<JanitorAccount> janitors =
                    snapshot.data!.docs
                        .map((doc) => JanitorAccount.fromFirestore(doc))
                        .toList();
                return ListView.builder(
                  padding: EdgeInsets.all(0),
                  itemCount: janitors.length,
                  itemBuilder: (context, index) {
                    JanitorAccount janitor = janitors[index];
                    return Card(
                      margin: const EdgeInsets.all(8),
                      color: Colors.grey[100],
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ListTile(
                        title: Text(
                          janitor.fullName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Username: ${janitor.username}'),
                            if (janitor.lastSeen != null)
                              Text(
                                'Last Login: ${janitor.lastSeen!.toDate()}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black,
                                ),
                              ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.green),
                              onPressed: () => _editJanitor(context, janitor),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteJanitor(janitor.id),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addJanitor(context),
        backgroundColor: Colors.purple,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
