import '../../../core/enums/language.dart';
import '../../corrections/application/correction_service.dart';
import '../../corrections/domain/correction_item.dart';
import '../../corrections/domain/error_category.dart';

/// The two outcome tiers for a re-translation in the Traducir frases game.
///
/// The judgment is deliberately narrow: a saved error is single-category by
/// construction (errors are saved one at a time by tapping a span), so the
/// re-translation is judged ONLY against that one category. Errors the grader
/// finds in other categories are still returned in [RetranslationGrade.corrections]
/// (the walkthrough service needs the full list), but they do NOT influence the
/// tier.
enum RetranslationTier {
  /// The saved error's category is no longer present in the re-translation.
  wellDone,

  /// The saved error's category is still present in the re-translation.
  keepPracticing,
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

  /// well done vs. KEEP PRACTICING, derived solely from [categoryErrors].
  final RetranslationTier tier;

  bool get isWellDone => tier == RetranslationTier.wellDone;

  bool get isKeepPracticing => tier == RetranslationTier.keepPracticing;
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
  /// The full grade is preserved on the result; only corrections matching
  /// [savedErrorCategory] decide the tier. If the saved category is absent from
  /// the re-translation the attempt is [RetranslationTier.wellDone]; if it is
  /// still present, [RetranslationTier.keepPracticing].
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
        ? RetranslationTier.wellDone
        : RetranslationTier.keepPracticing;

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
