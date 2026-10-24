import 'package:cloud_firestore/cloud_firestore.dart';

/// Timestamp parsing and formatting helpers.
///
/// Rules:
/// * Never invent a time. If a value can't be parsed (or isn't plausible),
///   [parse] returns null and the UI shows "Unknown time".
/// * Accepts Firestore [Timestamp], [DateTime], epoch seconds, epoch
///   milliseconds (what RTDB `ServerValue.timestamp` and most firmware
///   write), numeric strings and ISO-8601 strings.
class DateTimeHelper {
  DateTimeHelper._();

  /// Anything earlier is treated as "not a real time". This catches ESP32
  /// `millis()` uptime values (e.g. 123456), which look like 1970 dates.
  static final DateTime _earliestPlausible = DateTime.utc(2020, 1, 1);

  /// Allowed clock skew into the future before a value is rejected.
  static const Duration _maxFutureSkew = Duration(days: 1);

  /// Dart's DateTime range limit in milliseconds.
  static const int _maxMillis = 8640000000000000;

  static DateTime? parse(dynamic value, {DateTime? now}) {
    final DateTime? parsed = _parseRaw(value);
    if (parsed == null) return null;

    final utc = parsed.toUtc();
    final reference = (now ?? DateTime.now()).toUtc();

    if (utc.isBefore(_earliestPlausible)) return null;
    if (utc.isAfter(reference.add(_maxFutureSkew))) return null;

    return parsed.toLocal();
  }

  static DateTime? _parseRaw(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;

    if (value is num) {
      if (!value.isFinite) return null;
      final n = value.toInt();
      // Below 1e11 it must be epoch seconds (1e11 s is year ~5138);
      // otherwise treat as milliseconds.
      final millis = n.abs() < 100000000000 ? n * 1000 : n;
      if (millis.abs() > _maxMillis) return null;
      return DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true);
    }

    if (value is String) {
      final text = value.trim();
      if (text.isEmpty) return null;
      final asInt = int.tryParse(text);
      if (asInt != null) return _parseRaw(asInt);
      return DateTime.tryParse(text);
    }

    return null;
  }

  /// True when [time] is missing or older than [threshold].
  /// A missing time counts as stale: we don't know when data last arrived.
  static bool isStale(
    DateTime? time, {
    required Duration threshold,
    DateTime? now,
  }) {
    if (time == null) return true;
    final reference = now ?? DateTime.now();
    return reference.difference(time) > threshold;
  }

  /// "Just now", "5 min ago", "3 hr ago", "2 days ago", or a full date.
  static String timeAgo(DateTime? time, {DateTime? now}) {
    if (time == null) return 'Unknown time';

    final reference = now ?? DateTime.now();
    final diff = reference.difference(time);

    // Negative = small clock skew between phone and server.
    if (diff.isNegative || diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hr ago';
    if (diff.inDays < 7) {
      final d = diff.inDays;
      return '$d ${d == 1 ? 'day' : 'days'} ago';
    }
    return formatDateTime(time);
  }

  static const List<String> _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  /// e.g. "24 Oct 2026, 12:19" in the device's local time.
  static String formatDateTime(DateTime? time) {
    if (time == null) return 'Unknown time';
    final t = time.toLocal();
    final hh = t.hour.toString().padLeft(2, '0');
    final mm = t.minute.toString().padLeft(2, '0');
    return '${t.day} ${_months[t.month - 1]} ${t.year}, $hh:$mm';
  }
}