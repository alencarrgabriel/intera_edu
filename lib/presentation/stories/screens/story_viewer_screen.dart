import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/design/app_tokens.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../domain/entities/story.dart';

class StoryViewerScreen extends StatefulWidget {
  final List<StoryGroup> groups;
  final int initialIndex;
  const StoryViewerScreen({
    super.key,
    required this.groups,
    this.initialIndex = 0,
  });

  @override
  State<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends State<StoryViewerScreen> {
  late int _groupIdx;
  int _storyIdx = 0;
  Timer? _timer;
  static const _duration = Duration(seconds: 5);

  @override
  void initState() {
    super.initState();
    _groupIdx = widget.initialIndex.clamp(0, widget.groups.length - 1);
    _start();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _start() {
    final story = widget.groups[_groupIdx].stories[_storyIdx];
    sl.storiesRepo.markViewed(story.id);
    _timer?.cancel();
    _timer = Timer(_duration, _next);
  }

  void _next() {
    final g = widget.groups[_groupIdx];
    if (_storyIdx < g.stories.length - 1) {
      setState(() => _storyIdx++);
      _start();
    } else if (_groupIdx < widget.groups.length - 1) {
      setState(() {
        _groupIdx++;
        _storyIdx = 0;
      });
      _start();
    } else {
      Navigator.of(context).maybePop();
    }
  }

  void _prev() {
    if (_storyIdx > 0) {
      setState(() => _storyIdx--);
      _start();
    } else if (_groupIdx > 0) {
      setState(() {
        _groupIdx--;
        _storyIdx = widget.groups[_groupIdx].stories.length - 1;
      });
      _start();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.groups.isEmpty) {
      return const Scaffold(body: Center(child: Text('Sem stories')));
    }
    final g = widget.groups[_groupIdx];
    final s = g.stories[_storyIdx];

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: GestureDetector(
          onTapUp: (d) {
            final w = MediaQuery.of(context).size.width;
            if (d.globalPosition.dx < w / 3) {
              _prev();
            } else {
              _next();
            }
          },
          child: Stack(
            children: [
              Center(
                child: s.mediaMime != null && s.mediaMime!.startsWith('video/')
                    ? GestureDetector(
                        onTap: () async {
                          await Clipboard.setData(ClipboardData(text: s.mediaUrl));
                          if (!context.mounted) return;
                          AppSnackbar.info(context, 'Link do vídeo copiado.');
                        },
                        child: Container(
                          color: Colors.black,
                          padding: const EdgeInsets.all(40),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.play_circle_outline_rounded,
                                  color: Colors.white70, size: 88),
                              SizedBox(height: 12),
                              Text(
                                'Toque pra copiar o link do vídeo',
                                style: TextStyle(color: Colors.white70),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      )
                    : Image.network(
                        s.mediaUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.broken_image,
                          color: Colors.white70,
                          size: 64,
                        ),
                      ),
              ),
              Positioned(
                top: 8,
                left: 12,
                right: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: List.generate(
                        g.stories.length,
                        (i) => Expanded(
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            height: 3,
                            decoration: BoxDecoration(
                              color: i < _storyIdx
                                  ? Colors.white
                                  : i == _storyIdx
                                      ? Colors.white
                                      : Colors.white24,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundImage: g.authorAvatarUrl != null
                              ? NetworkImage(g.authorAvatarUrl!)
                              : null,
                          backgroundColor: AppTokens.primaryContainer,
                          child: g.authorAvatarUrl == null
                              ? Text(
                                  g.authorName?.substring(0, 1).toUpperCase() ?? '?',
                                  style:
                                      const TextStyle(color: Colors.white),
                                )
                              : null,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            g.authorName ?? '—',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.of(context).maybePop(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (s.caption != null && s.caption!.isNotEmpty)
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: 32,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      s.caption!,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
