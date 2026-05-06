import 'package:chat_application/core/theme/app_pallette.dart';
import 'package:chat_application/features/achievement/presentation/widgets/achievement_progress.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:get_it/get_it.dart';
import '../bloc/achievement_bloc.dart';
import '../widgets/achievement_grid.dart';
import '../../services/achievement_image_service.dart';
import '../../services/achievement_details_mapper.dart';

class AchievementPage extends StatefulWidget {
  final String userId;

  const AchievementPage({
    super.key,
    required this.userId,
  });

  @override
  State<AchievementPage> createState() => _AchievementPageState();
}

class _AchievementPageState extends State<AchievementPage>
    with SingleTickerProviderStateMixin {
  Set<String> shownAchievements = {};

  late AchievementBloc _bloc;
  late AchievementImageService _imageService;
  late AnimationController _dialogController;

  @override
  void initState() {
    super.initState();

    _bloc = GetIt.instance<AchievementBloc>();
    _imageService = AchievementImageService(Supabase.instance.client);
    _dialogController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _bloc.add(LoadAchievements(widget.userId));
  }

  @override
  void dispose() {
    _dialogController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: Scaffold(
        backgroundColor: AppPallete.darkBg,
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppPallete.darkBg,
                AppPallete.darkSecondary,
                AppPallete.darkBg,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
          child: SafeArea(
            child: BlocListener<AchievementBloc, AchievementState>(
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
                  return SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildHeader(context),
                        if (state is AchievementLoading ||
                            state is AchievementInitial)
                          const Padding(
                            padding: EdgeInsets.all(50),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: AppPallete.primaryOrange,
                              ),
                            ),
                          )
                        else if (state is AchievementError)
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Center(
                              child: Text(
                                state.message,
                                style: TextStyle(
                                  color: AppPallete.errorColor,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          )
                        else if (state is AchievementLoaded)
                          Column(
                            children: [
                              AchievementProgress(data: state.data),
                              AchievementGrid(
                                data: state.data,
                                imageService: _imageService,
                                onCollect: (id) {
                                  _bloc.add(CollectAchievementEvent(
                                    id,
                                    widget.userId,
                                  ));
                                },
                              ),
                            ],
                          )
                        else
                          const SizedBox(),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppPallete.cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppPallete.divider),
              ),
              child: const Icon(
                Icons.arrow_back,
                color: AppPallete.whiteColor,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Achievements',
                style: TextStyle(
                  color: AppPallete.whiteColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Collect them all',
                style: TextStyle(
                  color: AppPallete.greyText,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showUnlockDialog(BuildContext context, String id) {
    final detail = AchievementDetailsMapper.getById(id);

    _dialogController.reset();
    _dialogController.forward();

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) {
        return Dialog(
          backgroundColor: AppPallete.transparentColor,
          child: AnimatedBuilder(
            animation: _dialogController,
            builder: (_, __) {
              return Transform.scale(
                scale: Curves.easeOutBack.transform(
                  _dialogController.value.clamp(0.0, 1.0),
                ),
                child: Container(
                  width: double.maxFinite,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppPallete.cardBg,
                        AppPallete.darkTertiary,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: detail.rarity.color.withValues(alpha: 0.4),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: detail.rarity.color.withValues(alpha: 0.3),
                        blurRadius: 30,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                detail.rarity.color.withValues(alpha: 0.3),
                                detail.rarity.color.withValues(alpha: 0.1),
                              ],
                            ),
                            border: Border.all(
                              color: detail.rarity.color.withValues(alpha: 0.5),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: detail.rarity.color.withValues(alpha: 0.2),
                                blurRadius: 20,
                              ),
                            ],
                          ),
                          child: Icon(
                            detail.icon,
                            size: 40,
                            color: detail.rarity.color,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Achievement Unlocked',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppPallete.whiteColor,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          detail.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppPallete.whiteColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          detail.description,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppPallete.greyText,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: detail.rarity.color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              detail.rarity.label,
                              style: TextStyle(
                                fontSize: 13,
                                color: detail.rarity.color,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.maxFinite,
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppPallete.primaryOrange,
                              foregroundColor: AppPallete.whiteColor,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Continue',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
