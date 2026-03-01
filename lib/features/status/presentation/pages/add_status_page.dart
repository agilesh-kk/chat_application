import 'dart:io';

import 'package:chat_application/core/common/widgets/loader.dart';
import 'package:chat_application/core/utils/show_snackbar.dart';
import 'package:chat_application/features/status/presentation/bloc/status_bloc.dart';
import 'package:chat_application/features/status/presentation/pages/status_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

class AddStatusPage extends StatelessWidget {
  final String id;
  final XFile image;
  const AddStatusPage({super.key, required this.id, required this.image});

  @override
  Widget build(BuildContext context) {
    final captionController = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        //title: Text(id),
      ),
      body: BlocConsumer<StatusBloc, StatusState>(
        listener: (context, state) {
          if(state is StatusFailure){
            showSnackbar(context, state.error);
          }
          else if(state is StatusUploadSuccess){
            captionController.clear();
            Navigator.push(
              context, 
              MaterialPageRoute(
                builder: (_)=> StatusPage(),
              ),
            );
          }
        },
        builder: (context, state) {
          if(state is StatusLoading){
            return const Loader();
          }
          return SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: Column(
              children: [
                Image.file(File(image.path)),
                TextFormField(
                  controller: captionController,
                  decoration: InputDecoration(hintText: "Add caption"),
                  maxLines:
                      null, //used to make new lines once each line is filled.
                  // validator: (value) { //to check if the fields are not empty.
                  //   if(value!.isEmpty){
                  //     return 'caption is missing';
                  //   }
                  //   return null;
                  // },
                ),
                ElevatedButton(
                  onPressed: () {
                    context.read<StatusBloc>().add(
                      UploadStatusEvent(
                        userId: id,
                        image: image,
                        caption: captionController.text.trim(),
                      ),
                    );
                  },
                  child: Text("Add"),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
