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
/// NOTE: [bienHecho] is not yet emitted — the "rest of the sentence" check that
/// distinguishes it from [excelente] is wired in a following step. For now the
/// grader produces only [excelente] (target fixed) or [siguePracticando]
/// (target not fixed), preserving the previous two-outcome behaviour.
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
  ///
  /// Not yet emitted; reserved for the rest-of-sentence check added next.
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

  /// The outcome tier. Currently derived solely from [categoryErrors]; the
  /// rest-of-sentence check that distinguishes [RetranslationTier.excelente]
  /// from [RetranslationTier.bienHecho] is added in a following step.
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
  /// The full grade is preserved on the result. For now only corrections
  /// matching [savedErrorCategory] decide the tier: if the saved category is
  /// absent from the re-translation the attempt is [RetranslationTier.excelente];
  /// if it is still present, [RetranslationTier.siguePracticando].
  /// ([RetranslationTier.bienHecho] is not yet emitted — the rest-of-sentence
  /// check is added in a following step.)
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

    final tier = categoryErrors.isEmpty
        ? RetranslationTier.excelente
        : RetranslationTier.siguePracticando;

    return RetranslationGrade(
      corrections: corrections,
      categoryErrors: categoryErrors,
      judgedCategory: savedErrorCategory,
      tier: tier,
    );
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
