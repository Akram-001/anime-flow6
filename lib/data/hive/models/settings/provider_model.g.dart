// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'provider_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ProviderSettingsAdapter extends TypeAdapter<ProviderSettings> {
  @override
  final int typeId = 6;

  @override
  ProviderSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ProviderSettings(
      selectedProviderName: fields[0] as String,
      customApiUrl: fields[1] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ProviderSettings obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.selectedProviderName)
      ..writeByte(1)
      ..write(obj.customApiUrl);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProviderSettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
