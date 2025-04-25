import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:janitor_app/models/sensor_data.dart';
import 'package:janitor_app/pages/monitoring/percentage_icon.dart';
import 'package:janitor_app/utils/string_util.dart';

class MonitoringAccordionList extends StatelessWidget {
  final Map<String, List<SensorData>> tisuFloorMap;
  final Map<String, List<SensorData>> bauFloorMap;
  final Map<String, List<SensorData>> sabunFloorMap;
  final Map<String, List<SensorData>> bateraiFloorMap;
  final String gender;

  const MonitoringAccordionList({
    super.key,
    required this.tisuFloorMap,
    required this.bauFloorMap,
    required this.sabunFloorMap,
    required this.bateraiFloorMap,
    required this.gender,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children:
            _checkFloorList(
              tisuFloorMap,
              bauFloorMap,
              sabunFloorMap,
              bateraiFloorMap,
            ).map((lokasi) {
              final tisu = List<SensorData>.from(tisuFloorMap[lokasi] ?? []);
              final bau = List<SensorData>.from(bauFloorMap[lokasi] ?? []);
              final sabun = List<SensorData>.from(sabunFloorMap[lokasi] ?? []);
              final baterai = List<SensorData>.from(
                bateraiFloorMap[lokasi] ?? [],
              );

              tisu.sort(
                (a, b) => int.parse(a.number).compareTo(int.parse(b.number)),
              );
              bau.sort(
                (a, b) => int.parse(a.number).compareTo(int.parse(b.number)),
              );
              sabun.sort(
                (a, b) => int.parse(a.number).compareTo(int.parse(b.number)),
              );
              baterai.sort(
                (a, b) => int.parse(a.number).compareTo(int.parse(b.number)),
              );

              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: ExpansionTile(
                  title: Align(
                    alignment: Alignment.centerLeft,
                    child: Row(
                      children: [
                        Text(
                          StringUtil.snakeToCapitalized(lokasi),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.circle,
                          color: _getStatusColor(tisu, bau, sabun, baterai),
                        ),
                      ],
                    ),
                  ),
                  collapsedBackgroundColor: Colors.teal[300],
                  collapsedTextColor: Colors.white,
                  backgroundColor: Colors.white,
                  tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  children: [
                    _buildSensorSection(
                      title: "Tisu",
                      items: tisu,
                      icon: FontAwesomeIcons.toiletPaper,
                    ),
                    const Divider(
                      thickness: 0.5,
                      height: 30,
                      color: Colors.grey,
                    ),
                    _buildSensorSection(
                      title: "Bau",
                      items: bau,
                      icon: FontAwesomeIcons.wind,
                    ),
                    const Divider(
                      thickness: 0.5,
                      height: 30,
                      color: Colors.grey,
                    ),
                    _buildSensorSection(
                      title: "Sabun",
                      items: sabun,
                      icon: FontAwesomeIcons.pumpSoap,
                    ),
                    const Divider(
                      thickness: 0.5,
                      height: 30,
                      color: Colors.grey,
                    ),
                    _buildSensorSection(
                      title: "Baterai",
                      items: baterai,
                      icon: FontAwesomeIcons.batteryFull,
                    ),
                  ],
                ),
              );
            }).toList(),
      ),
    );
  }

  Widget _buildSensorSection({
    required String title,
    required List<SensorData> items,
    required IconData icon,
  }) {
    String text = '';
    Color? color;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 60,
            child: Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),

          const SizedBox(width: 8),

          Expanded(
            child: Wrap(
              alignment: WrapAlignment.start,
              spacing: 25,
              runSpacing: 12,
              children:
                  items.map((item) {
                    if (title == 'Bau' && int.parse(item.number) > 1000) {
                      text = 'Luar';
                    } else if (title == 'Sabun') {
                      text = 'Sabun ${item.number}';
                    } else if (title == 'Baterai') {
                      text = 'Device ${item.number}';
                    } else {
                      text = 'Toilet ${item.number}';
                    }

                    switch (item.status) {
                      case 'good':
                        color = Colors.lightGreen;
                        break;
                      case 'ok':
                        color = Colors.yellowAccent;
                        break;
                      case 'bad':
                        color = Colors.redAccent;
                        break;
                    }

                    final percentage = double.tryParse(item.amount ?? '100.0');

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        title != 'Baterai'
                            ? PercentageIcon(
                              icon: icon,
                              percentage: percentage!,
                              color: color,
                            )
                            : chooseBaterai(item.status),
                        const SizedBox(height: 2),
                        Text(text, style: const TextStyle(fontSize: 12)),
                        Text(
                          title == 'Bau'
                              ? item.status.toUpperCase()
                              : "${(percentage! * 100).toStringAsFixed(0)}%",
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    );
                  }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  List<String> _checkFloorList(
    Map<String, List<SensorData>> tisuFloorMap,
    Map<String, List<SensorData>> bauFloorMap,
    Map<String, List<SensorData>> sabunFloorMap,
    Map<String, List<SensorData>> bateraiFloorMap,
  ) {
    final keysTisu = tisuFloorMap.keys.toSet();
    final keysBau = bauFloorMap.keys.toSet();
    final keysSabun = sabunFloorMap.keys.toSet();
    final keysBaterai = bateraiFloorMap.keys.toSet();

    if (!keysTisu.containsAll(keysBau) &&
        keysBau.containsAll(keysSabun) &&
        keysSabun.containsAll(keysTisu) &&
        keysTisu.containsAll(keysBaterai)) {
      final merged =
          {...keysTisu, ...keysBau, ...keysSabun, ...keysBaterai}.toList();
      merged.sort();
      return merged;
    } else {
      return keysTisu.toList();
    }
  }

  Color _getStatusColor(
    List<SensorData> tisuList,
    List<SensorData> bauList,
    List<SensorData> sabunList,
    List<SensorData> bateraiList,
  ) {
    final hasBad =
        tisuList.any((e) => e.status == 'bad') ||
        bauList.any((e) => e.status == 'bad') ||
        sabunList.any((e) => e.status == 'bad') ||
        bateraiList.any((e) => e.status == 'bad');

    final hasOk =
        tisuList.any((e) => e.status == 'ok') ||
        bauList.any((e) => e.status == 'ok') ||
        sabunList.any((e) => e.status == 'ok') ||
        bateraiList.any((e) => e.status == 'ok');

    if (hasBad) {
      return Colors.red;
    } else if (hasOk) {
      return Colors.yellow;
    } else {
      return Colors.green;
    }
  }

  Widget chooseBaterai(String status) {
    if (status == 'good') {
      return Icon(FontAwesomeIcons.batteryFull, color: Colors.green, size: 40);
    } else if (status == 'ok') {
      return Icon(FontAwesomeIcons.batteryHalf, color: Colors.yellow, size: 40);
    } else {
      return Icon(FontAwesomeIcons.batteryQuarter, color: Colors.red, size: 40);
    }
  }
}
