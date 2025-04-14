import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:janitor_app/firebase_options.dart';
import 'package:janitor_app/pages/admin_page.dart';
import 'package:janitor_app/pages/chart/chart_page.dart';
import 'package:janitor_app/pages/janitor_page.dart';
import 'package:janitor_app/pages/login_page.dart';
import 'package:janitor_app/pages/manage_user/manage_user_page.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
  );
  await FirebaseAuth.instance.signInAnonymously();

  runApp(const JanitorApp());
}

class JanitorApp extends StatelessWidget {
  const JanitorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Toilet Monitoring',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      theme: ThemeData(primarySwatch: Colors.blue, fontFamily: 'Roboto'),
      routes: {
        '/login': (context) => const LoginPage(),
        '/janitor': (context) => const JanitorPage(),
        '/admin': (context) => const AdminPage(),
        '/chart': (context) => const ChartPage(),
        '/user': (context) => const ManageUserPage(),
      },
      home: LoginPage(),
    );
  }
}
