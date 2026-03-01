import 'package:chat_application/core/common/cubit/app_user_cubit.dart';
import 'package:chat_application/core/utils/image_picker_service.dart';
import 'package:chat_application/core/utils/modal_bottom_sheet.dart';
import 'package:chat_application/features/status/presentation/bloc/status_bloc.dart';
import 'package:chat_application/features/status/presentation/pages/add_status_page.dart';
import 'package:chat_application/features/status/presentation/widgets/user_status_column.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

class StatusPage extends StatefulWidget {
  const StatusPage({super.key});

  @override
  State<StatusPage> createState() => _StatusPageState();
}

class _StatusPageState extends State<StatusPage> {
  //XFile? _pickedImage;
  final _imagePickerService = ImagePickerService();

  //function that calls modalbottomsheet class
  void _showImageSourceBottomSheet(String userId) async {
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

    XFile? image;

    if (result == 'camera') {
      image = await _imagePickerService.pickFromCamera();
    } else if (result == 'gallery') {
      image = await _imagePickerService.pickFromGallery();
    }

    if (image != null && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BlocProvider.value(
            value: context.read<StatusBloc>(),
            child: AddStatusPage(
              id: userId,
              image: image!,
            ),
          ),
        ),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final appUserState = context.watch<AppUserCubit>().state;

    if (appUserState is! AppUserIsSignedin) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final String username = appUserState.user.name;
    final String userid = appUserState.user.id;

    return Scaffold(
      appBar: AppBar(
        title: Text("Status"),
      ),
      body: Padding(
        padding: EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            UserStatusColumn(
              name: username,
              onPressed: (){
                _showImageSourceBottomSheet(userid);
              },
            ),
            SizedBox(height: 20,),
            Text(
              "Friends",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20
              ),
            ),
            SizedBox(height: 10,),
          ],
        ),
      ),
    );
  }
}