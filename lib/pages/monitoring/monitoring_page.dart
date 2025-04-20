import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:janitor_app/models/sensor_data.dart';
import 'package:janitor_app/pages/monitoring/accordion_list.dart';
import 'package:janitor_app/pages/monitoring/gedung_dropdown.dart';
import 'package:janitor_app/pages/monitoring/gender_dropdown.dart';
import 'package:janitor_app/pages/monitoring/header.dart';

class MonitoringPage extends StatefulWidget {
  final String role;
  const MonitoringPage({super.key, required this.role});

  @override
  State<MonitoringPage> createState() => _MonitoringPageState();
}

class _MonitoringPageState extends State<MonitoringPage> {
  String? selectedGedung;
  String? selectedGender;
  late Future<List<String>> gedungFuture;

  @override
  void initState() {
    super.initState();
    gedungFuture = fetchGedungList();
  }

  Future<List<String>> fetchGedungList() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('sensor').get();
    return snapshot.docs.map((doc) => doc.id).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        MonitoringHeader(widget.role),
        FutureBuilder<List<String>>(
          future: gedungFuture,
          builder: (context, snapshot) {
            final gedungList = snapshot.data ?? [];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: GedungDropdown(
                      gedungList: gedungList,
                      selectedGedung: selectedGedung,
                      onChanged: (value) {
                        setState(() {
                          selectedGedung = value;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: GenderDropdown(
                      selectedGender: selectedGender,
                      onChanged: (value) {
                        setState(() {
                          selectedGender = value;
                        });
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        if (selectedGedung != null && selectedGender != null)
          _buildToiletAccordionList(),
      ],
    );
  }

  Widget _buildToiletAccordionList() {
    final tisuStream =
        FirebaseFirestore.instance
            .collection('sensor')
            .doc(selectedGedung)
            .collection('tisu')
            .where('gender', isEqualTo: selectedGender)
            .orderBy('lokasi')
            .snapshots();

    final bauStream =
        FirebaseFirestore.instance
            .collection('sensor')
            .doc(selectedGedung)
            .collection('bau')
            .where('gender', isEqualTo: selectedGender)
            .snapshots();

    final sabunStream =
        FirebaseFirestore.instance
            .collection('sensor')
            .doc(selectedGedung)
            .collection('sabun')
            .where('gender', isEqualTo: selectedGender)
            .snapshots();

    if (selectedGedung != null && selectedGender != null) {
      return StreamBuilder<QuerySnapshot>(
        stream: tisuStream,
        builder: (context, tisuSnapshot) {
          if (!tisuSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          return StreamBuilder<QuerySnapshot>(
            stream: bauStream,
            builder: (context, bauSnapshot) {
              if (!bauSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              return StreamBuilder<QuerySnapshot>(
                stream: sabunStream,
                builder: (context, sabunSnapshot) {
                  if (!sabunSnapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final tisuFloorMap = <String, List<SensorData>>{};
                  for (var doc in tisuSnapshot.data!.docs) {
                    final data = SensorData.fromFirestore(
                      doc.data() as Map<String, dynamic>,
                    );
                    tisuFloorMap.putIfAbsent(data.lokasi, () => []).add(data);
                  }

                  final bauFloorMap = <String, List<SensorData>>{};
                  for (var doc in bauSnapshot.data!.docs) {
                    final data = SensorData.fromFirestoreWithoutAmount(
                      doc.data() as Map<String, dynamic>,
                    );
                    bauFloorMap.putIfAbsent(data.lokasi, () => []).add(data);
                  }

                  final sabunFloorMap = <String, List<SensorData>>{};
                  for (var doc in sabunSnapshot.data!.docs) {
                    final data = SensorData.fromFirestore(
                      doc.data() as Map<String, dynamic>,
                    );
                    sabunFloorMap.putIfAbsent(data.lokasi, () => []).add(data);
                  }

                  return MonitoringAccordionList(
                    tisuFloorMap: tisuFloorMap,
                    bauFloorMap: bauFloorMap,
                    sabunFloorMap: sabunFloorMap,
                    gender: selectedGender!,
                  );
                },
              );
            },
          );
        },
      );
    } else {
      return Column();
    }
  }
}
