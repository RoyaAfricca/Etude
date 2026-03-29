// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'schedule_slot.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ScheduleSlotAdapter extends TypeAdapter<ScheduleSlot> {
  @override
  final int typeId = 4;

  @override
  ScheduleSlot read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ScheduleSlot(
      dayOfWeek: fields[0] as int,
      startHour: fields[1] as int,
      startMinute: fields[2] as int,
      endHour: fields[3] as int,
      endMinute: fields[4] as int,
    );
  }

  @override
  void write(BinaryWriter writer, ScheduleSlot obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.dayOfWeek)
      ..writeByte(1)
      ..write(obj.startHour)
      ..writeByte(2)
      ..write(obj.startMinute)
      ..writeByte(3)
      ..write(obj.endHour)
      ..writeByte(4)
      ..write(obj.endMinute);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScheduleSlotAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
