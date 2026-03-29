import 'package:chat_application/core/common/cubit/app_user_cubit.dart';
import 'package:chat_application/core/utils/app_images.dart';
import 'package:chat_application/core/utils/show_confirmation_dialog.dart';
import 'package:chat_application/features/profile/presentation/bloc/profile_picture/profilePic_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class EditAvatar extends StatelessWidget {
  final String userId;

  const EditAvatar({
    super.key,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocListener<ProfilePicBloc, ProfilePicState>(
      listener: (context, state) {
        if (state is ProfilePicUpdateScuccess) {
          //Update local state
          context
              .read<AppUserCubit>()
              .updateUserProfilePic(state.imageUrl);

          Navigator.pop(context);
        }

        if (state is ProfilePicUpdateFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Edit Avatar"),
        ),
        body: BlocBuilder<ProfilePicBloc, ProfilePicState>(
          builder: (context, state) {
            if (state is ProfilePicLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            return GridView.builder(
              itemCount: AppImages.profileImages.length,
              padding: const EdgeInsets.all(10),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemBuilder: (context, index) {
                final selectedImage =
                    AppImages.profileImages[index];

                return InkWell(
                  onTap: () async {
                    final confirm = await showConfirmationDialog(
                      context,
                      "Change profile picture?",
                      Icons.image,
                    );

                    if (confirm == true && context.mounted) {
                      context.read<ProfilePicBloc>().add(
                            ProfilePicUpdate(
                              userId: userId,
                              imageUrl: selectedImage,
                            ),
                          );
                    }
                  },
                  child: Center(
                    child: CircleAvatar(
                      radius: 80,
                      backgroundImage:
                          AssetImage(selectedImage),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}