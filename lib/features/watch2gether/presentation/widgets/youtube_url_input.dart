import 'package:chat_application/core/theme/app_pallette.dart';
import 'package:chat_application/features/watch2gether/presentation/bloc/youtube_player_bloc.dart';
import 'package:chat_application/features/watch2gether/presentation/bloc/youtube_player_event.dart';
import 'package:chat_application/features/watch2gether/presentation/bloc/youtube_player_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class YoutubeUrlInput extends StatefulWidget {
  final void Function(String videoId)? onVideoLoaded;

  const YoutubeUrlInput({super.key, this.onVideoLoaded});

  @override
  State<YoutubeUrlInput> createState() => _YoutubeUrlInputState();
}

class _YoutubeUrlInputState extends State<YoutubeUrlInput> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<YoutubePlayerBloc, YoutubePlayerState>(
      listener: (context, state) {
        if (state is YoutubePlayerLoaded) {
          widget.onVideoLoaded?.call(state.videoData.videoId);
        }
      },
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Paste YouTube URL...',
                      hintStyle: TextStyle(
                          color: AppPallete.greyText.withValues(alpha: 0.5)),
                      filled: true,
                      fillColor: AppPallete.inputBg,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      suffixIcon: state is YoutubePlayerLoading
                          ? const Padding(
                              padding: EdgeInsets.all(10),
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppPallete.primaryOrange,
                                ),
                              ),
                            )
                          : null,
                    ),
                    onSubmitted: (_) => _loadVideo(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.play_circle_fill,
                      color: AppPallete.primaryOrange, size: 32),
                  onPressed: _loadVideo,
                ),
              ],
            ),
            if (state is YoutubePlayerError)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  state.message,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                ),
              ),
          ],
        );
      },
    );
  }

  void _loadVideo() {
    final url = _controller.text.trim();
    if (url.isEmpty) return;
    context.read<YoutubePlayerBloc>().add(LoadYoutubeVideo(url));
  }
}
