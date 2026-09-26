import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Extracts an 11-character YouTube video id from any common URL shape
/// (watch?v=, youtu.be/, embed/). Returns null if none is found.
String? extractYoutubeId(String url) {
  for (final pattern in [
    RegExp(r'(?:v=|/)([a-zA-Z0-9_-]{11})(?:$|[?&])'),
    RegExp(r'youtu\.be/([a-zA-Z0-9_-]{11})'),
  ]) {
    final match = pattern.firstMatch(url);
    if (match != null) return match.group(1);
  }
  return null;
}

/// Plays a YouTube video as a silent, looping, chrome-free background
/// clip: autoplay, muted, no controls, no related videos, minimal
/// branding, and not tappable — purely ambient, like a video banner.
class YoutubeBackgroundPlayer extends StatefulWidget {
  const YoutubeBackgroundPlayer({super.key, required this.videoId});
  final String videoId;
  @override
  State<YoutubeBackgroundPlayer> createState() =>
      _YoutubeBackgroundPlayerState();
}

class _YoutubeBackgroundPlayerState extends State<YoutubeBackgroundPlayer> {
  late final controller = WebViewController()
    ..setJavaScriptMode(JavaScriptMode.unrestricted)
    ..setBackgroundColor(Colors.black)
    ..loadHtmlString(_html(widget.videoId));

  static String _html(String id) =>
      '''
<!DOCTYPE html><html><head><meta name="viewport" content="width=device-width, initial-scale=1"><style>
html,body{margin:0;padding:0;background:#000;overflow:hidden;height:100%;width:100%;}
.wrap{position:relative;width:100%;height:100%;}
iframe{position:absolute;top:50%;left:50%;width:100%;height:100%;min-width:177.77vh;min-height:100%;transform:translate(-50%,-50%);border:0;pointer-events:none;}
</style></head><body>
<div class="wrap"><iframe
  src="https://www.youtube.com/embed/$id?autoplay=1&mute=1&loop=1&playlist=$id&controls=0&modestbranding=1&rel=0&showinfo=0&iv_load_policy=3&disablekb=1&fs=0&playsinline=1&enablejsapi=0"
  allow="autoplay; encrypted-media"
  allowfullscreen></iframe></div>
</body></html>
''';

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(16),
    child: AspectRatio(
      aspectRatio: 16 / 9,
      child: WebViewWidget(controller: controller),
    ),
  );
}
