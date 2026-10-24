import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/sensor_data_model.dart';
import '../utils/data_error_helper.dart';
import 'firebase_service.dart';

enum MonitorPhase { loading, noDevice, ready, error }

/// Everything the app knows about the caregiver's linked wearable, kept in
/// one place so Home and Live Monitor show the same facts.
///
/// * Owned by `MainNavigation`: created when the user is signed in and
///   disposed when that screen goes away (sign-out), so no listener outlives
///   the session.
/// * Only real data is exposed. Missing data stays null; nothing is invented.
/// * "Connected" is decided from timestamps, not from a stored flag. A timer
///   re-evaluates every few seconds, so a silent device turns stale even when
///   no new data arrives.
///
/// Today it follows the first device linked to the account. Multi-device
/// support would add a selector here.
class DeviceMonitor extends ChangeNotifier {
  DeviceMonitor({required this.uid, FirebaseService? service})
      : _service = service ?? FirebaseService() {
    _start();
  }

  /// How long without a heartbeat/reading before the device counts as
  /// "no recent data". Keep this a few times the firmware's heartbeat
  /// interval (the contract proposes 10 s).
  static const Duration staleAfter = Duration(seconds: 30);

  static const Duration _refreshEvery = Duration(seconds: 5);

  final String uid;
  final FirebaseService _service;

  MonitorPhase _phase = MonitorPhase.loading;
  String? _deviceId;
  SensorDataModel? _reading;
  DeviceStatus _status = DeviceStatus.unknown;
  Duration _serverOffset = Duration.zero;
  String? _errorMessage;
  String? _dataError;
  bool _disposed = false;

  Timer? _ticker;
  StreamSubscription<List<String>>? _devicesSub;
  StreamSubscription<SensorDataModel?>? _readingSub;
  StreamSubscription<DeviceStatus>? _statusSub;
  StreamSubscription<Duration>? _offsetSub;

  // ---------- Public state ----------

  MonitorPhase get phase => _phase;
  String? get deviceId => _deviceId;

  /// Latest live reading, or null if none was published. May be old: check
  /// [readingIsFresh] before showing values as current.
  SensorDataModel? get reading => _reading;

  DeviceStatus get status => _status;

  /// Set when [phase] is [MonitorPhase.error].
  String? get errorMessage => _errorMessage;

  /// Set when the device's own data couldn't be read (e.g. permissions).
  String? get dataError => _dataError;

  /// Firebase server time, so a wrong phone clock can't fake "connected".
  DateTime get serverNow => FirebaseService.serverNow(_serverOffset);

  /// Most recent sign of life: the later of the last heartbeat and the last
  /// sensor reading timestamp. Null if neither exists.
  DateTime? get lastCommunication {
    final beat = _status.lastHeartbeat;
    final read = _reading?.timestamp;
    if (beat == null) return read;
    if (read == null) return beat;
    return beat.isAfter(read) ? beat : read;
  }

  DeviceConnection get connection {
    return DeviceStatus(
      reportedState: _status.reportedState,
      lastHeartbeat: lastCommunication,
    ).connectionAt(serverNow, staleAfter: staleAfter);
  }

  bool get readingIsFresh {
    final r = _reading;
    return r != null && !r.isStale(threshold: staleAfter, now: serverNow);
  }

  // ---------- Lifecycle ----------

  void _start() {
    _ticker = Timer.periodic(_refreshEvery, (_) => _notify());

    // Server-time offset is a nicety; if it fails we fall back to the
    // phone's clock instead of failing the whole screen.
    _offsetSub = _service.serverTimeOffsetStream().listen(
      (offset) {
        _serverOffset = offset;
        _notify();
      },
      onError: (Object _) {},
    );

    _devicesSub = _service.userDeviceIdsStream(uid).listen(
      _onDevices,
      onError: _onDevicesError,
    );
  }

  void _onDevices(List<String> ids) {
    if (ids.isEmpty) {
      _detachDevice();
      _deviceId = null;
      _phase = MonitorPhase.noDevice;
      _errorMessage = null;
      _notify();
      return;
    }

    final current = _deviceId;
    final chosen = (current != null && ids.contains(current)) ? current : ids.first;
    if (chosen != current) {
      _attachDevice(chosen);
    }
    _phase = MonitorPhase.ready;
    _errorMessage = null;
    _notify();
  }

  void _onDevicesError(Object error) {
    _detachDevice();
    _deviceId = null;
    _phase = MonitorPhase.error;
    _errorMessage = DataErrorHelper.friendlyMessage(error);
    _notify();
  }

  void _attachDevice(String id) {
    _detachDevice();
    _deviceId = id;
    _dataError = null;

    _readingSub = _service.sensorStream(deviceId: id).listen(
      (reading) {
        _reading = reading;
        _dataError = null;
        _notify();
      },
      onError: (Object e) {
        _dataError = DataErrorHelper.friendlyMessage(e);
        _notify();
      },
    );

    _statusSub = _service.deviceStatusStream(deviceId: id).listen(
      (status) {
        _status = status;
        _notify();
      },
      onError: (Object e) {
        _dataError = DataErrorHelper.friendlyMessage(e);
        _notify();
      },
    );
  }

  void _detachDevice() {
    _readingSub?.cancel();
    _statusSub?.cancel();
    _readingSub = null;
    _statusSub = null;
    _reading = null;
    _status = DeviceStatus.unknown;
    _dataError = null;
  }

  /// Re-opens everything, e.g. from a "Try again" button.
  void retry() {
    if (_disposed) return;
    _cancelAll();
    _deviceId = null;
    _detachDevice();
    _phase = MonitorPhase.loading;
    _errorMessage = null;
    _start();
    _notify();
  }

  void _cancelAll() {
    _ticker?.cancel();
    _ticker = null;
    _devicesSub?.cancel();
    _offsetSub?.cancel();
    _devicesSub = null;
    _offsetSub = null;
    _readingSub?.cancel();
    _statusSub?.cancel();
    _readingSub = null;
    _statusSub = null;
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _cancelAll();
    super.dispose();
  }
}