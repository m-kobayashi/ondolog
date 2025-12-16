// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'record.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TemperatureRecordAdapter extends TypeAdapter<TemperatureRecord> {
  @override
  final int typeId = 3;

  @override
  TemperatureRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TemperatureRecord(
      id: fields[0] as String,
      checkpointId: fields[1] as String,
      temperature: fields[2] as double,
      recordedAt: fields[3] as DateTime,
      recordedBy: fields[4] as String?,
      isAbnormal: fields[5] as bool,
      abnormalAction: fields[6] as String?,
      notes: fields[7] as String?,
      createdAt: fields[8] as DateTime,
      synced: fields[9] as bool?,
    );
  }

  @override
  void write(BinaryWriter writer, TemperatureRecord obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.checkpointId)
      ..writeByte(2)
      ..write(obj.temperature)
      ..writeByte(3)
      ..write(obj.recordedAt)
      ..writeByte(4)
      ..write(obj.recordedBy)
      ..writeByte(5)
      ..write(obj.isAbnormal)
      ..writeByte(6)
      ..write(obj.abnormalAction)
      ..writeByte(7)
      ..write(obj.notes)
      ..writeByte(8)
      ..write(obj.createdAt)
      ..writeByte(9)
      ..write(obj.synced);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TemperatureRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
