enum FallPrediction { normal, warning, fall }

FallPrediction fallPredictionFromString(String value) {
  return FallPrediction.values.firstWhere(
    (e) => e.name.toLowerCase() == value.toLowerCase(),
    orElse: () => FallPrediction.normal,
  );
}

class SensorDataModel {
  final double accelX;
  final double accelY;
  final double accelZ;

  final double gyroX;
  final double gyroY;
  final double gyroZ;

  final FallPrediction prediction;
  final DateTime timestamp;

  SensorDataModel({
    required this.accelX,
    required this.accelY,
    required this.accelZ,
    required this.gyroX,
    required this.gyroY,
    required this.gyroZ,
    required this.prediction,
    required this.timestamp,
  });

  factory SensorDataModel.fromMap(Map<String, dynamic> map) {
    return SensorDataModel(
      accelX: (map['accelX'] ?? 0).toDouble(),
      accelY: (map['accelY'] ?? 0).toDouble(),
      accelZ: (map['accelZ'] ?? 0).toDouble(),
      gyroX: (map['gyroX'] ?? 0).toDouble(),
      gyroY: (map['gyroY'] ?? 0).toDouble(),
      gyroZ: (map['gyroZ'] ?? 0).toDouble(),
      prediction: fallPredictionFromString(map['prediction'] ?? 'normal'),
      timestamp: map['timestamp'] != null
          ? DateTime.tryParse(map['timestamp']) ?? DateTime.now()
          : DateTime.now(),
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
      'prediction': prediction.name,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}