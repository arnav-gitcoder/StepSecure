import 'dart:math' as math;

import '../utils/date_time_helper.dart';

/// Result reported by the ESP32-S3 classifier.
///
/// [unknown] is the default for any missing or unrecognized value. The app
/// must never treat an unrecognized prediction as "normal".
enum FallPrediction { normal, warning, fall, unknown }

FallPrediction fallPredictionFromString(Object? value) {
  if (value is! String) return FallPrediction.unknown;
  switch (value.trim().toLowerCase()) {
    case 'normal':
      return FallPrediction.normal;
    case 'warning':
      return FallPrediction.warning;
    case 'fall':
    case 'fall_detected':
      return FallPrediction.fall;
    default:
      return FallPrediction.unknown;
  }
}

double? _toDouble(Object? value) {
  if (value is num) {
    final d = value.toDouble();
    return d.isFinite ? d : null;
  }
  if (value is String) {
    final d = double.tryParse(value.trim());
    return (d != null && d.isFinite) ? d : null;
  }
  return null;
}

String? _toText(Object? value) {
  if (value is! String) return null;
  final text = value.trim();
  return text.isEmpty ? null : text;
}

bool? _toBool(Object? value) {
  if (value is bool) return value;
  if (value is String) {
    final text = value.trim().toLowerCase();
    if (text == 'true') return true;
    if (text == 'false') return false;
  }
  return null;
}

/// One reading published by the wearable.
///
/// Every field is nullable on purpose: a missing value means "the device did
/// not publish it", which is different from 0. Screens should show "—" /
/// "No data" for null values, never 0.0.
class SensorDataModel {
  final double? accelX;
  final double? accelY;
  final double? accelZ;

  final double? gyroX;
  final double? gyroY;
  final double? gyroZ;

  /// Units exactly as published by the firmware (e.g. "g", "m/s²", "°/s").
  /// Null if the firmware doesn't say; don't guess in the UI.
  final String? accelUnit;
  final String? gyroUnit;

  final FallPrediction prediction;

  /// When the device says the reading was taken. Null if missing or not a
  /// plausible real-world time (e.g. a `millis()` uptime counter).
  final DateTime? timestamp;

  const SensorDataModel({
    this.accelX,
    this.accelY,
    this.accelZ,
    this.gyroX,
    this.gyroY,
    this.gyroZ,
    this.accelUnit,
    this.gyroUnit,
    this.prediction = FallPrediction.unknown,
    this.timestamp,
  });

  /// Never fabricates values: anything missing or malformed stays null.
  factory SensorDataModel.fromMap(Map<String, dynamic> map) {
    return SensorDataModel(
      accelX: _toDouble(map['accelX']),
      accelY: _toDouble(map['accelY']),
      accelZ: _toDouble(map['accelZ']),
      gyroX: _toDouble(map['gyroX']),
      gyroY: _toDouble(map['gyroY']),
      gyroZ: _toDouble(map['gyroZ']),
      accelUnit: _toText(map['accelUnit']),
      gyroUnit: _toText(map['gyroUnit']),
      prediction: fallPredictionFromString(map['prediction']),
      timestamp: DateTimeHelper.parse(map['timestamp']),
    );
  }

  bool get hasAccel => accelX != null && accelY != null && accelZ != null;
  bool get hasGyro => gyroX != null && gyroY != null && gyroZ != null;
  bool get hasMotionData => hasAccel || hasGyro;

  /// True when the node held nothing usable.
  bool get isEmpty =>
      !hasMotionData &&
      accelX == null &&
      accelY == null &&
      accelZ == null &&
      gyroX == null &&
      gyroY == null &&
      gyroZ == null &&
      prediction == FallPrediction.unknown &&
      timestamp == null;

  /// Vector magnitude of the real accelerometer values, or null if any axis
  /// is missing.
  double? get accelMagnitude {
    final x = accelX, y = accelY, z = accelZ;
    if (x == null || y == null || z == null) return null;
    return math.sqrt(x * x + y * y + z * z);
  }

  /// A reading with no timestamp is treated as stale: we can't show it as
  /// current.
  bool isStale({required Duration threshold, DateTime? now}) =>
      DateTimeHelper.isStale(timestamp, threshold: threshold, now: now);

  Map<String, dynamic> toMap() {
    return {
      if (accelX != null) 'accelX': accelX,
      if (accelY != null) 'accelY': accelY,
      if (accelZ != null) 'accelZ': accelZ,
      if (gyroX != null) 'gyroX': gyroX,
      if (gyroY != null) 'gyroY': gyroY,
      if (gyroZ != null) 'gyroZ': gyroZ,
      if (accelUnit != null) 'accelUnit': accelUnit,
      if (gyroUnit != null) 'gyroUnit': gyroUnit,
      'prediction': prediction.name,
      if (timestamp != null) 'timestamp': timestamp!.millisecondsSinceEpoch,
    };
  }
}

/// How the app should describe the wearable's connection.
///
/// * [connected]    – heartbeat is recent.
/// * [stale]        – no recent heartbeat, but the device never said it went
///                    offline ("No recent data").
/// * [disconnected] – the device (or its onDisconnect hook) reported offline.
/// * [unknown]      – nothing usable to decide from.
enum DeviceConnection { connected, stale, disconnected, unknown }

/// Device status as published at `sensors/{deviceId}/status`.
///
/// Accepts either a bare string ("online"/"offline") or a map:
/// `{ state, lastHeartbeat, monitoring, battery }`.
///
/// A bare "online" flag is never enough to show "Connected"; a recent
/// heartbeat timestamp is required.
class DeviceStatus {
  final String? reportedState;
  final DateTime? lastHeartbeat;
  final bool? monitoringActive;

  /// Only set if the firmware actually publishes a 0–100 battery value.
  final int? batteryPercent;

  const DeviceStatus({
    this.reportedState,
    this.lastHeartbeat,
    this.monitoringActive,
    this.batteryPercent,
  });

  static const DeviceStatus unknown = DeviceStatus();

  factory DeviceStatus.fromRaw(Object? raw) {
    if (raw is Map) {
      final map = Map<String, dynamic>.from(raw);
      final battery = map['battery'];
      return DeviceStatus(
        reportedState: _toText(map['state'] ?? map['status'])?.toLowerCase(),
        lastHeartbeat:
            DateTimeHelper.parse(map['lastHeartbeat'] ?? map['lastSeen']),
        monitoringActive: _toBool(map['monitoring']),
        batteryPercent: (battery is num && battery >= 0 && battery <= 100)
            ? battery.round()
            : null,
      );
    }
    if (raw is String) {
      return DeviceStatus(reportedState: _toText(raw)?.toLowerCase());
    }
    return unknown;
  }

  /// Decide connection state from timestamps, not from a stored flag.
  ///
  /// [now] should be server-adjusted time (see
  /// `FirebaseService.serverTimeOffsetStream`), because the phone's clock can
  /// be wrong. [staleAfter] should match the firmware heartbeat interval,
  /// with some slack (default assumes a heartbeat every ~10 s).
  DeviceConnection connectionAt(
    DateTime now, {
    Duration staleAfter = const Duration(seconds: 30),
  }) {
    final state = reportedState;
    if (state == 'offline' || state == 'disconnected') {
      return DeviceConnection.disconnected;
    }

    final beat = lastHeartbeat;
    if (beat == null) return DeviceConnection.unknown;

    // Negative age = small clock skew; treat as just received.
    final age = now.difference(beat);
    if (age > staleAfter) return DeviceConnection.stale;
    return DeviceConnection.connected;
  }
}