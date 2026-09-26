import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

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
/// branding. An [AbsorbPointer] makes it purely decorative — nothing the
/// viewer taps ever reaches the embedded player.
class YoutubeBackgroundPlayer extends StatefulWidget {
  const YoutubeBackgroundPlayer({super.key, required this.videoId});
  final String videoId;
  @override
  State<YoutubeBackgroundPlayer> createState() =>
      _YoutubeBackgroundPlayerState();
}

class _YoutubeBackgroundPlayerState extends State<YoutubeBackgroundPlayer> {
  late final WebViewController controller;

  @override
  void initState() {
    super.initState();
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black);
    // Android WebView blocks autoplaying media by default unless this is
    // explicitly disabled — without it, muted autoplay silently fails.
    final platform = controller.platform;
    if (platform is AndroidWebViewController) {
      platform.setMediaPlaybackRequiresUserGesture(false);
    }
    controller.loadRequest(
      Uri.https('www.youtube.com', '/embed/${widget.videoId}', {
        'autoplay': '1',
        'mute': '1',
        'loop': '1',
        'playlist': widget.videoId,
        'controls': '0',
        'modestbranding': '1',
        'rel': '0',
        'iv_load_policy': '3',
        'disablekb': '1',
        'fs': '0',
        'playsinline': '1',
      }),
    );
  }

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(16),
    child: AspectRatio(
      aspectRatio: 16 / 9,
      child: AbsorbPointer(child: WebViewWidget(controller: controller)),
    ),
  );
}
