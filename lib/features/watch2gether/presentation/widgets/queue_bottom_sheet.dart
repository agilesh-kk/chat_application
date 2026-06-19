import 'package:chat_application/core/theme/app_pallette.dart';
import 'package:chat_application/features/watch2gether/domain/entity/w2g_video_item.dart';
import 'package:chat_application/features/watch2gether/presentation/bloc/w2g_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class QueueBottomSheet extends StatefulWidget {
  final List<W2GVideoItem> queue;
  final void Function(String url) onAdd;
  final void Function(String itemId) onRemove;

  const QueueBottomSheet({
    super.key,
    required this.queue,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  State<QueueBottomSheet> createState() => _QueueBottomSheetState();
}

class _QueueBottomSheetState extends State<QueueBottomSheet> {
  final _urlController = TextEditingController();

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppPallete.cardBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppPallete.greyText,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Video Queue',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _urlController,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'YouTube URL',
                    hintStyle: TextStyle(
                        color: AppPallete.greyText.withValues(alpha: 0.5)),
                    filled: true,
                    fillColor: AppPallete.inputBg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.add_circle,
                    color: AppPallete.primaryOrange, size: 32),
                onPressed: () {
                  final url = _urlController.text.trim();
                  if (url.isEmpty) return;
                  widget.onAdd(url);
                  _urlController.clear();
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: BlocBuilder<W2GBloc, W2GState>(
              builder: (context, state) {
                final queue = state is W2GRoomLoaded ? state.room.queue : widget.queue;
                if (queue.isEmpty) {
                  return const Center(
                    child: Text(
                      'Queue is empty.\nAdd videos above!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppPallete.greyText),
                    ),
                  );
                }
                return ListView.separated(
                  itemCount: queue.length,
                  separatorBuilder: (_, __) =>
                      const Divider(color: AppPallete.divider, height: 1),
                  itemBuilder: (context, index) {
                    final item = queue[index];
                    return ListTile(
                      leading: item.thumbnailUrl != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: Image.network(
                                item.thumbnailUrl!,
                                width: 64,
                                height: 48,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Icon(
                                  item.source == W2GVideoSource.youtube
                                      ? Icons.play_circle_fill
                                      : Icons.videocam,
                                  color: AppPallete.primaryOrange,
                                ),
                              ),
                            )
                          : Icon(
                              item.source == W2GVideoSource.youtube
                                  ? Icons.play_circle_fill
                                  : Icons.videocam,
                              color: AppPallete.primaryOrange,
                            ),
                      title: Text(
                        item.title,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        item.url,
                        style: TextStyle(
                          color: AppPallete.greyText.withValues(alpha: 0.7),
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.remove_circle_outline,
                            color: Colors.redAccent, size: 20),
                        onPressed: () => widget.onRemove(item.id),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
