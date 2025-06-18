import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:janitor_app/models/janitor_account.dart';
import 'package:janitor_app/pages/manage_janitor/header.dart';
import 'package:janitor_app/pages/manage_janitor/janitor_dialog.dart';
import 'package:janitor_app/utils/firebase_usage_monitor.dart';

class ManageJanitorPage extends StatefulWidget {
  final String company;

  const ManageJanitorPage({super.key, required this.company});

  @override
  State<ManageJanitorPage> createState() => _ManageJanitorPageState();
}

class _ManageJanitorPageState extends State<ManageJanitorPage> {
  final JanitorDialog _janitorDialog = JanitorDialog();
  final usageMonitor = FirestoreUsageMonitor();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const ManageJanitorHeader(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('users')
                      .where('role', isEqualTo: 'janitor')
                      .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                usageMonitor.incrementReads(snapshot.data!.size);

                List<JanitorAccount> janitors =
                    snapshot.data!.docs
                        .map((doc) => JanitorAccount.fromFirestore(doc))
                        .toList();

                return ListView.builder(
                  padding: EdgeInsets.zero,
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
                              onPressed:
                                  () => _janitorDialog.editJanitor(
                                    context,
                                    janitor,
                                  ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed:
                                  () => _janitorDialog.deleteJanitor(
                                    context,
                                    janitor.id,
                                  ),
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
        onPressed: () => _janitorDialog.addJanitor(context, widget.company),
        backgroundColor: Colors.purple,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
