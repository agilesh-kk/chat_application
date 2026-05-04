import 'package:chat_application/core/common/widgets/loader.dart';
import 'package:chat_application/features/achievement/presentation/widgets/achievement_progress.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:get_it/get_it.dart';
import '../bloc/achievement_bloc.dart';
import '../widgets/achievement_grid.dart';

// Services
import '../../services/achievement_image_service.dart';


class AchievementPage extends StatefulWidget {
  final String userId;

  const AchievementPage({
    super.key,
    required this.userId,
  });

  @override
  State<AchievementPage> createState() => _AchievementPageState();
}

class _AchievementPageState extends State<AchievementPage> {
  Set<String> shownAchievements = {};

  late AchievementBloc _bloc;
  late AchievementImageService _imageService;

  @override
  void initState() {
    super.initState();

    // 🔥 Get Bloc from DI (GetIt)
    _bloc = GetIt.instance<AchievementBloc>();

    // 🔥 Initialize Supabase Image Service
    _imageService =
        AchievementImageService(Supabase.instance.client);

    // 🔥 Trigger Load
    _bloc.add(LoadAchievements(widget.userId));
  }

  @override
  void dispose() {
    // ❗ IMPORTANT: Do NOT close if using singleton bloc
    // _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Achievements"),
          centerTitle: true,
        ),

        body: BlocListener<AchievementBloc, AchievementState>(
          listener: (context, state) {
            if (state is AchievementLoaded) {
              final data = state.data;

              for (final ach in data.unlocked) {
                if (!data.seen.contains(ach)) {

                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      _showUnlockDialog(context, ach);
                    }
                  });

                  // 👇 MARK AS SEEN (IMPORTANT)
                  _bloc.add(MarkAchievementSeenEvent(
                    userId: widget.userId,
                    achievementId: ach,
                  ));

                  break;
                }
              }
            }
          },

          child: BlocBuilder<AchievementBloc, AchievementState>(
            builder: (context, state) {

              // 🌀 LOADING
              if (state is AchievementLoading ||
                  state is AchievementInitial) {
                return const Loader();
              }

              // ❌ ERROR
              if (state is AchievementError) {
                return Center(
                  child: Text(state.message),
                );
              }

              // ✅ DATA
              if (state is AchievementLoaded) {
                return Column(
                  children: [
                    // 📊 Progress
                    AchievementProgress(data: state.data),

                    // 🧱 Grid
                    Expanded(
                      child: AchievementGrid(
                        data: state.data,
                        imageService: _imageService,
                        onCollect: (id) {
                          _bloc.add(CollectAchievementEvent(id,widget.userId));
                        },
                      ),
                    ),
                  ],
                );
              }

              return const SizedBox();
            },
          ),
        ),
      ),
    );
  }

  // =========================
  // 🎉 UNLOCK DIALOG
  // =========================
  void _showUnlockDialog(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("🎉 Achievement Unlocked"),
          content: Text(id),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            )
          ],
        );
      },
    );
  }
}