import 'package:chat_application/features/profile/data/model/profile_pic_hive_model.dart';
import 'package:hive/hive.dart';

class ProfilePicHiveModelAdapter extends TypeAdapter<ProfilePicHiveModel> {
  @override
  final int typeId = 2;

  @override
  ProfilePicHiveModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };

    return ProfilePicHiveModel(
      userId: fields[0] as String,
      profilePicUrl: fields[1] as String,
      localPath: fields[2] as String,
      lastUpdated: fields[3] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, ProfilePicHiveModel obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.userId)
      ..writeByte(1)
      ..write(obj.profilePicUrl)
      ..writeByte(2)
      ..write(obj.localPath)
      ..writeByte(3)
      ..write(obj.lastUpdated);
  }
}
