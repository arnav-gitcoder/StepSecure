import 'package:cloud_firestore/cloud_firestore.dart';

import '../utils/date_time_helper.dart';

/// Acknowledgement state of an alert. Unrecognized values fall back to
/// [pending] so an alert never silently looks "handled".
enum AlertStatus { pending, acknowledged, resolved }

AlertStatus alertStatusFromString(Object? value) {
  if (value is! String) return AlertStatus.pending;
  switch (value.trim().toLowerCase()) {
    case 'acknowledged':
      return AlertStatus.acknowledged;
    case 'resolved':
      return AlertStatus.resolved;
    default: // 'pending', 'unacknowledged', anything unexpected
      return AlertStatus.pending;
  }
}

/// Push/SMS/email notification state, tracked separately from detection.
/// Only the backend that actually sent the message should set [sent].
/// [unknown] = the field is missing, so the app must not claim anything.
enum NotificationStatus { notSent, pending, sent, failed, unknown }

/// Emergency escalation (contacting emergency contacts) state.
enum EscalationStatus { none, pending, contactsNotified, failed, unknown }

String _normalizeKey(String s) =>
    s.trim().toLowerCase().replaceAll(RegExp(r'[_\-\s]'), '');

/// Matches "not_sent", "notSent", "NOT-SENT" etc. against enum names.
T _enumFromName<T extends Enum>(List<T> values, Object? raw, T fallback) {
  if (raw is! String) return fallback;
  final key = _normalizeKey(raw);
  for (final v in values) {
    if (_normalizeKey(v.name) == key) return v;
  }
  return fallback;
}

String? _text(Object? value) {
  if (value is! String) return null;
  final t = value.trim();
  return t.isEmpty ? null : t;
}

class AlertModel {
  /// Firestore document id. Convention: the backend uses the unique event id
  /// as the document id, so retries and reconnects can't create duplicates.
  final String id;
  final String title;
  final String description;
  final AlertStatus status;

  /// Null if the backend didn't write a usable time. UI shows "Unknown time".
  final DateTime? timestamp;

  final String? deviceId;
  final String? eventType;
  final NotificationStatus notificationStatus;
  final EscalationStatus escalationStatus;
  final DateTime? acknowledgedAt;

  const AlertModel({
    required this.id,
    this.title = '',
    this.description = '',
    this.status = AlertStatus.pending,
    this.timestamp,
    this.deviceId,
    this.eventType,
    this.notificationStatus = NotificationStatus.unknown,
    this.escalationStatus = EscalationStatus.unknown,
    this.acknowledgedAt,
  });

  /// Tolerant of missing/odd fields and of timestamps stored as Firestore
  /// Timestamp, epoch ints or ISO strings. It never throws on bad data.
  factory AlertModel.fromMap(Map<String, dynamic> map, {String? docId}) {
    return AlertModel(
      id: docId ?? _text(map['id']) ?? '',
      title: _text(map['title']) ?? '',
      description: _text(map['description']) ?? '',
      status: alertStatusFromString(map['status']),
      timestamp: DateTimeHelper.parse(map['timestamp']),
      deviceId: _text(map['deviceId']),
      eventType: _text(map['eventType']),
      notificationStatus: _enumFromName(
        NotificationStatus.values,
        map['notificationStatus'],
        NotificationStatus.unknown,
      ),
      escalationStatus: _enumFromName(
        EscalationStatus.values,
        map['escalationStatus'],
        EscalationStatus.unknown,
      ),
      acknowledgedAt: DateTimeHelper.parse(map['acknowledgedAt']),
    );
  }

  /// Title to show: the stored title, else one derived from [eventType].
  String get displayTitle {
    if (title.isNotEmpty) return title;
    switch ((eventType ?? '').toLowerCase()) {
      case 'fall_detected':
      case 'fall':
        return 'Fall detected';
      default:
        return 'Alert';
    }
  }

  /// True until the user acknowledges (or it's resolved).
  bool get needsAttention => status == AlertStatus.pending;
  bool get isAcknowledged => status != AlertStatus.pending;

  /// Used only by the legacy client-side write path. Timestamps are written
  /// as Firestore Timestamps (mixing strings and Timestamps in one field
  /// breaks `orderBy`, because Firestore sorts by type first).
  Map<String, dynamic> toMap() {
    final ts = timestamp;
    final ackTs = acknowledgedAt;
    return {
      'id': id,
      'title': title,
      'description': description,
      'status': status.name,
      if (ts != null) 'timestamp': Timestamp.fromDate(ts),
      if (deviceId != null) 'deviceId': deviceId,
      if (eventType != null) 'eventType': eventType,
      if (notificationStatus != NotificationStatus.unknown)
        'notificationStatus': notificationStatus.name,
      if (escalationStatus != EscalationStatus.unknown)
        'escalationStatus': escalationStatus.name,
      if (ackTs != null) 'acknowledgedAt': Timestamp.fromDate(ackTs),
    };
  }

  AlertModel copyWith({
    String? id,
    String? title,
    String? description,
    AlertStatus? status,
    DateTime? timestamp,
    String? deviceId,
    String? eventType,
    NotificationStatus? notificationStatus,
    EscalationStatus? escalationStatus,
    DateTime? acknowledgedAt,
  }) {
    return AlertModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
      deviceId: deviceId ?? this.deviceId,
      eventType: eventType ?? this.eventType,
      notificationStatus: notificationStatus ?? this.notificationStatus,
      escalationStatus: escalationStatus ?? this.escalationStatus,
      acknowledgedAt: acknowledgedAt ?? this.acknowledgedAt,
    );
  }
}