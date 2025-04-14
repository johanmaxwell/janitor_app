import 'package:flutter/material.dart';

class GenderDropdown extends StatelessWidget {
  final String? selectedGender;
  final ValueChanged<String?> onChanged;
  final List<String> genderOption = const ['pria', 'wanita'];

  const GenderDropdown({
    super.key,
    required this.selectedGender,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.teal),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedGender,
          isExpanded: true,
          hint: Center(child: Text('Pilih Gender')),
          icon: const Icon(Icons.arrow_drop_down),
          items:
              genderOption.map((gender) {
                return DropdownMenuItem<String>(
                  value: gender,
                  child: Center(
                    child: Container(
                      width: double.infinity,
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.fromLTRB(0, 8.0, 0, 6.0),
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(
                            color:
                                genderOption.indexOf(gender) == 0
                                    ? Colors.transparent
                                    : Colors.grey,
                            width: 1,
                          ),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          gender[0].toUpperCase() + gender.substring(1),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
