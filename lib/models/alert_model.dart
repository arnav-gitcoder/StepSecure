enum AlertStatus { pending, acknowledged, resolved }

AlertStatus alertStatusFromString(String value) {
  return AlertStatus.values.firstWhere(
    (e) => e.name == value,
    orElse: () => AlertStatus.pending,
  );
}

class AlertModel {
  final String id;
  final String title;
  final String description;
  final AlertStatus status;
  final DateTime timestamp;

  AlertModel({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.timestamp,
  });

  factory AlertModel.fromMap(Map<String, dynamic> map, {String? docId}) {
    return AlertModel(
      id: docId ?? map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      status: alertStatusFromString(map['status'] ?? 'pending'),
      timestamp: DateTime.tryParse(map['timestamp'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'status': status.name,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  AlertModel copyWith({
    String? id,
    String? title,
    String? description,
    AlertStatus? status,
    DateTime? timestamp,
  }) {
    return AlertModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}