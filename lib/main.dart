import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:janitor_app/firebase_options.dart';
import 'package:janitor_app/pages/login_page.dart';
import 'package:janitor_app/utils/firebase_usage_monitor.dart';
import 'package:janitor_app/utils/notification_service.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
  );
  await FirebaseAuth.instance.signInAnonymously();
  await NotificationService.init();

  final usageMonitor = FirestoreUsageMonitor();

  runApp(JanitorApp(usageMonitor: usageMonitor));
}

class JanitorApp extends StatefulWidget {
  final FirestoreUsageMonitor usageMonitor;

  const JanitorApp({super.key, required this.usageMonitor});

  @override
  State<JanitorApp> createState() => _JanitorAppState();
}

class _JanitorAppState extends State<JanitorApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.usageMonitor.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      widget.usageMonitor.flushToFirestore();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Toilet Monitoring',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      theme: ThemeData(primarySwatch: Colors.blue, fontFamily: 'Roboto'),
      home: LoginPage(),
    );
  }
}
