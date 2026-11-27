import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../theme/app_colors.dart';
import '../widgets/common.dart';

/// असली 24x7 लाइव दर्शन — HLS (m3u8) स्ट्रीम प्लेयर।
/// `AppConfig.liveStreamUrl` खाली हो तो यह विजेट नहीं बनता (डेमो स्क्रीन चलती है)।
class LiveStreamView extends StatefulWidget {
  const LiveStreamView({super.key, required this.url, this.height = 230});

  final String url;
  final double height;

  @override
  State<LiveStreamView> createState() => _LiveStreamViewState();
}

class _LiveStreamViewState extends State<LiveStreamView> {
  VideoPlayerController? _controller;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final controller = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    _controller = controller;
    try {
      await controller.initialize();
      await controller.setLooping(true);
      await controller.play();
      if (!mounted) return;
      setState(() => _loading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'स्ट्रीम नहीं खुल पाई — कनेक्शन जाँचें';
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _retry() {
    setState(() {
      _error = null;
      _loading = true;
    });
    _controller?.dispose();
    _controller = null;
    _init();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        height: widget.height,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: Color(0xFF2A0A10)),
            if (_error != null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const AppIcon('alert', size: 22, color: C.gold2),
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 11.5, color: C.creamText),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: 140,
                        child: BsmButton(
                          label: 'फिर कोशिश करें',
                          kind: BtnKind.ghost,
                          small: true,
                          onPressed: _retry,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else if (_loading || controller == null || !controller.value.isInitialized)
              const Center(
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(strokeWidth: 3, color: C.gold2),
                ),
              )
            else
              FittedBox(
                fit: BoxFit.cover,
                clipBehavior: Clip.hardEdge,
                child: SizedBox(
                  width: controller.value.size.width,
                  height: controller.value.size.height,
                  child: VideoPlayer(controller),
                ),
              ),
            // LIVE बैज
            Positioned(
              top: 9,
              left: 9,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0x88000000),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _LiveDot(),
                    SizedBox(width: 5),
                    Text(
                      'LIVE · गर्भगृह',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFFFD9DC),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // म्यूट / अनम्यूट
            if (controller != null && controller.value.isInitialized)
              Positioned(
                bottom: 8,
                right: 8,
                child: Material(
                  color: const Color(0x88000000),
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () {
                      controller.setVolume(controller.value.volume > 0 ? 0 : 1);
                      setState(() {});
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(7),
                      child: AppIcon(
                        controller.value.volume > 0 ? 'bell' : 'close',
                        size: 14,
                        color: C.creamText,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _LiveDot extends StatelessWidget {
  const _LiveDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 6,
      height: 6,
      decoration: const BoxDecoration(color: Color(0xFFFF5A64), shape: BoxShape.circle),
    );
  }
}
