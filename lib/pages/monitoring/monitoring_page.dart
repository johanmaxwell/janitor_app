import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:janitor_app/models/sensor_data.dart';
import 'package:janitor_app/pages/monitoring/accordion_list.dart';
import 'package:janitor_app/pages/monitoring/gedung_dropdown.dart';
import 'package:janitor_app/pages/monitoring/gender_dropdown.dart';
import 'package:janitor_app/pages/monitoring/header.dart';
import 'package:janitor_app/utils/firebase_usage_monitor.dart';

class MonitoringPage extends StatefulWidget {
  final String role;
  final String company;

  const MonitoringPage({super.key, required this.role, required this.company});

  @override
  State<MonitoringPage> createState() => _MonitoringPageState();
}

class _MonitoringPageState extends State<MonitoringPage> {
  String? selectedGedung;
  String? selectedGender;
  late Future<List<String>> gedungFuture;
  final usageMonitor = FirestoreUsageMonitor();

  @override
  void initState() {
    super.initState();
    gedungFuture = fetchGedungList();
  }

  Future<List<String>> fetchGedungList() async {
    final snapshot =
        await FirebaseFirestore.instance
            .collection('gedung')
            .doc(widget.company)
            .collection('daftar')
            .get();

    usageMonitor.incrementReads(snapshot.docs.length);
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
            .doc(widget.company)
            .collection(selectedGender!)
            .doc(selectedGedung)
            .collection('tisu')
            .orderBy('lokasi')
            .snapshots();

    final bauStream =
        FirebaseFirestore.instance
            .collection('sensor')
            .doc(widget.company)
            .collection(selectedGender!)
            .doc(selectedGedung)
            .collection('bau')
            .snapshots();

    final sabunStream =
        FirebaseFirestore.instance
            .collection('sensor')
            .doc(widget.company)
            .collection(selectedGender!)
            .doc(selectedGedung)
            .collection('sabun')
            .snapshots();

    final bateraiStream =
        FirebaseFirestore.instance
            .collection('sensor')
            .doc(widget.company)
            .collection(selectedGender!)
            .doc(selectedGedung)
            .collection('baterai')
            .snapshots();

    if (selectedGedung != null && selectedGender != null) {
      return StreamBuilder<QuerySnapshot>(
        stream: tisuStream,
        builder: (context, tisuSnapshot) {
          final tisuFloorMap = <String, List<SensorData>>{};
          if (tisuSnapshot.hasData) {
            usageMonitor.incrementReads(tisuSnapshot.data!.size);
            for (var doc in tisuSnapshot.data!.docs) {
              final data = SensorData.fromFirestore(
                doc.data() as Map<String, dynamic>,
              );
              tisuFloorMap.putIfAbsent(data.lokasi, () => []).add(data);
            }
          }

          return StreamBuilder<QuerySnapshot>(
            stream: bauStream,
            builder: (context, bauSnapshot) {
              final bauFloorMap = <String, List<SensorData>>{};
              if (bauSnapshot.hasData) {
                usageMonitor.incrementReads(bauSnapshot.data!.size);
                for (var doc in bauSnapshot.data!.docs) {
                  final data = SensorData.fromFirestoreWithoutAmount(
                    doc.data() as Map<String, dynamic>,
                  );
                  bauFloorMap.putIfAbsent(data.lokasi, () => []).add(data);
                }
              }

              return StreamBuilder<QuerySnapshot>(
                stream: sabunStream,
                builder: (context, sabunSnapshot) {
                  final sabunFloorMap = <String, List<SensorData>>{};
                  if (sabunSnapshot.hasData) {
                    usageMonitor.incrementReads(sabunSnapshot.data!.size);
                    for (var doc in sabunSnapshot.data!.docs) {
                      final data = SensorData.fromFirestore(
                        doc.data() as Map<String, dynamic>,
                      );
                      sabunFloorMap
                          .putIfAbsent(data.lokasi, () => [])
                          .add(data);
                    }
                  }

                  return StreamBuilder<QuerySnapshot>(
                    stream: bateraiStream,
                    builder: (context, bateraiSnapshot) {
                      final bateraiFloorMap = <String, List<SensorData>>{};
                      if (bateraiSnapshot.hasData) {
                        usageMonitor.incrementReads(bateraiSnapshot.data!.size);
                        for (var doc in bateraiSnapshot.data!.docs) {
                          final data = SensorData.fromFirestore(
                            doc.data() as Map<String, dynamic>,
                          );
                          bateraiFloorMap
                              .putIfAbsent(data.lokasi, () => [])
                              .add(data);
                        }
                      }

                      // Show loading indicator only if all streams are still loading
                      if (!tisuSnapshot.hasData &&
                          !bauSnapshot.hasData &&
                          !sabunSnapshot.hasData &&
                          !bateraiSnapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      // Collect all unique locations
                      final allLocations = <String>{};
                      allLocations.addAll(tisuFloorMap.keys);
                      allLocations.addAll(bauFloorMap.keys);
                      allLocations.addAll(sabunFloorMap.keys);
                      allLocations.addAll(bateraiFloorMap.keys);

                      // Ensure all locations exist in all maps
                      for (final location in allLocations) {
                        tisuFloorMap.putIfAbsent(location, () => []);
                        bauFloorMap.putIfAbsent(location, () => []);
                        sabunFloorMap.putIfAbsent(location, () => []);
                        bateraiFloorMap.putIfAbsent(location, () => []);
                      }

                      return MonitoringAccordionList(
                        tisuFloorMap: tisuFloorMap,
                        bauFloorMap: bauFloorMap,
                        sabunFloorMap: sabunFloorMap,
                        bateraiFloorMap: bateraiFloorMap,
                        gender: selectedGender!,
                      );
                    },
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
