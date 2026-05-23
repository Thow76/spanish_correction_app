class QueuedSubmission {
  const QueuedSubmission({
    required this.id,
    required this.text,
    required this.createdAt,
  });

  final String id;
  final String text;
  final DateTime createdAt;

  factory QueuedSubmission.fromJson(Map<String, Object?> json) {
    return QueuedSubmission(
      id: json['id'] as String? ?? '',
      text: json['text'] as String? ?? '',
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  Map<String, Object?> toJson() {
    return {'id': id, 'text': text, 'created_at': createdAt.toIso8601String()};
  }
}
