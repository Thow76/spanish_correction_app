import '../../../core/enums/language.dart';
import '../../corrections/application/correction_service.dart';
import '../../corrections/domain/correction_item.dart';
import '../../corrections/domain/error_category.dart';

/// The three outcome tiers for a re-translation in the Traducir frases game.
///
/// The tier is decided from two facts: (1) was the saved target error fixed,
/// and (2) is the REST of the sentence clean (no other substantive errors)?
///
/// - [excelente] — the saved error's category is fixed AND no other substantive
///   error exists anywhere in the attempt (the whole sentence is clean).
/// - [bienHecho] — the saved error's category is fixed BUT other substantive
///   errors exist elsewhere in the attempt.
/// - [siguePracticando] — the saved error's category is still present (the
///   target error was not fixed), regardless of the rest of the sentence.
///
/// A saved error is single-category by construction (errors are saved one at a
/// time by tapping a span), so whether the TARGET error was fixed is judged
/// only against that one category. Errors the grader finds in other categories
/// are still returned in [RetranslationGrade.corrections] (the walkthrough
/// service needs the full list).
enum RetranslationTier {
  /// Target error fixed AND the rest of the sentence is clean.
  excelente,

  /// Target error fixed BUT other substantive errors exist elsewhere.
  bienHecho,

  /// The saved error's category is still present in the re-translation.
  siguePracticando,
}

/// Result of grading a re-translation attempt against the saved error's
/// category.
class RetranslationGrade {
  const RetranslationGrade({
    required this.corrections,
    required this.categoryErrors,
    required this.judgedCategory,
    required this.tier,
  });

  /// Every correction the grader returned for the attempt, across all
  /// categories. Carried in full because the walkthrough service (a later
  /// chunk) consumes the whole corrections array, not just the judged category.
  final List<CorrectionItem> corrections;

  /// The subset of [corrections] whose category equals [judgedCategory]. These
  /// are the only errors that count toward the [tier].
  final List<CorrectionItem> categoryErrors;

  /// The single category the attempt was judged against — the category of the
  /// saved error the user is re-practising.
  final ErrorCategory judgedCategory;

  /// The outcome tier. Decided from [categoryErrors] (did the target error
  /// remain?) and, once the target is fixed, whether any other substantive
  /// error remains in [corrections] (distinguishing [RetranslationTier.excelente]
  /// from [RetranslationTier.bienHecho]).
  final RetranslationTier tier;

  /// Whether the target error was fixed — true for BOTH top tiers
  /// ([RetranslationTier.excelente] and [RetranslationTier.bienHecho]). This
  /// preserves the meaning the previous two-value `wellDone` had, so downstream
  /// consumers keep behaving identically.
  bool get isWellDone =>
      tier == RetranslationTier.excelente ||
      tier == RetranslationTier.bienHecho;

  /// Whether the target error is still present. Equivalent to the previous
  /// two-value `keepPracticing`, so the walkthrough triggers on the same
  /// condition as before.
  bool get isKeepPracticing => tier == RetranslationTier.siguePracticando;
}

/// Grades a user's re-translation in the Traducir frases practice game.
///
/// This is the first place the live correction grader runs on the re-translation
/// step. It produces BOTH the full corrections list (needed later by the
/// walkthrough service) and a category-filtered verdict + tier.
class GradeRetranslationUseCase {
  const GradeRetranslationUseCase({
    required CorrectionService correctionService,
  }) : _correctionService = correctionService;

  final CorrectionService _correctionService;

  /// Grades [attempt] in [language] and judges it against [savedErrorCategory].
  ///
  /// The full grade is preserved on the result. The tier is decided from two
  /// facts:
  ///
  /// - If the saved category is still present (substantive errors in
  ///   [savedErrorCategory] remain), the target error was not fixed →
  ///   [RetranslationTier.siguePracticando], regardless of the rest.
  /// - Otherwise the target error is fixed. If NO other substantive error
  ///   exists anywhere in the attempt, the whole sentence is clean →
  ///   [RetranslationTier.excelente]; if some other-category substantive error
  ///   remains → [RetranslationTier.bienHecho].
  Future<RetranslationGrade> call({
    required String attempt,
    required ErrorCategory savedErrorCategory,
    required Language language,
  }) async {
    final response = await _correctionService.correctText(
      attempt.trim(),
      language,
    );
    final corrections = response.corrections;

    final categoryErrors = corrections
        .where((correction) => correction.category == savedErrorCategory)
        .where(_isSubstantive)
        .toList(growable: false);

    final otherSubstantiveErrors = corrections
        .where((correction) => correction.category != savedErrorCategory)
        .where(_isSubstantive)
        .toList(growable: false);

    final tier = _tierFor(
      categoryErrors: categoryErrors,
      otherSubstantiveErrors: otherSubstantiveErrors,
    );

    return RetranslationGrade(
      corrections: corrections,
      categoryErrors: categoryErrors,
      judgedCategory: savedErrorCategory,
      tier: tier,
    );
  }

  /// Pure tier decision. The target error always dominates: if it remains the
  /// attempt is [RetranslationTier.siguePracticando] no matter how clean the
  /// rest is. Only once the target is fixed does the rest of the sentence
  /// distinguish [RetranslationTier.excelente] (nothing else substantive) from
  /// [RetranslationTier.bienHecho] (other substantive errors remain).
  static RetranslationTier _tierFor({
    required List<CorrectionItem> categoryErrors,
    required List<CorrectionItem> otherSubstantiveErrors,
  }) {
    if (categoryErrors.isNotEmpty) {
      return RetranslationTier.siguePracticando;
    }
    return otherSubstantiveErrors.isEmpty
        ? RetranslationTier.excelente
        : RetranslationTier.bienHecho;
  }

  /// Whether a correction represents a substantive error in its category.
  ///
  /// Live grading surfaced that the grader routinely inserts a missing
  /// sentence-final period as a `Grammar` correction (empty original_phrase →
  /// `"."`). Counting that as "the saved error is still present" would flip
  /// nearly every otherwise-clean attempt to KEEP PRACTICING, since attempts
  /// commonly omit final punctuation. A pure punctuation/whitespace insertion is
  /// therefore not treated as a substantive error for the tier. The correction
  /// is still kept in [RetranslationGrade.corrections] for the walkthrough.
  static bool _isSubstantive(CorrectionItem correction) {
    final originalIsEmpty = correction.originalPhrase.trim().isEmpty;
    final correctedCore = correction.correctedPhrase.replaceAll(
      _punctuationOrWhitespace,
      '',
    );
    final isPunctuationInsertion = originalIsEmpty && correctedCore.isEmpty;
    return !isPunctuationInsertion;
  }

  static final RegExp _punctuationOrWhitespace = RegExp(
    r'''[\s.,;:!?¡¿"'“”‘’…—–-]''',
  );
}
