import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class SensorFormPage extends StatefulWidget {
  final String company;
  final String gender;
  final String device;
  final VoidCallback onResetSelections;

  const SensorFormPage({
    super.key,
    required this.company,
    required this.gender,
    required this.device,
    required this.onResetSelections,
  });

  @override
  State<SensorFormPage> createState() => _SensorFormPageState();
}

class _SensorFormPageState extends State<SensorFormPage> {
  final Map<String, TextEditingController> controllers = {};
  bool isEditing = false;

  @override
  void initState() {
    super.initState();
    final fields = [
      "company_code",
      "luar",
      "mqtt_password",
      "mqtt_server",
      "mqtt_user",
      "nomor_dispenser",
      "nomor_toilet",
      "setting_berat",
      "setting_jarak",
      "wifi_password",
      "wifi_ssid",
    ];

    for (final field in fields) {
      controllers[field] = TextEditingController();
    }

    fetchData();
  }

  Future<void> fetchData() async {
    final snapshot =
        await FirebaseFirestore.instance
            .collection('config')
            .doc(widget.company)
            .collection(widget.gender)
            .doc(widget.device)
            .get();

    final data = snapshot.data() as Map<String, dynamic>;
    for (final entry in data.entries) {
      controllers[entry.key]?.text = entry.value.toString();
    }
  }

  // Method to save data to Firebase
  Future<void> saveDataToFirebase() async {
    try {
      final Map<String, dynamic> updatedData = {};
      for (final entry in controllers.entries) {
        final field = entry.key;
        final controller = entry.value;
        updatedData[field] = controller.text;
      }

      await FirebaseFirestore.instance
          .collection('config')
          .doc(widget.company)
          .collection(widget.gender)
          .doc(widget.device)
          .set(updatedData);

      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: Row(
                children: [
                  Icon(FontAwesomeIcons.check, color: Colors.yellow),
                  Text("Success"),
                ],
              ),
              content: const Text("Data Berhasil Diperbarui!"),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text("OK"),
                ),
              ],
            ),
      );
    } catch (e) {
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text("Error"),
              content: Text("Failed to save data: $e"),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text("OK"),
                ),
              ],
            ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Edit Config - Device ${widget.device}"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            widget.onResetSelections();
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: Icon(isEditing ? Icons.save : Icons.edit),
            onPressed: () {
              if (isEditing) {
                saveDataToFirebase().then((_) {
                  setState(() {
                    isEditing = false;
                  });
                });
              } else {
                setState(() {
                  isEditing = !isEditing;
                });
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children:
              controllers.entries.map((entry) {
                final field = entry.key;
                final controller = entry.value;
                return TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    labelText: field,
                    enabled: isEditing,
                  ),
                  enabled: isEditing,
                  style: const TextStyle(color: Colors.black),
                );
              }).toList(),
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Dispose of all controllers
    for (final controller in controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }
}
