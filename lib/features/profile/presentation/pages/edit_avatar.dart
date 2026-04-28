import 'package:chat_application/core/common/cubit/app_user_cubit.dart';
import 'package:chat_application/core/theme/app_pallette.dart';
import 'package:chat_application/core/utils/app_images.dart';
import 'package:chat_application/core/utils/show_confirmation_dialog.dart';
import 'package:chat_application/features/profile/presentation/bloc/profile_picture/profilePic_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class EditAvatar extends StatefulWidget {
  final String userId;

  const EditAvatar({
    super.key,
    required this.userId,
  });

  @override
  State<EditAvatar> createState() => _EditAvatarState();
}

class _EditAvatarState extends State<EditAvatar> {
  @override
  Widget build(BuildContext context) {
    return BlocListener<ProfilePicBloc, ProfilePicState>(
      listener: (context, state) {
        if (state is ProfilePicUpdateScuccess) {
          context.read<AppUserCubit>().updateUserProfilePic(state.imageUrl);
          Navigator.pop(context);
        }

        if (state is ProfilePicUpdateFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppPallete.errorColor,
            ),
          );
        }
      },
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
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                _buildAppBar(context),
                Expanded(
                  child: BlocBuilder<ProfilePicBloc, ProfilePicState>(
                    builder: (context, state) {
                      if (state is ProfilePicLoading) {
                        return _buildLoading();
                      }

                      return GridView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: AppImages.profileImages.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemBuilder: (context, index) {
                          return _AvatarCircle(
                            imagePath: AppImages.profileImages[index],
                            onTap: () => _onAvatarTap(context, index),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppPallete.cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppPallete.divider),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => Navigator.pop(context),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Icon(
                    Icons.arrow_back,
                    color: AppPallete.whiteColor,
                    size: 22,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Avatar",
                style: TextStyle(
                  color: AppPallete.whiteColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppPallete.primaryOrange,
                          AppPallete.lightOrange,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    width: 16,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppPallete.divider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: CircularProgressIndicator(
        color: AppPallete.primaryOrange,
      ),
    );
  }

  Future<void> _onAvatarTap(BuildContext context, int index) async {
    final confirm = await showConfirmationDialog(
      context,
      "Change profile picture?",
      Icons.image,
    );

    if (confirm == true && context.mounted) {
      context.read<ProfilePicBloc>().add(
            ProfilePicUpdate(
              userId: widget.userId,
              imageUrl: AppImages.profileImages[index],
            ),
          );
    }
  }
}

class _AvatarCircle extends StatefulWidget {
  final String imagePath;
  final VoidCallback onTap;

  const _AvatarCircle({
    required this.imagePath,
    required this.onTap,
  });

  @override
  State<_AvatarCircle> createState() => _AvatarCircleState();
}

class _AvatarCircleState extends State<_AvatarCircle>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: CircleAvatar(
          radius: 50,
          backgroundColor: AppPallete.cardBg,
          backgroundImage: AssetImage(widget.imagePath),
          foregroundImage: null,
        ),
      ),
    );
  }
}