import 'dart:io';

import 'package:chat_application/core/errors/exceptions.dart';
import 'package:chat_application/features/status/data/model/status_model.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract interface class StatusRemoteDataSource {
  Future<StatusModel> uploadStatus(StatusModel status);
  Future<String> uploadImage({required XFile image, required StatusModel status});

  //Future<List<StatusModel>> getAllStatus();
}

class StatusRemoteDataSourceImpl implements StatusRemoteDataSource{
  final SupabaseClient supabaseClient;

  StatusRemoteDataSourceImpl({required this.supabaseClient});
  @override
  Future<StatusModel> uploadStatus(StatusModel status) async {
    try {
      final response = await supabaseClient
          .from('statuses')
          .insert(status.toJson()) //converting from map to json
          .select()
          .single();

      return StatusModel.fromJson(response);
    } on PostgrestException catch (e) {
      throw ServerExceptions(e.message);
    } catch (e) {
      throw ServerExceptions(e.toString());
    }
  }

  @override
  Future<String> uploadImage({required XFile image, required StatusModel status}) async{
    try{
      final File file = File(image.path);
      
      await supabaseClient.storage.from('status_images').upload(status.id, file);

      return supabaseClient.storage.from('status_images').getPublicUrl(status.id);
    }
    on PostgrestException catch(e){
      throw ServerExceptions(e.message);
    }
    catch(e){
      throw ServerExceptions(e.toString());
    }
  }

  // @override
  // Future<List<StatusModel>> getAllStatus() {
  //   // TODO: implement getAllStatus
  //   throw UnimplementedError();
  // }
}