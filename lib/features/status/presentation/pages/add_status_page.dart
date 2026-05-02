import 'dart:io' as io;

import 'package:chat_application/core/common/cubit/app_user_cubit.dart';
import 'package:chat_application/core/common/widgets/loader.dart';
import 'package:chat_application/core/theme/app_pallette.dart';
import 'package:chat_application/core/utils/show_snackbar.dart';
import 'package:chat_application/features/status/presentation/bloc/status/status_bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

class AddStatusPage extends StatefulWidget {
  final String userId;
  final XFile image;
  final String userName;

  const AddStatusPage({
    super.key,
    required this.userId,
    required this.image,
    required this.userName,
  });

  @override
  State<AddStatusPage> createState() => _AddStatusPageState();
}

class _AddStatusPageState extends State<AddStatusPage> {
  late TextEditingController _captionController;
  String? _userProfile;

  @override
  void initState() {
    super.initState();
    _captionController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appUserState = context.read<AppUserCubit>().state;
      if (appUserState is AppUserIsSignedin) {
        setState(() {
          _userProfile = appUserState.user.profilePic;
        });
      }
    });
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          child: BlocConsumer<StatusBloc, StatusState>(
            listener: (context, state) {
              if (state is StatusFailure) {
                showSnackbar(context, state.error);
              } else if (state is StatusUploadSuccess) {
                _captionController.clear();
                Navigator.pop(context);
              }
            },
            builder: (context, state) {
              if (state is StatusLoading) {
                return const Loader();
              }
              return Column(
                children: [
                  _buildAppBar(context),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Expanded(child: _buildImagePreview()),
                          const SizedBox(height: 20),
                          _buildCaptionField(),
                          const SizedBox(height: 20),
                          _buildUploadButton(context),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close, color: AppPallete.whiteColor),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          Text(
            'New Status',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppPallete.whiteColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppPallete.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: kIsWeb
            ? Image.network(
                widget.image.path,
                fit: BoxFit.cover,
                width: double.infinity,
              )
            : Image.file(
                io.File(widget.image.path),
                fit: BoxFit.cover,
                width: double.infinity,
              ),
      ),
    );
  }

  Widget _buildCaptionField() {
    return Container(
      decoration: BoxDecoration(
        color: AppPallete.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppPallete.divider),
      ),
      child: TextFormField(
        controller: _captionController,
        style: const TextStyle(color: AppPallete.whiteColor),
        maxLines: 3,
        decoration: InputDecoration(
          hintText: 'Add a caption...',
          hintStyle: TextStyle(color: AppPallete.greyText),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }

  Widget _buildUploadButton(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [AppPallete.primaryOrange, AppPallete.lightOrange],
        ),
        boxShadow: [
          BoxShadow(
            color: AppPallete.primaryOrange.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: () {
          context.read<StatusBloc>().add(
                UploadStatusEvent(
                  userId: widget.userId,
                  image: widget.image,
                  caption: _captionController.text.trim(),
                  userName: widget.userName,
                  profilepic: _userProfile ?? '',
                ),
              );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: const Text(
          'Share Status',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}