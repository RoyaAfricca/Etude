// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'group_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class GroupAdapter extends TypeAdapter<Group> {
  @override
  final int typeId = 1;

  @override
  Group read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Group(
      id: fields[0] as String,
      name: fields[1] as String,
      subject: fields[2] as String,
      schedule: fields[3] as String,
      studentIds: (fields[4] as List?)?.cast<String>(),
      teacherId: fields[5] == null ? '' : fields[5] as String?,
      roomName: fields[6] == null ? '' : fields[6] as String?,
      level: fields[7] == null ? '' : fields[7] as String?,
      grade: fields[8] == null ? '' : fields[8] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Group obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.subject)
      ..writeByte(3)
      ..write(obj.schedule)
      ..writeByte(4)
      ..write(obj.studentIds)
      ..writeByte(5)
      ..write(obj.teacherId)
      ..writeByte(6)
      ..write(obj.roomName)
      ..writeByte(7)
      ..write(obj.level)
      ..writeByte(8)
      ..write(obj.grade);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GroupAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
