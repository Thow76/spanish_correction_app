import '../../../core/enums/language.dart';

class QueuedSubmission {
  const QueuedSubmission({
    required this.id,
    required this.text,
    required this.createdAt,
    required this.language,
  });

  final String id;
  final String text;
  final DateTime createdAt;
  final Language language;

  factory QueuedSubmission.fromJson(Map<String, Object?> json) {
    return QueuedSubmission(
      id: json['id'] as String? ?? '',
      text: json['text'] as String? ?? '',
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      language: Language.fromJson(json['language'] as String?),
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'text': text,
      'created_at': createdAt.toIso8601String(),
      'language': language.toJson(),
    };
  }
}
