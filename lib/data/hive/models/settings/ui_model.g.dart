// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ui_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UiSettingsAdapter extends TypeAdapter<UiSettings> {
  @override
  final int typeId = 3;

  @override
  UiSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UiSettings(
      compactMode: fields[0] as bool,
      defaultTab: fields[1] as String,
      showThumbnails: fields[2] as bool,
      cardStyle: fields[3] as String,
      layoutStyle: fields[4] as String,
      immersiveMode: fields[5] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, UiSettings obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.compactMode)
      ..writeByte(1)
      ..write(obj.defaultTab)
      ..writeByte(2)
      ..write(obj.showThumbnails)
      ..writeByte(3)
      ..write(obj.cardStyle)
      ..writeByte(4)
      ..write(obj.layoutStyle)
      ..writeByte(5)
      ..write(obj.immersiveMode);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UiSettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
