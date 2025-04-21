class SensorData {
  final String lokasi;
  final String number;
  final String status;
  final String? amount;

  SensorData({
    required this.lokasi,
    required this.number,
    required this.status,
    this.amount,
  });

  factory SensorData.fromFirestore(Map<String, dynamic> json) {
    return SensorData(
      lokasi: json['lokasi'],
      number: json['nomor'],
      status: json['status'],
      amount: json['amount'],
    );
  }

  factory SensorData.fromFirestoreWithoutAmount(Map<String, dynamic> json) {
    return SensorData(
      lokasi: json['lokasi'],
      number: json['nomor'],
      status: json['status'],
    );
  }
}
