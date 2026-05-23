import '../../corrections/domain/correction_response.dart';

class CorrectionSubmission {
  const CorrectionSubmission({
    required this.id,
    required this.response,
    required this.createdAt,
  });

  final String id;
  final CorrectionResponse response;
  final DateTime createdAt;

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
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'response': response.toJson(),
      'created_at': createdAt.toIso8601String(),
    };
  }
}
