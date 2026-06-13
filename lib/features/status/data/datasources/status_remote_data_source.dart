import 'dart:io';
import 'package:flutter/foundation.dart';

import 'package:chat_application/core/errors/exceptions.dart';
import 'package:chat_application/features/status/data/model/status_model.dart';
import 'package:chat_application/features/status/data/model/status_view_model.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract interface class StatusRemoteDataSource {
  Future<StatusModel> uploadStatus(StatusModel status);
  Future<String> uploadImage({required XFile image, required StatusModel status});

  Future<List<StatusModel>> getAllStatus();

  Future<void> updateView(StatusViewModel statusView);

  Future<List<StatusViewModel>> getViews(String statusId);

  Future<void> deleteStatus(String statusId);

  Future<void> addLike({
    required String statusId,
    required String userId,
  });
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
      if (kIsWeb) {
        final bytes = await image.readAsBytes();
        await supabaseClient.storage.from('status_images').uploadBinary(status.id, bytes);
      } else {
        final File file = File(image.path);
        await supabaseClient.storage.from('status_images').upload(status.id, file);
      }

      return supabaseClient.storage.from('status_images').getPublicUrl(status.id);
    }
    on PostgrestException catch(e){
      throw ServerExceptions(e.message);
    }
    catch(e){
      throw ServerExceptions(e.toString());
    }
  }

  @override
  Future<List<StatusModel>> getAllStatus() async {
    try{
      //final statuses = await supabaseClient.from('statuses').select();
      final nowUtc = DateTime.now().toUtc().toIso8601String();
      final statuses = await supabaseClient
        .from('statuses')
        .select()
        .gt('expires_at', nowUtc)
        .order('created_at', ascending: false);
      
      //print('working');
      return statuses.map(
        (status) => StatusModel.fromJson(status)
      ).toList();
    }
    on PostgrestException catch (e){
      throw ServerExceptions(e.message);
    }
    catch(e){
      throw ServerExceptions(e.toString());
    }
  }
  
  @override
  Future<void> updateView(StatusViewModel statusView) async{
    try{
      try {
        await supabaseClient
          .from('status_views')
          .insert(statusView.toJson())
          .select()
          .single();
      } on PostgrestException catch (e) {
        if (e.code != '23505') rethrow;
      }

      final response = await supabaseClient
        .from('statuses')
        .select('viewed_by')
        .eq('id', statusView.statusId)
        .single();

      List<String> viewedBy = List<String>.from(response['viewed_by'] ?? []);
      if (!viewedBy.contains(statusView.viewerId)) {
        viewedBy.add(statusView.viewerId);
        await supabaseClient
            .from('statuses')
            .update({'viewed_by': viewedBy})
            .eq('id', statusView.statusId);
      }
    }
    on PostgrestException catch (e) {
      throw ServerExceptions(e.message);
    } catch (e) {
      throw ServerExceptions(e.toString());
    }
  }
  
  @override
  Future<List<StatusViewModel>> getViews(String statusId) async{
    try{
      final response = await supabaseClient
        .from('status_views')
        .select()
        .eq('status_id', statusId);

      final List data = response as List;

      return data
          .map((json) => StatusViewModel.fromJson(json))
          .toList();
    }
    on PostgrestException catch (e){
      throw ServerExceptions(e.message);
    }
    catch(e){
      throw ServerExceptions(e.toString());
    }
  }
  
  @override
  Future<void> deleteStatus(String statusId) async {
    try {
      //deleting image from storage
      await supabaseClient
          .storage
          .from('status_images')
          .remove([statusId]);

      //deleting related views
      await supabaseClient
          .from('status_views')
          .delete()
          .eq('status_id', statusId);

      //deleting status
      await supabaseClient
          .from('statuses')
          .delete()
          .eq('id', statusId);

    } on PostgrestException catch (e) {
      throw ServerExceptions(e.message);
    } catch (e) {
      throw ServerExceptions(e.toString());
    }
  }
  
  @override
  Future<void> addLike({
    required String statusId,
    required String userId,
  }) async {
    try {
      final response = await supabaseClient
          .from('statuses')
          .select('liked_by')
          .eq('id', statusId)
          .single();

      List<String> likedBy = List<String>.from(
        response['liked_by'] ?? [],
      );

      final bool isLiked = likedBy.contains(userId);

      if (isLiked) {
        likedBy.remove(userId);
      } else {
        likedBy.add(userId);
      }

      await supabaseClient
          .from('statuses')
          .update({
            'liked_by': likedBy,
          })
          .eq('id', statusId);

      await supabaseClient
          .from('status_views')
          .update({
            'liked': !isLiked,
          })
          .eq('status_id', statusId)
          .eq('viewer_id', userId);

    } on PostgrestException catch (e) {
      throw ServerExceptions(e.message);
    } catch (e) {
      throw ServerExceptions(e.toString());
    }
  }
}