import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:janitor_app/utils/firebase_usage_monitor.dart';
import 'package:janitor_app/utils/string_util.dart';

class SensorFormPage extends StatefulWidget {
  final String company;
  final String gender;
  final String device;
  final String gedung;
  final String location;
  final VoidCallback onResetSelections;

  const SensorFormPage({
    super.key,
    required this.company,
    required this.gender,
    required this.device,
    required this.gedung,
    required this.location,
    required this.onResetSelections,
  });

  @override
  State<SensorFormPage> createState() => _SensorFormPageState();
}

class _SensorFormPageState extends State<SensorFormPage> {
  final Map<String, TextEditingController> controllers = {};
  bool isEditing = false;
  final Map<String, bool> checkboxValues = {
    'okupansi': false,
    'pengunjung': false,
    'tisu': false,
    'sabun': false,
    'bau': false,
    'is_luar': false,
  };
  String? placement = 'left';
  String? gender = 'pria';
  final usageMonitor = FirestoreUsageMonitor();

  @override
  void initState() {
    super.initState();
    final fields = [
      "mac_address",
      "version",
      "company",
      "gedung",
      "lokasi",
      "wifi_password",
      "wifi_ssid",
      "mqtt_server",
      "mqtt_port",
      "mqtt_user",
      "mqtt_password",
      "nomor_perangkat",
      "nomor_toilet",
      "nomor_dispenser",
      "jarak_deteksi",
      "berat_tisu",
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

    usageMonitor.incrementReads();

    if (snapshot.exists) {
      final data = snapshot.data() as Map<String, dynamic>;
      for (final entry in data.entries) {
        if (checkboxValues.containsKey(entry.key)) {
          checkboxValues[entry.key] =
              entry.value.toString().toLowerCase() == "on";
        } else if (entry.key == "placement") {
          placement = entry.value.toString();
          controllers[entry.key]?.text = entry.value.toString();
        } else if (entry.key == "gender") {
          gender =
              entry.value
                  .toString(); // Override default if Firebase has a value
        } else {
          controllers[entry.key]?.text = entry.value.toString();
        }
      }
      setState(() {});
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

    usageMonitor.incrementReads(querySnapshot.docs.length);

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

      usageMonitor.incrementReads(dispenserSnapshot.docs.length);

      if (dispenserSnapshot.docs.isNotEmpty &&
          dispenserSnapshot.docs.first.id != widget.device) {
        validation += '*';
      }
    }

    return validation;
  }

  Future<void> saveDataToFirebase() async {
    String message = '';
    final List<String> types = [
      'baterai',
      'bau',
      'okupansi',
      'pengunjung',
      'sabun',
      'tisu',
    ];

    try {
      final Map<String, dynamic> updatedData = {};
      for (final entry in controllers.entries) {
        final field = entry.key;
        final controller = entry.value;

        if (field == "gedung" || field == "lokasi") {
          updatedData[field] = StringUtil.toSnakeCase(controller.text);
        } else if (field == "version") {
          final currentVersion = int.tryParse(controller.text) ?? 0;
          final newVersion = currentVersion + 1;
          updatedData[field] = newVersion.toString();
          controller.text = newVersion.toString();
        } else {
          updatedData[field] = controller.text;
        }
      }

      for (final entry in checkboxValues.entries) {
        updatedData[entry.key] = entry.value ? "on" : "";
      }

      // Handle gender and placement
      updatedData["gender"] = gender ?? "pria";
      updatedData["placement"] =
          placement ?? (checkboxValues['pengunjung']! ? "left" : "");

      // Clear optional fields if their checkboxes are unchecked
      if (!checkboxValues['okupansi']! &&
          !checkboxValues['tisu']! &&
          !checkboxValues['bau']!) {
        updatedData["nomor_toilet"] = "";
      }
      if (!checkboxValues['sabun']!) {
        updatedData["nomor_dispenser"] = "";
      }
      if (!checkboxValues['bau']!) {
        updatedData["is_luar"] = "";
      }
      if (!checkboxValues['okupansi']!) {
        updatedData["jarak_deteksi"] = "";
      }
      if (!checkboxValues['tisu']!) {
        updatedData["berat_tisu"] = "";
      }
      if (!checkboxValues['pengunjung']!) {
        updatedData["placement"] = "";
      }

      final deviceNumber = widget.device.split('_').last;
      final hasChanges =
          updatedData["company"] != widget.company ||
          updatedData["gender"] != widget.gender ||
          updatedData["gedung"] != widget.gedung ||
          updatedData["lokasi"] != widget.location ||
          updatedData["nomor_perangkat"] != deviceNumber;

      final newDeviceId =
          "${updatedData["gedung"]}_${updatedData["lokasi"]}_${updatedData["gender"]}_${updatedData["nomor_perangkat"]}";

      final validation = await validateData(updatedData);
      if (validation.contains(RegExp(r'[!*]'))) {
        if (validation.contains('!') && validation.contains('*')) {
          message =
              'Coba gunakan nomor perangkat dan nomor dispenser yang lain';
        } else if (validation.contains('!')) {
          message = 'Coba gunakan nomor perangkat yang lain';
        } else if (validation.contains('*')) {
          message = 'Coba gunakan nomor dispenser yang lain';
        }

        showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text("Konfigurasi Tidak Valid!"),
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

      // Move sensor data if key fields have changed
      if (hasChanges) {
        final oldDeviceRef = FirebaseFirestore.instance
            .collection('config')
            .doc(widget.company)
            .collection(widget.gender)
            .doc(widget.device);

        // Check if old gedung is still needed in both genders
        final oldGedungConfigsPria =
            await FirebaseFirestore.instance
                .collection('config')
                .doc(widget.company)
                .collection('pria')
                .where('gedung', isEqualTo: widget.gedung)
                .where(FieldPath.documentId, isNotEqualTo: widget.device)
                .get();

        final oldGedungConfigsWanita =
            await FirebaseFirestore.instance
                .collection('config')
                .doc(widget.company)
                .collection('wanita')
                .where('gedung', isEqualTo: widget.gedung)
                .get();

        usageMonitor.incrementReads(
          oldGedungConfigsPria.docs.length + oldGedungConfigsWanita.docs.length,
        );

        // Check if old lokasi is still needed in both genders
        final oldLokasiConfigsPria =
            await FirebaseFirestore.instance
                .collection('config')
                .doc(widget.company)
                .collection('pria')
                .where('gedung', isEqualTo: widget.gedung)
                .where('lokasi', isEqualTo: widget.location)
                .where(FieldPath.documentId, isNotEqualTo: widget.device)
                .get();

        final oldLokasiConfigsWanita =
            await FirebaseFirestore.instance
                .collection('config')
                .doc(widget.company)
                .collection('wanita')
                .where('gedung', isEqualTo: widget.gedung)
                .where('lokasi', isEqualTo: widget.location)
                .get();

        usageMonitor.incrementReads(
          oldLokasiConfigsPria.docs.length + oldLokasiConfigsWanita.docs.length,
        );

        // Delete old device config
        await oldDeviceRef.delete();
        usageMonitor.incrementWrites();

        // Delete old gedung if no other devices use it in either gender
        if (oldGedungConfigsPria.docs.isEmpty &&
            oldGedungConfigsWanita.docs.isEmpty) {
          await FirebaseFirestore.instance
              .collection('gedung')
              .doc(widget.company)
              .collection('daftar')
              .doc(widget.gedung)
              .delete();
          usageMonitor.incrementWrites();
        }

        // Delete old lokasi if no other devices use it in either gender
        if (oldLokasiConfigsPria.docs.isEmpty &&
            oldLokasiConfigsWanita.docs.isEmpty) {
          await FirebaseFirestore.instance
              .collection('lokasi')
              .doc(widget.company)
              .collection(widget.gedung)
              .doc(widget.location)
              .delete();
          usageMonitor.incrementWrites();
        }

        // Migrate sensor data
        for (final type in types) {
          final oldSensorRef = FirebaseFirestore.instance
              .collection('sensor')
              .doc(widget.company)
              .collection(widget.gender)
              .doc(widget.gedung)
              .collection(type)
              .doc(widget.device);

          final oldSensorSnapshot = await oldSensorRef.get();
          usageMonitor.incrementReads();
          if (oldSensorSnapshot.exists) {
            final oldSensorData = oldSensorSnapshot.data() ?? {};

            // Update lokasi
            oldSensorData['lokasi'] = updatedData['lokasi'];

            // Update nomor based on type
            if (type == 'baterai') {
              oldSensorData['nomor'] = updatedData['nomor_perangkat'];
            } else if (['bau', 'okupansi', 'tisu'].contains(type)) {
              oldSensorData['nomor'] = updatedData['nomor_toilet'];
            } else if (type == 'sabun') {
              oldSensorData['nomor'] = updatedData['nomor_dispenser'];
            }

            await oldSensorRef.delete();
            usageMonitor.incrementWrites();

            await FirebaseFirestore.instance
                .collection('sensor')
                .doc(updatedData['company'])
                .collection(updatedData['gender'])
                .doc(updatedData['gedung'])
                .collection(type)
                .doc(newDeviceId)
                .set(oldSensorData);

            usageMonitor.incrementWrites();
          }
        }
      }

      // Update the new device config
      await FirebaseFirestore.instance
          .collection('config')
          .doc(updatedData["company"])
          .collection(updatedData["gender"])
          .doc(newDeviceId)
          .set(updatedData);

      usageMonitor.incrementWrites();

      // Update gedung collection
      await FirebaseFirestore.instance
          .collection('gedung')
          .doc(updatedData["company"])
          .collection('daftar')
          .doc(updatedData["gedung"])
          .set({'company': updatedData["company"]}, SetOptions(merge: true));

      usageMonitor.incrementWrites();

      // Update lokasi collection
      await FirebaseFirestore.instance
          .collection('lokasi')
          .doc(updatedData["company"])
          .collection(updatedData["gedung"])
          .doc(updatedData["lokasi"])
          .set({
            'company': updatedData["company"],
            'gedung': updatedData["gedung"],
          }, SetOptions(merge: true));

      usageMonitor.incrementWrites();

      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: Row(
                children: [
                  Icon(FontAwesomeIcons.check, color: Colors.yellow),
                  const Text(" Success"),
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
    // Always visible fields
    final List<String> alwaysVisibleFields = [
      "mac_address",
      "version",
      "company",
      "gedung",
      "lokasi",
      "wifi_ssid",
      "wifi_password",
      "mqtt_server",
      "mqtt_port",
      "mqtt_user",
      "mqtt_password",
      "nomor_perangkat",
    ];

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
            // Always visible text fields
            ...alwaysVisibleFields.map((field) {
              final controller = controllers[field];
              if (controller == null) return const SizedBox.shrink();
              return TextField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: field,
                  enabled:
                      isEditing && field != "mac_address" && field != "version",
                ),
                enabled:
                    isEditing && field != "mac_address" && field != "version",
                style: const TextStyle(color: Colors.black),
              );
            }),
            // Gender radio buttons
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    'Gender',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                RadioListTile<String>(
                  title: const Text('Pria'),
                  value: 'pria',
                  groupValue: gender,
                  onChanged:
                      isEditing
                          ? (value) {
                            setState(() {
                              gender = value;
                            });
                          }
                          : null,
                ),
                RadioListTile<String>(
                  title: const Text('Wanita'),
                  value: 'wanita',
                  groupValue: gender,
                  onChanged:
                      isEditing
                          ? (value) {
                            setState(() {
                              gender = value;
                            });
                          }
                          : null,
                ),
              ],
            ),
            // Checkbox fields
            ...checkboxValues.entries.map((entry) {
              return CheckboxListTile(
                title: Text(entry.key),
                value: entry.value,
                onChanged:
                    isEditing
                        ? (value) {
                          setState(() {
                            checkboxValues[entry.key] = value!;
                          });
                        }
                        : null,
              );
            }),
            // Conditional optional fields
            if (checkboxValues['okupansi']! ||
                checkboxValues['tisu']! ||
                checkboxValues['bau']!)
              TextField(
                controller: controllers["nomor_toilet"],
                decoration: InputDecoration(
                  labelText: "nomor_toilet",
                  enabled: isEditing,
                ),
                enabled: isEditing,
                style: const TextStyle(color: Colors.black),
              ),
            if (checkboxValues['sabun']!)
              TextField(
                controller: controllers["nomor_dispenser"],
                decoration: InputDecoration(
                  labelText: "nomor_dispenser",
                  enabled: isEditing,
                ),
                enabled: isEditing,
                style: const TextStyle(color: Colors.black),
              ),
            if (checkboxValues['bau']!)
              TextField(
                controller: controllers["is_luar"],
                decoration: InputDecoration(
                  labelText: "is_luar",
                  enabled: isEditing,
                ),
                enabled: isEditing,
                style: const TextStyle(color: Colors.black),
              ),
            if (checkboxValues['okupansi']!)
              TextField(
                controller: controllers["jarak_deteksi"],
                decoration: InputDecoration(
                  labelText: "jarak_deteksi",
                  enabled: isEditing,
                ),
                enabled: isEditing,
                style: const TextStyle(color: Colors.black),
              ),
            if (checkboxValues['tisu']!)
              TextField(
                controller: controllers["berat_tisu"],
                decoration: InputDecoration(
                  labelText: "berat_tisu",
                  enabled: isEditing,
                ),
                enabled: isEditing,
                style: const TextStyle(color: Colors.black),
              ),
            if (checkboxValues['pengunjung']!)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      'Sensor Placement',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  RadioListTile<String>(
                    title: const Text('Left'),
                    value: 'left',
                    groupValue: placement,
                    onChanged:
                        isEditing
                            ? (value) {
                              setState(() {
                                placement = value;
                              });
                            }
                            : null,
                  ),
                  RadioListTile<String>(
                    title: const Text('Right'),
                    value: 'right',
                    groupValue: placement,
                    onChanged:
                        isEditing
                            ? (value) {
                              setState(() {
                                placement = value;
                              });
                            }
                            : null,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    for (final controller in controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }
}
