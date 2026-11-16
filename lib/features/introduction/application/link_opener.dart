/// Opens a web address outside the app, for "Open now" on the
/// recommendation card (decision A3). Behind an interface so the
/// introduction can be tested without a phone.
abstract interface class LinkOpener {
  /// Opens [url] in the phone's browser or the app that handles it. Returns
  /// false when nothing could open it.
  Future<bool> open(Uri url);
}
