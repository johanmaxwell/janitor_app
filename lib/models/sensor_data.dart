class SensorData {
  final String gedung;
  final String lokasi;
  final String gender;
  final String number;
  final String status;
  final String? amount;

  SensorData({
    required this.gedung,
    required this.lokasi,
    required this.gender,
    required this.number,
    required this.status,
    this.amount,
  });

  factory SensorData.fromFirestore(Map<String, dynamic> json) {
    return SensorData(
      gedung: json['gedung'],
      lokasi: json['lokasi'],
      gender: json['gender'],
      number: json['nomor'],
      status: json['status'],
      amount: json['amount'],
    );
  }

  factory SensorData.fromFirestoreWithoutAmount(Map<String, dynamic> json) {
    return SensorData(
      gedung: json['gedung'],
      lokasi: json['lokasi'],
      gender: json['gender'],
      number: json['nomor'],
      status: json['status'],
    );
  }
}
