import 'package:url_launcher/url_launcher.dart';

import '../application/link_opener.dart';

/// Opens links in the phone's browser (or the app that handles them, such as
/// YouTube), outside Corregir.
class UrlLauncherLinkOpener implements LinkOpener {
  const UrlLauncherLinkOpener();

  @override
  Future<bool> open(Uri url) async {
    try {
      return await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }
}
