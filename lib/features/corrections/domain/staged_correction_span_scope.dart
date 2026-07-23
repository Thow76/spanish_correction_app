/// Stage 2's judgment of how much of a Natural Language correction's quoted
/// phrase must stay highlighted — see `stage2CategorizationSpanish` in
/// `correction_prompt.dart`. Null (not requested/returned) for every
/// category other than Natural Language.
///
/// Parsed and stored only — nothing in the pipeline consults this yet to
/// adjust a span.
enum StagedCorrectionSpanScope {
  /// Only the words that actually change should stay highlighted; the rest
  /// of the quoted phrase is unchanged context that stands fine on its own.
  exact('exact'),

  /// The entire quoted phrase must stay highlighted — no smaller piece of
  /// it makes sense on its own (a fixed collocation, or a clause where
  /// grammatical roles are reassigned across the whole span).
  full('full');

  const StagedCorrectionSpanScope(this.apiValue);

  /// The exact string Stage 2 returns for this span scope.
  final String apiValue;

  /// Looks up the span scope matching Stage 2's raw `span_scope` string, or
  /// null if it doesn't match either known value.
  static StagedCorrectionSpanScope? fromApiValue(String value) {
    for (final scope in StagedCorrectionSpanScope.values) {
      if (scope.apiValue == value) {
        return scope;
      }
    }
    return null;
  }
}
