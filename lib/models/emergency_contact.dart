import '../utils/date_time_helper.dart';

String? _text(Object? value) {
  if (value is! String) return null;
  final t = value.trim();
  return t.isEmpty ? null : t;
}

class EmergencyContact {
  final String id;
  final String name;

  /// As the user entered it. Use [phoneE164] when sending SMS: providers
  /// need the international format.
  final String phone;
  final String relation;

  /// Optional.
  final String? email;

  /// Lower number = contacted first. Ties are broken by name.
  final int priority;

  /// Set by the server on creation (null until the server confirms it).
  final DateTime? createdAt;

  const EmergencyContact({
    required this.id,
    required this.name,
    required this.phone,
    required this.relation,
    this.email,
    this.priority = 0,
    this.createdAt,
  });

  factory EmergencyContact.fromMap(Map<String, dynamic> map, {String? docId}) {
    final rawPriority = map['priority'];
    return EmergencyContact(
      id: docId ?? _text(map['id']) ?? '',
      name: _text(map['name']) ?? '',
      phone: _text(map['phone']) ?? '',
      relation: _text(map['relation']) ?? '',
      email: _text(map['email']),
      priority: rawPriority is num ? rawPriority.toInt() : 0,
      createdAt: DateTimeHelper.parse(map['createdAt']),
    );
  }

  /// Fields the user edits. `createdAt` is deliberately excluded: the
  /// service sets it with a server timestamp on creation only.
  Map<String, dynamic> toMap() {
    final mail = email?.trim();
    return {
      'name': name.trim(),
      'phone': phone.trim(),
      'relation': relation.trim(),
      if (mail != null && mail.isNotEmpty) 'email': mail,
      'priority': priority,
    };
  }

  /// [phone] in E.164 form ("+919876543210"), or null if it can't be
  /// normalized without a country code.
  String? get phoneE164 => normalizePhone(phone);

  EmergencyContact copyWith({
    String? id,
    String? name,
    String? phone,
    String? relation,
    String? email,
    int? priority,
    DateTime? createdAt,
  }) {
    return EmergencyContact(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      relation: relation ?? this.relation,
      email: email ?? this.email,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Converts user input to E.164 ("+" and 8–15 digits), or returns null if
  /// it isn't a valid number.
  ///
  /// * "+91 98765 43210"  -> "+919876543210"
  /// * "0091 98765 43210" -> "+919876543210"
  /// * "098765 43210"     -> needs [defaultCountryCode] (e.g. "+91"),
  ///   otherwise null. We don't guess a country.
  static String? normalizePhone(String raw, {String? defaultCountryCode}) {
    final text = raw.trim();
    if (text.isEmpty) return null;

    final hasPlus = text.startsWith('+');
    var digits = text.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return null;

    if (!hasPlus) {
      if (digits.startsWith('00')) {
        // International call prefix, e.g. 0091...
        digits = digits.substring(2);
      } else {
        final cc = defaultCountryCode?.replaceAll(RegExp(r'\D'), '');
        if (cc == null || cc.isEmpty) return null;
        // Drop a national trunk prefix (leading zeros) before adding the code.
        digits = '$cc${digits.replaceFirst(RegExp(r'^0+'), '')}';
      }
    }

    if (!RegExp(r'^[1-9]\d{7,14}$').hasMatch(digits)) return null;
    return '+$digits';
  }

  static bool isValidPhone(String raw, {String? defaultCountryCode}) =>
      normalizePhone(raw, defaultCountryCode: defaultCountryCode) != null;
}