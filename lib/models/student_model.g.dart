// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'student_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class StudentAdapter extends TypeAdapter<Student> {
  @override
  final int typeId = 0;

  @override
  Student read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Student(
      id: fields[0] as String,
      name: fields[1] as String,
      phone: fields[2] as String,
      sessionsSincePayment: fields[3] as int,
      pricePerCycle: fields[4] as double,
      pricePerMonth: fields[10] as double,
      pricePerSession: fields[11] as double,
      monthlyExpiry: fields[12] as DateTime?,
      attendances: (fields[5] as List?)?.cast<DateTime>(),
      payments: (fields[6] as List?)?.cast<Payment>(),
      groupId: fields[7] as String,
      email: fields[8] as String,
      originSchool: fields[9] as String,
      paymentMode: fields[13] as String,
      lastModifiedAt: fields[14] as DateTime?,
      isLocalOnly: fields[15] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, Student obj) {
    writer
      ..writeByte(16)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(14)
      ..write(obj.lastModifiedAt)
      ..writeByte(15)
      ..write(obj.isLocalOnly)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.phone)
      ..writeByte(3)
      ..write(obj.sessionsSincePayment)
      ..writeByte(4)
      ..write(obj.pricePerCycle)
      ..writeByte(10)
      ..write(obj.pricePerMonth)
      ..writeByte(11)
      ..write(obj.pricePerSession)
      ..writeByte(12)
      ..write(obj.monthlyExpiry)
      ..writeByte(5)
      ..write(obj.attendances)
      ..writeByte(6)
      ..write(obj.payments)
      ..writeByte(7)
      ..write(obj.groupId)
      ..writeByte(8)
      ..write(obj.email)
      ..writeByte(9)
      ..write(obj.originSchool)
      ..writeByte(13)
      ..write(obj.paymentMode);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StudentAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
