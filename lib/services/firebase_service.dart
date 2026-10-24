import 'package:firebase_database/firebase_database.dart';

import '../models/sensor_data_model.dart';

/// Realtime Database access for the wearable.
///
/// Paths (proposed contract, see hardware_data_contract.md):
///
///   userDevices/{uid}/{deviceId}   -> device ownership (written by the
///                                     backend pairing flow, NOT by the app)
///   sensors/{deviceId}/live        -> latest reading  (SensorDataModel)
///   sensors/{deviceId}/status      -> DeviceStatus: { state, lastHeartbeat,
///                                     monitoring, battery }
///
/// There is no default device id: which devices a user sees comes from
/// `userDevices/{uid}`, so every account gets its own devices.
///
/// The database connection is created lazily and every stream is guarded.
/// If the database doesn't exist yet (or its URL isn't configured), the
/// streams emit an error instead of crashing the app, and the UI shows a
/// "wearable status unavailable" state.
///
/// Streams do NOT swallow errors: a permission-denied or network error is
/// delivered to the listener's `onError` / `StreamBuilder.hasError` (see
/// `DataErrorHelper.friendlyMessage`). Always pass `onError` to `.listen()`.
class FirebaseService {
  FirebaseService({FirebaseDatabase? database}) : _database = database;

  final FirebaseDatabase? _database;
  DatabaseReference? _root;

  /// Created on first use, so constructing the service can never throw.
  DatabaseReference get _db =>
      _root ??= (_database ?? FirebaseDatabase.instance).ref();

  static final RegExp _safeKey = RegExp(r'^[A-Za-z0-9_\-]+$');

  /// Guards against empty ids and path tricks (`/`, `.`, `#`, `$`, `[`, `]`).
  String _checkKey(String value, String name) {
    if (!_safeKey.hasMatch(value)) {
      throw ArgumentError.value(value, name, 'is not a valid id');
    }
    return value;
  }

  /// Turns a synchronous failure while opening a stream (bad id, missing
  /// database) into an error event on that stream.
  Stream<T> _guard<T>(Stream<T> Function() open) {
    try {
      return open();
    } catch (e) {
      return Stream<T>.error(e);
    }
  }

  // ---------- DEVICE OWNERSHIP ----------

  /// Ids of the devices that belong to [uid], live. Empty list = the user
  /// has no linked device (show the "no wearable linked" empty state).
  Stream<List<String>> userDeviceIdsStream(String uid) {
    return _guard(() {
      _checkKey(uid, 'uid');
      return _db.child('userDevices/$uid').onValue.map((event) {
        final raw = event.snapshot.value;
        if (raw is Map) {
          return raw.keys.map((k) => k.toString()).toList()..sort();
        }
        return <String>[];
      });
    });
  }

  /// One-time read of [uid]'s device ids. Only reads that user's node, never
  /// the whole `sensors` tree.
  Future<List<String>> listUserDeviceIds(String uid) async {
    _checkKey(uid, 'uid');
    final snapshot = await _db.child('userDevices/$uid').get();
    final raw = snapshot.value;
    if (snapshot.exists && raw is Map) {
      return raw.keys.map((k) => k.toString()).toList()..sort();
    }
    return <String>[];
  }

  // ---------- LIVE DATA ----------

  /// Live readings for [deviceId]. Emits `null` when the node is empty or
  /// malformed. Null means "no data", never a fake all-zero reading.
  Stream<SensorDataModel?> sensorStream({required String deviceId}) {
    return _guard(() {
      _checkKey(deviceId, 'deviceId');
      return _db.child('sensors/$deviceId/live').onValue.map((event) {
        return _parseReading(event.snapshot.value);
      });
    });
  }

  /// One-time read for the initial screen load. Null = no data.
  Future<SensorDataModel?> getLatestReading({
    required String deviceId,
  }) async {
    _checkKey(deviceId, 'deviceId');
    final snapshot = await _db.child('sensors/$deviceId/live').get();
    return _parseReading(snapshot.value);
  }

  SensorDataModel? _parseReading(Object? raw) {
    if (raw is! Map) return null;
    final reading = SensorDataModel.fromMap(Map<String, dynamic>.from(raw));
    return reading.isEmpty ? null : reading;
  }

  // ---------- DEVICE STATUS ----------

  /// Live device status. Use [DeviceStatus.connectionAt] with server-adjusted
  /// time to decide connected / stale / disconnected. Don't trust a stored
  /// "online" flag on its own.
  Stream<DeviceStatus> deviceStatusStream({required String deviceId}) {
    return _guard(() {
      _checkKey(deviceId, 'deviceId');
      return _db.child('sensors/$deviceId/status').onValue.map(
            (event) => DeviceStatus.fromRaw(event.snapshot.value),
          );
    });
  }

  // ---------- SERVER TIME ----------

  /// Difference between the Firebase server clock and this phone's clock.
  /// Add it to `DateTime.now()` (see [serverNow]) before comparing against
  /// device heartbeats, because the phone's clock can be wrong.
  Stream<Duration> serverTimeOffsetStream() {
    return _guard(() {
      return _db.child('.info/serverTimeOffset').onValue.map((event) {
        final value = event.snapshot.value;
        return value is num
            ? Duration(milliseconds: value.toInt())
            : Duration.zero;
      });
    });
  }

  static DateTime serverNow(Duration offset) => DateTime.now().add(offset);
}