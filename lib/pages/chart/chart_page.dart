import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:janitor_app/pages/chart/logs_chart.dart';
import 'package:janitor_app/utils/string_util.dart';

class ChartPage extends StatefulWidget {
  final String company;

  const ChartPage({super.key, required this.company});

  @override
  State<ChartPage> createState() => _ChartPageState();
}

class _ChartPageState extends State<ChartPage> {
  String? _selectedMode;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _showAdvancedFilters = false;

  String? _selectedGedung;
  String? _selectedGender;
  String? _selectedLokasi;

  List<String> _gedungList = [];
  List<String> _lokasiList = [];

  Future<void> fetchGedungList() async {
    final gedungSnapshot =
        await FirebaseFirestore.instance
            .collection('gedung')
            .doc(widget.company)
            .collection('daftar')
            .get();

    setState(() {
      _gedungList = gedungSnapshot.docs.map((doc) => doc.id).toList();
    });
  }

  @override
  void initState() {
    super.initState();
    _selectedMode = 'Daily';
    _startDate = DateTime.now().subtract(const Duration(days: 7));
    _endDate = DateTime.now();

    fetchGedungList();
  }

  final List<String> modes = ['Daily', 'Weekly', 'Monthly', 'Yearly'];
  final List<String> genders = ['pria', 'wanita'];

  Stream<Map<String, int>> getLogsGroupedByMode(
    String mode,
    String type,
    String? status,
  ) {
    Query query = FirebaseFirestore.instance
        .collection('logs')
        .doc(widget.company)
        .collection(type);

    if (type != 'pengunjung' && status != null) {
      query = query.where('status', isEqualTo: status);
    }

    query = query
        .where(
          'timestamp',
          isGreaterThanOrEqualTo: Timestamp.fromDate(_startDate!),
        )
        .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(_endDate!));

    if (_selectedGedung != null) {
      query = query.where('gedung', isEqualTo: _selectedGedung);
    }
    if (_selectedGender != null) {
      query = query.where('gender', isEqualTo: _selectedGender);
    }
    if (_selectedLokasi != null) {
      query = query.where('lokasi', isEqualTo: _selectedLokasi);
    }

    return query.snapshots().map((snapshot) {
      final Map<String, int> groupedData = {};
      for (var doc in snapshot.docs) {
        final timestamp = (doc['timestamp'] as Timestamp).toDate();
        String key;
        switch (mode) {
          case 'Daily':
            key = DateFormat('yyyy-MM-dd').format(timestamp);
            break;
          case 'Weekly':
            final week = weekNumber(timestamp);
            key = '${timestamp.year}-W$week';
            break;
          case 'Monthly':
            key = DateFormat('yyyy-MM').format(timestamp);
            break;
          case 'Yearly':
            key = DateFormat('yyyy').format(timestamp);
            break;
          default:
            key = '';
        }
        groupedData[key] = (groupedData[key] ?? 0) + 1;
      }

      if (type == 'pengunjung') {
        final adjustedData = <String, int>{};
        groupedData.forEach((key, value) {
          adjustedData[key] = (value / 2).round();
        });
        return adjustedData;
      }

      return groupedData;
    });
  }

  int weekNumber(DateTime date) {
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final daysOffset = date.difference(firstDayOfYear).inDays;
    return ((daysOffset + firstDayOfYear.weekday) / 7).ceil();
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final initialStartDate =
        _startDate ?? DateTime.now().subtract(const Duration(days: 7));
    final initialEndDate = _endDate ?? DateTime.now();

    final pickedDates = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: initialStartDate,
        end: initialEndDate,
      ),
    );

    if (pickedDates != null) {
      setState(() {
        _startDate = pickedDates.start;
        _endDate = pickedDates.end;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16.0),
          color: Colors.tealAccent,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 50),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Logs Dashboard',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey, width: 1),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedMode,
                        icon: const Icon(
                          Icons.arrow_drop_down,
                          size: 30,
                          color: Colors.black87,
                        ),
                        iconSize: 30,
                        elevation: 16,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                        onChanged: (value) {
                          setState(() {
                            _selectedMode = value!;
                          });
                        },
                        items:
                            modes.map((mode) {
                              return DropdownMenuItem<String>(
                                value: mode,
                                child: Text(mode),
                              );
                            }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () => _selectDateRange(context),
                    child: Text(
                      'Filter (${DateFormat('dd MMM yyyy').format(_startDate!)} - ${DateFormat('dd MMM yyyy').format(_endDate!)})',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Show Advanced Filters'),
                  Switch(
                    value: _showAdvancedFilters,
                    onChanged: (value) {
                      setState(() {
                        _showAdvancedFilters = value;
                      });
                    },
                  ),
                ],
              ),
              if (_showAdvancedFilters)
                Row(
                  children: [
                    Expanded(
                      child: _buildDropdown(
                        label: 'Gedung',
                        items: _gedungList,
                        hint: 'Select Gedung',
                        value: _selectedGedung,
                        onChanged: (value) async {
                          setState(() {
                            _selectedGedung = value;
                          });

                          if (_selectedGedung != null) {
                            final lokasiSnapshot =
                                await FirebaseFirestore.instance
                                    .collection('lokasi')
                                    .doc(widget.company)
                                    .collection(_selectedGedung!)
                                    .get();
                            setState(() {
                              _lokasiList =
                                  lokasiSnapshot.docs
                                      .map((doc) => doc.id)
                                      .toList();
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildDropdown(
                        label: 'Gender',
                        items: genders,
                        hint: 'Select Gender',
                        value: _selectedGender,
                        onChanged: (value) {
                          setState(() {
                            _selectedGender = value;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildDropdown(
                        label: 'Lokasi',
                        items: _lokasiList,
                        hint: 'Select Lokasi',
                        value: _selectedLokasi,
                        onChanged: (value) async {
                          setState(() {
                            _selectedLokasi = value;
                          });
                        },
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LogsChart(
                  title: 'Occupancy Logs',
                  stream: getLogsGroupedByMode(
                    _selectedMode!,
                    'okupansi',
                    'occupied',
                  ),
                  color: Colors.green,
                  mode: _selectedMode!,
                  chartType: 'bar',
                ),
                const SizedBox(height: 32),
                LogsChart(
                  title: 'Tissue Logs',
                  stream: getLogsGroupedByMode(_selectedMode!, 'tisu', 'good'),
                  color: Colors.blue,
                  mode: _selectedMode!,
                  chartType: 'bar',
                ),
                const SizedBox(height: 32),
                LogsChart(
                  title: 'Smell Logs',
                  stream: getLogsGroupedByMode(_selectedMode!, 'bau', 'good'),
                  color: Colors.orange,
                  mode: _selectedMode!,
                  chartType: 'bar',
                ),
                const SizedBox(height: 32),
                LogsChart(
                  title: 'Soap Logs',
                  stream: getLogsGroupedByMode(_selectedMode!, 'sabun', 'good'),
                  color: Colors.purple,
                  mode: _selectedMode!,
                  chartType: 'bar',
                ),
                LogsChart(
                  title: 'Visitor Count',
                  stream: getLogsGroupedByMode(
                    _selectedMode!,
                    'pengunjung',
                    null,
                  ),
                  color: Colors.red,
                  mode: _selectedMode!,
                  chartType: 'line',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required List<String> items,
    required String hint,
    String? value,
    required Function(String?) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label),
          const SizedBox(height: 4),
          DropdownButtonFormField<String?>(
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              hintText: hint,
              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            isExpanded: true,
            value: value,
            onChanged: (selectedValue) {
              if (selectedValue == 'none') {
                onChanged(null);
              } else {
                onChanged(selectedValue);
              }
            },
            items: [
              const DropdownMenuItem<String>(
                value: 'none',
                child: Text('None'),
              ),
              ...items.map((item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(
                    StringUtil.snakeToCapitalized(item),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }
}
