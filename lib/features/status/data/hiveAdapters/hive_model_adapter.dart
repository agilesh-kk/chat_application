import 'package:chat_application/features/status/data/model/status_hive_model.dart';
import 'package:hive/hive.dart';

class StatusHiveModelAdapter extends TypeAdapter<StatusHiveModel> {
  @override
  final int typeId = 1;

  @override
  StatusHiveModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++)
        reader.readByte(): reader.read(),
    };

    return StatusHiveModel(
      id: fields[0] as String,
      userId: fields[1] as String,
      imageUrl: fields[2] as String,
      caption: fields[3] as String,
      createdAt: fields[4] as DateTime,
      expiresAt: fields[5] as DateTime,
      userName: fields[6] as String,
      localPath: fields[7] as String,
      profilepic: fields[8] as String
    );
  }

  @override
  void write(BinaryWriter writer, StatusHiveModel obj) {
    writer
      ..writeByte(9) // number of fields
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.imageUrl)
      ..writeByte(3)
      ..write(obj.caption)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.expiresAt)
      ..writeByte(6)
      ..write(obj.userName)
      ..writeByte(7)
      ..write(obj.localPath)
      ..writeByte(8)
      ..write(obj.profilepic);
  }
}