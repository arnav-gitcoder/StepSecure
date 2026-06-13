class AlertModel {
  final String id;
  final String title;
  final String description;
  final String status;
  final String timestamp;

  AlertModel({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.timestamp,
  });

  factory AlertModel.fromMap(Map<String, dynamic> map) {
    return AlertModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      status: map['status'] ?? '',
      timestamp: map['timestamp'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'status': status,
      'timestamp': timestamp,
    };
  }
}