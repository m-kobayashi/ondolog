// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'checkpoint.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CheckpointAdapter extends TypeAdapter<Checkpoint> {
  @override
  final int typeId = 2;

  @override
  Checkpoint read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Checkpoint(
      id: fields[0] as String,
      locationId: fields[1] as String,
      name: fields[2] as String,
      checkpointType: fields[3] as String,
      minTemp: fields[4] as double?,
      maxTemp: fields[5] as double?,
      sortOrder: fields[6] as int,
      isActive: fields[7] as bool,
      createdAt: fields[8] as DateTime,
      updatedAt: fields[9] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, Checkpoint obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.locationId)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.checkpointType)
      ..writeByte(4)
      ..write(obj.minTemp)
      ..writeByte(5)
      ..write(obj.maxTemp)
      ..writeByte(6)
      ..write(obj.sortOrder)
      ..writeByte(7)
      ..write(obj.isActive)
      ..writeByte(8)
      ..write(obj.createdAt)
      ..writeByte(9)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CheckpointAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
