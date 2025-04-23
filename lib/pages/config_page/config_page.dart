import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:janitor_app/pages/config_page/config_header.dart';
import 'package:janitor_app/pages/config_page/sensor_form_page.dart';
import 'package:janitor_app/utils/string_util.dart';

class ConfigPage extends StatefulWidget {
  final String company;

  const ConfigPage({super.key, required this.company});

  @override
  State<ConfigPage> createState() => _ConfigPageState();
}

class _ConfigPageState extends State<ConfigPage> {
  String? selectedGedung;
  String? selectedLokasi;
  String? selectedGender;
  String? selectedDevice;

  Future<List<String>> fetchGedungOptions() async {
    final snapshot =
        await FirebaseFirestore.instance
            .collection('gedung')
            .doc(widget.company)
            .collection('daftar')
            .get();

    return snapshot.docs.map((doc) => doc.id).toList();
  }

  Future<List<String>> fetchLokasiOptions(String gedung) async {
    final snapshot =
        await FirebaseFirestore.instance
            .collection('lokasi')
            .doc(widget.company)
            .collection(gedung)
            .get();

    return snapshot.docs.map((doc) => doc.id).toList();
  }

  Future<List<String>> fetchDeviceOptions(String gender) async {
    final snapshot =
        await FirebaseFirestore.instance
            .collection('config')
            .doc(widget.company)
            .collection('data')
            .get();

    return snapshot.docs.map((doc) => doc.id).toList();
  }

  // Function to reset selections
  void resetSelections() {
    setState(() {
      selectedGedung = null;
      selectedLokasi = null;
      selectedGender = null;
      selectedDevice = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const ConfigHeader(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildOptionSelector(
                  title: "Select Gedung",
                  optionsFuture: fetchGedungOptions(),
                  selectedValue: selectedGedung,
                  onSelected: (value) {
                    setState(() {
                      selectedGedung = value;
                      selectedLokasi = null;
                      selectedGender = null;
                      selectedDevice = null;
                    });
                  },
                ),
                if (selectedGedung != null)
                  _buildOptionSelector(
                    title: "Select Lokasi",
                    optionsFuture: fetchLokasiOptions(selectedGedung!),
                    selectedValue: selectedLokasi,
                    onSelected: (value) {
                      setState(() {
                        selectedLokasi = value;
                        selectedGender = null;
                        selectedDevice = null;
                      });
                    },
                  ),
                if (selectedLokasi != null)
                  _buildOptionSelector(
                    title: "Select Gender",
                    options: const ["pria", "wanita"],
                    selectedValue: selectedGender,
                    onSelected: (value) {
                      setState(() {
                        selectedGender = value;
                        selectedDevice = null;
                      });
                    },
                  ),
                if (selectedGender != null)
                  _buildOptionSelector(
                    title: "Select Device",
                    optionsFuture: fetchDeviceOptions(selectedGender!),
                    selectedValue: selectedDevice,
                    onSelected: (value) {
                      setState(() {
                        selectedDevice = value;
                      });
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => SensorFormPage(
                                company: widget.company,
                                gender: selectedGender!,
                                device: selectedDevice!,
                                onResetSelections:
                                    resetSelections, // Pass the reset function
                              ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionSelector({
    required String title,
    List<String>? options,
    Future<List<String>>? optionsFuture,
    String? selectedValue,
    required Function(String) onSelected,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        if (optionsFuture != null)
          FutureBuilder<List<String>>(
            future: optionsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Text("Error: ${snapshot.error}");
              } else if (snapshot.hasData) {
                final items = snapshot.data!;
                if (title == 'Select Device') {
                  return _buildChoiceChips(
                    items,
                    selectedValue,
                    onSelected,
                    true,
                  );
                }
                return _buildChoiceChips(
                  items,
                  selectedValue,
                  onSelected,
                  false,
                );
              } else {
                return const Text("No options available.");
              }
            },
          )
        else if (options != null)
          _buildChoiceChips(options, selectedValue, onSelected, false)
        else
          const Text("No options provided."),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildChoiceChips(
    List<String> items,
    String? selectedValue,
    Function(String) onSelected,
    bool isDevice,
  ) {
    return Wrap(
      spacing: 10,
      children:
          items.map((item) {
            return ChoiceChip(
              label:
                  isDevice
                      ? Text(item.split('_').last)
                      : Text(StringUtil.snakeToCapitalized(item)),
              selected: item == selectedValue,
              onSelected: (selected) {
                if (selected) {
                  onSelected(item);
                }
              },
            );
          }).toList(),
    );
  }
}
