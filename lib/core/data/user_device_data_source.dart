import 'package:supabase_flutter/supabase_flutter.dart';

abstract class UserDeviceDataSource {
  Future<void> upsertToken(String userId, String fcmToken, String platform);
  Future<void> deleteToken(String fcmToken);
}

class UserDeviceDataSourceImpl implements UserDeviceDataSource {
  final SupabaseClient supabase;

  UserDeviceDataSourceImpl(this.supabase);

  @override
  Future<void> upsertToken(String userId, String fcmToken, String platform) async {
    await supabase.from('user_devices').upsert({
      'user_id': userId,
      'fcm_token': fcmToken,
      'device_name': platform,
    }, onConflict: 'fcm_token');
  }

  @override
  Future<void> deleteToken(String fcmToken) async {
    await supabase.from('user_devices').delete().eq('fcm_token', fcmToken);
  }
}
