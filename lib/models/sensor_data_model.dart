class SensorDataModel {
  final double accelX;
  final double accelY;
  final double accelZ;

  final double gyroX;
  final double gyroY;
  final double gyroZ;

  final String prediction;

  SensorDataModel({
    required this.accelX,
    required this.accelY,
    required this.accelZ,
    required this.gyroX,
    required this.gyroY,
    required this.gyroZ,
    required this.prediction,
  });

  factory SensorDataModel.fromMap(Map<String, dynamic> map) {
    return SensorDataModel(
      accelX: (map['accelX'] ?? 0).toDouble(),
      accelY: (map['accelY'] ?? 0).toDouble(),
      accelZ: (map['accelZ'] ?? 0).toDouble(),
      gyroX: (map['gyroX'] ?? 0).toDouble(),
      gyroY: (map['gyroY'] ?? 0).toDouble(),
      gyroZ: (map['gyroZ'] ?? 0).toDouble(),
      prediction: map['prediction'] ?? 'Normal',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'accelX': accelX,
      'accelY': accelY,
      'accelZ': accelZ,
      'gyroX': gyroX,
      'gyroY': gyroY,
      'gyroZ': gyroZ,
      'prediction': prediction,
    };
  }
}