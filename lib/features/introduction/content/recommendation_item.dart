import '../../../core/enums/language.dart';

/// What kind of thing a recommendation points at.
enum RecommendationType {
  /// Something to read: an article or a web page.
  article,

  /// Something to watch.
  video,

  /// Anything else: a podcast, a site, an audio piece.
  other,
}

/// One recommendation linked to an interest: the "A recommendation" step of
/// "Try it" (decision A3), shown as a card as it will be in the app.
///
/// The card shows [title], [thumbnailUrl] where there is one, and where the
/// item comes from ([source]), with two buttons, Open now and Skip. Open now
/// opens [url] outside the app. The card links to the item and never copies
/// its content (the conclusion of the YouTube licensing chat, 1 Nov 2026).
///
/// Links can break and some video sites lock clips to a region, so the items
/// need checking now and then (decision A3). The placeholder items point at
/// stable public pages that open from the UK.
class RecommendationItem {
  const RecommendationItem({
    required this.id,
    required this.interestId,
    required this.language,
    required this.title,
    required this.url,
    required this.source,
    required this.type,
    this.thumbnailUrl,
  });

  final String id;
  final String interestId;
  final Language language;

  /// The title shown on the card, in the target language.
  final String title;

  /// Where Open now goes. Always an https address.
  final String url;

  /// A small picture for the card, or null when there is none to show.
  final String? thumbnailUrl;

  /// Who publishes the item, shown under the title (for example a newspaper
  /// or a broadcaster).
  final String source;
  final RecommendationType type;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is RecommendationItem && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'RecommendationItem($id)';
}
