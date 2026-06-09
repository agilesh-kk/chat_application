import 'package:chat_application/core/common/cubit/app_user_cubit.dart';
import 'package:chat_application/core/theme/app_pallette.dart';
import 'package:chat_application/core/utils/app_images.dart';
import 'package:chat_application/core/utils/image_picker_service.dart';
import 'package:chat_application/core/utils/modal_bottom_sheet.dart';
import 'package:chat_application/core/utils/show_confirmation_dialog.dart';
import 'package:chat_application/core/utils/show_snackbar.dart';
import 'package:chat_application/features/profile/presentation/bloc/profile_picture/profilePic_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

class EditAvatar extends StatefulWidget {
  final String userId;
  final String pfpUrl;

  const EditAvatar({
    super.key,
    required this.userId,
    required this.pfpUrl,
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
          showSnackbar(context, "Profile picture updated successfully");
          Navigator.pop(context);
        }

        if (state is ProfilePicUpdateFailure) {
          showSnackbar(context, state.message);
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
                        itemCount: AppImages.profileImages.length + 1,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return _AddCustomAvatarTile(
                              onTap: () => _onAddCustomTap(context),
                            );
                          }
                          return _AvatarCircle(
                            imagePath: AppImages.profileImages[index - 1],
                            onTap: () => _onAvatarTap(context, index - 1),
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

  Future<void> _onAddCustomTap(BuildContext context) async {
    final result = await ModalBottomSheet.show<String>(
      context,
      title: "Select Image Source",
      options: [
        BottomSheetOption(
          value: 'camera',
          label: 'Camera',
          icon: Icons.camera_alt,
        ),
        BottomSheetOption(
          value: 'gallery',
          label: 'Gallery',
          icon: Icons.photo_library,
        ),
      ],
    );

    if (result == null || !context.mounted) return;

    final imagePickerService = ImagePickerService();
    XFile? image;
    if (result == 'camera') {
      image = await imagePickerService.pickFromCamera();
    } else if (result == 'gallery') {
      image = await imagePickerService.pickFromGallery();
    }

    if (image != null && context.mounted) {
      context.read<ProfilePicBloc>().add(
            ProfilePicCustomUpload(
              userId: widget.userId,
              image: image,
              oldPfpImage: widget.pfpUrl,
            ),
          );
    }
  }
}

class _AddCustomAvatarTile extends StatefulWidget {
  final VoidCallback onTap;

  const _AddCustomAvatarTile({
    required this.onTap,
  });

  @override
  State<_AddCustomAvatarTile> createState() => _AddCustomAvatarTileState();
}

class _AddCustomAvatarTileState extends State<_AddCustomAvatarTile>
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
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                AppPallete.primaryOrange,
                AppPallete.lightOrange,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: AppPallete.primaryOrange.withValues(alpha: 0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Center(
            child: Icon(
              Icons.add,
              size: 48,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
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