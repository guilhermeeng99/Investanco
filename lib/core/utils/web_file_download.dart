/// Triggers a browser download of [url] as [fileName]. Web-only — the stub
/// throws on other platforms (callers gate on `kIsWeb`). The web implementation
/// is swapped in via a conditional import. Mirrors financo's util.
void triggerBrowserUrlDownload(String url, String fileName) {
  throw UnsupportedError(
    'triggerBrowserUrlDownload is only supported on Flutter Web.',
  );
}
