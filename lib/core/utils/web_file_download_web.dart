import 'package:web/web.dart' as web;

/// Web implementation: clicks a hidden `<a download>` pointing at [url] so the
/// browser downloads it as [fileName]. Mirrors financo's util.
void triggerBrowserUrlDownload(String url, String fileName) {
  final anchor = web.HTMLAnchorElement()
    ..href = url
    ..download = fileName
    ..style.display = 'none';
  web.document.body!.append(anchor);
  anchor
    ..click()
    ..remove();
}
