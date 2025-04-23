import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:janitor_app/utils/string_util.dart';

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
  bool luarValue = false; // For the checkbox

  @override
  void initState() {
    super.initState();
    final fields = [
      "mac_address",
      "gedung",
      "gender",
      "lokasi",
      "wifi_password",
      "wifi_ssid",
      "mqtt_password",
      "mqtt_port",
      "mqtt_server",
      "mqtt_user",
      "nomor_dispenser",
      "nomor_perangkat",
      "nomor_toilet",
      "setting_berat",
      "setting_jarak",
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
            .collection('data')
            .doc(widget.device)
            .get();

    final data = snapshot.data() as Map<String, dynamic>;
    for (final entry in data.entries) {
      if (entry.key == "luar") {
        luarValue = entry.value.toString().toLowerCase() == "true";
      } else {
        controllers[entry.key]?.text = entry.value.toString();
      }
    }
  }

  Future<String> validateData(Map<String, dynamic> updatedData) async {
    String validation = '';

    final querySnapshot =
        await FirebaseFirestore.instance
            .collection('config')
            .where("gedung", isEqualTo: updatedData["gedung"])
            .where("lokasi", isEqualTo: updatedData["lokasi"])
            .where("gender", isEqualTo: updatedData["gender"])
            .where("nomor_perangkat", isEqualTo: updatedData["nomor_perangkat"])
            .where(FieldPath.documentId, isNotEqualTo: widget.device)
            .get();

    if (querySnapshot.docs.isNotEmpty &&
        querySnapshot.docs.first.id != widget.device) {
      validation += '!';
    }

    if (updatedData["nomor_dispenser"].isNotEmpty) {
      final dispenserSnapshot =
          await FirebaseFirestore.instance
              .collection('config')
              .where("gedung", isEqualTo: updatedData["gedung"])
              .where("lokasi", isEqualTo: updatedData["lokasi"])
              .where("gender", isEqualTo: updatedData["gender"])
              .where(
                "nomor_dispenser",
                isEqualTo: updatedData["nomor_dispenser"],
              )
              .where(FieldPath.documentId, isNotEqualTo: widget.device)
              .get();

      if (dispenserSnapshot.docs.isNotEmpty &&
          dispenserSnapshot.docs.first.id != widget.device) {
        validation += '*';
      }
    }

    return validation;
  }

  Future<void> saveDataToFirebase() async {
    String message = '';

    try {
      final Map<String, dynamic> updatedData = {};
      for (final entry in controllers.entries) {
        final field = entry.key;
        final controller = entry.value;

        if (field == "gedung" || field == "lokasi") {
          updatedData[field] = StringUtil.toSnakeCase(controller.text);
        } else {
          updatedData[field] = controller.text;
        }
      }

      updatedData["luar"] = luarValue.toString();

      final validation = await validateData(updatedData);
      if (validation.contains(RegExp(r'[!*]'))) {
        if (validation == '!') {
          message = 'Coba gunakan nomor perangkat yang lain';
        } else if (validation == '*') {
          message = 'Coba gunakan nomor dispenser yang lain';
        } else {
          message =
              'Coba gunakan nomor perangkat dan nomor dispenser yang lain';
        }

        showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text("Konfigurasi Telah Digunakan!"),
                content: Text(message),
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
        return;
      }

      // Save data to Firebase
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
                  const Text("Success"),
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
          children: [
            ...controllers.entries.map((entry) {
              final field = entry.key;
              final controller = entry.value;

              if (field == "mac_address") {
                return TextField(
                  controller: controller,
                  decoration: InputDecoration(labelText: field),
                  style: TextStyle(color: Colors.black),
                  enabled: false,
                );
              }

              return TextField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: field,
                  enabled: isEditing && field != "mac_address",
                ),
                enabled: isEditing && field != "mac_address",
                style: const TextStyle(color: Colors.black),
              );
            }),
            CheckboxListTile(
              title: const Text("Luar"),
              value: luarValue,
              onChanged:
                  isEditing
                      ? (value) {
                        setState(() {
                          luarValue = value!;
                        });
                      }
                      : null,
            ),
          ],
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
