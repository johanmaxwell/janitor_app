import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:janitor_app/pages/admin_page.dart';
import 'package:janitor_app/pages/janitor_page.dart';
import 'package:janitor_app/utils/firebase_usage_monitor.dart';
import 'package:janitor_app/utils/string_util.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  String company = '';

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final usageMonitor = FirestoreUsageMonitor();

  @override
  void initState() {
    super.initState();
    checkAutoLogin();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.clean_hands_outlined,
                size: 80,
                color: Colors.teal,
              ),
              const SizedBox(height: 16),
              const Text(
                'Janitor App',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal,
                ),
              ),
              const SizedBox(height: 32),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _usernameController,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.person),
                        hintText: 'Username',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      validator:
                          (value) =>
                              value == null || value.isEmpty
                                  ? 'Enter username'
                                  : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        hintText: 'Password',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      validator:
                          (value) =>
                              value == null || value.isEmpty
                                  ? 'Enter password'
                                  : null,
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            login(_usernameController, _passwordController);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.teal,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Login',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> login(
    TextEditingController usernameController,
    TextEditingController passwordController,
  ) async {
    final username = usernameController.text;
    final password = passwordController.text;

    QuerySnapshot result =
        await FirebaseFirestore.instance
            .collection('users')
            .where('username', isEqualTo: username.trim())
            .limit(1)
            .get();

    usageMonitor.incrementReads(result.docs.length);

    if (result.docs.isNotEmpty) {
      DocumentSnapshot userDoc = result.docs.first;
      final Map<String, dynamic> userData =
          userDoc.data() as Map<String, dynamic>;

      company = userData['company'];

      //print("password = ${StringUtil.hashPassword(password)}");
      if (userData['password'] == StringUtil.hashPassword(password)) {
        if (userData['role'] == 'admin') {
          SharedPreferences preferences = await SharedPreferences.getInstance();
          await preferences.setString('role', userData['role']);
          await preferences.setString('company', userData['company']);

          if (mounted) {
            navigateToPage(context, AdminPage(company));
          }
        } else {
          final fcmToken = await FirebaseMessaging.instance.getToken();

          await FirebaseFirestore.instance
              .collection('users')
              .doc(userDoc.id)
              .set({
                'active': true,
                'last_seen': FieldValue.serverTimestamp(),
                'fcm_token': fcmToken,
              }, SetOptions(merge: true));

          usageMonitor.incrementWrites();

          if (userData[company] != null) {
            usageMonitor.updateCompanyId(userData[company]);
          }

          SharedPreferences preferences = await SharedPreferences.getInstance();
          await preferences.setString('role', userData['role']);
          await preferences.setString('company', userData['company']);

          if (mounted) {
            navigateToPage(context, JanitorPage(company));
          }
        }
      } else {
        if (!mounted) return;
        showLoginFailedDialog(context);
        usernameController.clear();
        passwordController.clear();
      }
    }
  }

  Future<void> checkAutoLogin() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    final role = preferences.getString('role');
    final company = preferences.getString('company');

    if (company == null) return;

    if (role != null && role.isNotEmpty) {
      if (mounted) {
        usageMonitor.updateCompanyId(company);
        if (role == 'admin') {
          navigateToPage(context, AdminPage(company));
        } else {
          navigateToPage(context, JanitorPage(company));
        }
      }
    }
  }

  void showLoginFailedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: Colors.redAccent,
                  size: 60,
                ),
                const SizedBox(height: 16),
                const Text(
                  "Akun Tidak Ditemukan",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.redAccent,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  "Harap coba lagi!",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.black54),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      "OK",
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void navigateToPage(BuildContext context, Widget page) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
  }
}
