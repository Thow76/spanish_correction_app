import '../../../core/enums/language.dart';
import '../../corrections/domain/correction_response.dart';

class CorrectionSubmission {
  const CorrectionSubmission({
    required this.id,
    required this.response,
    required this.createdAt,
    required this.language,
  });

  final String id;
  final CorrectionResponse response;
  final DateTime createdAt;
  final Language language;

  CorrectionSubmission copyWith({
    String? id,
    CorrectionResponse? response,
    DateTime? createdAt,
    Language? language,
  }) {
    return CorrectionSubmission(
      id: id ?? this.id,
      response: response ?? this.response,
      createdAt: createdAt ?? this.createdAt,
      language: language ?? this.language,
    );
  }

  factory CorrectionSubmission.fromJson(Map<String, Object?> json) {
    final rawResponse = json['response'];

    return CorrectionSubmission(
      id: json['id'] as String? ?? '',
      response: rawResponse is Map<String, Object?>
          ? CorrectionResponse.fromJson(rawResponse)
          : const CorrectionResponse(
              originalText: '',
              correctedText: '',
              corrections: [],
            ),
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      language: Language.fromJson(json['language'] as String?),
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'response': response.toJson(),
      'created_at': createdAt.toIso8601String(),
      'language': language.toJson(),
    };
  }
}
