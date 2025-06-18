import 'package:cloud_firestore/cloud_firestore.dart';

class JanitorAccount {
  final String id;
  final String fullName;
  final String username;
  final String password;
  final String? company;
  final Timestamp? lastSeen;

  JanitorAccount({
    required this.id,
    required this.fullName,
    required this.username,
    required this.password,
    this.company,
    required this.lastSeen,
  });

  factory JanitorAccount.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return JanitorAccount(
      id: doc.id,
      fullName: data['full_name'],
      username: data['username'],
      password: data['password'],
      company: data['company'],
      lastSeen: data['last_seen'],
    );
  }
}
