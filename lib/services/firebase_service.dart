import 'package:firebase_database/firebase_database.dart';

import '../models/sensor_data_model.dart';

/// Handles Realtime Database sensor stream.
/// Path structure: sensors/{deviceId}/live
/// Multi-device ready — just pass different deviceId, no code change needed.
class FirebaseService {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  /// Default device id — swap when multi-device support goes live.
  static const String defaultDeviceId = 'device_01';

  /// Live stream of sensor readings for a given device.
  /// Usage: firebaseService.sensorStream().listen((data) { ... })
  Stream<SensorDataModel> sensorStream({String deviceId = defaultDeviceId}) {
    final ref = _db.child('sensors/$deviceId/live');

    return ref.onValue.map((event) {
      final raw = event.snapshot.value;
      if (raw is Map) {
        return SensorDataModel.fromMap(Map<String, dynamic>.from(raw));
      }
      // Fallback if node empty or malformed — avoid crashing the stream.
      return SensorDataModel.fromMap(const {});
    });
  }

  /// One-time read, useful for initial screen load before stream connects.
  Future<SensorDataModel> getLatestReading({
    String deviceId = defaultDeviceId,
  }) async {
    final snapshot = await _db.child('sensors/$deviceId/live').get();
    if (snapshot.exists && snapshot.value is Map) {
      return SensorDataModel.fromMap(
        Map<String, dynamic>.from(snapshot.value as Map),
      );
    }
    return SensorDataModel.fromMap(const {});
  }

  /// List all registered device ids — powers a device picker if/when
  /// multi-device support is turned on.
  Future<List<String>> listDeviceIds() async {
    final snapshot = await _db.child('sensors').get();
    if (snapshot.exists && snapshot.value is Map) {
      return (snapshot.value as Map).keys.map((k) => k.toString()).toList();
    }
    return [defaultDeviceId];
  }

  /// Check device online/connectivity flag, if ESP32 writes one
  /// (e.g. sensors/{deviceId}/status = 'online' | 'offline').
  Stream<String> deviceStatusStream({String deviceId = defaultDeviceId}) {
    final ref = _db.child('sensors/$deviceId/status');
    return ref.onValue.map((event) {
      final value = event.snapshot.value;
      return value?.toString() ?? 'unknown';
    });
  }
}