import 'package:supabase_flutter/supabase_flutter.dart';

class AchievementImageService {
  final SupabaseClient supabase;

  AchievementImageService(this.supabase);

  //Returns public URL for image
  String getImageUrl(String fileName) {
    return supabase.storage
        .from('achievement')
        .getPublicUrl(fileName);
  }
}