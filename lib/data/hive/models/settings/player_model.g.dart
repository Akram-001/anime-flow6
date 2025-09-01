// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'player_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PlayerSettingsAdapter extends TypeAdapter<PlayerSettings> {
  @override
  final int typeId = 4;

  @override
  PlayerSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PlayerSettings(
      episodeCompletionThreshold: fields[0] as double,
      autoPlayNextEpisode: fields[1] as bool,
      preferSubtitles: fields[2] as bool,
      subtitleFontSize: fields[3] as double,
      subtitleTextColor: fields[4] as int,
      subtitleBackgroundOpacity: fields[5] as double,
      subtitleHasShadow: fields[6] as bool,
      subtitleShadowOpacity: fields[7] as double,
      subtitleShadowBlur: fields[8] as double,
      subtitleFontFamily: fields[9] as String?,
      subtitlePosition: fields[10] as int,
      defaultPlaybackSpeed: fields[11] as double,
      skipIntro: fields[12] as bool,
      skipOutro: fields[13] as bool,
      subtitleBoldText: fields[14] as bool,
      subtitleForceUppercase: fields[15] as bool,
      showRemainingTime: fields[16] as bool,
      showNextEpisodeAutoPlay: fields[17] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, PlayerSettings obj) {
    writer
      ..writeByte(18)
      ..writeByte(0)
      ..write(obj.episodeCompletionThreshold)
      ..writeByte(1)
      ..write(obj.autoPlayNextEpisode)
      ..writeByte(2)
      ..write(obj.preferSubtitles)
      ..writeByte(3)
      ..write(obj.subtitleFontSize)
      ..writeByte(4)
      ..write(obj.subtitleTextColor)
      ..writeByte(5)
      ..write(obj.subtitleBackgroundOpacity)
      ..writeByte(6)
      ..write(obj.subtitleHasShadow)
      ..writeByte(7)
      ..write(obj.subtitleShadowOpacity)
      ..writeByte(8)
      ..write(obj.subtitleShadowBlur)
      ..writeByte(9)
      ..write(obj.subtitleFontFamily)
      ..writeByte(10)
      ..write(obj.subtitlePosition)
      ..writeByte(11)
      ..write(obj.defaultPlaybackSpeed)
      ..writeByte(12)
      ..write(obj.skipIntro)
      ..writeByte(13)
      ..write(obj.skipOutro)
      ..writeByte(14)
      ..write(obj.subtitleBoldText)
      ..writeByte(15)
      ..write(obj.subtitleForceUppercase)
      ..writeByte(16)
      ..write(obj.showRemainingTime)
      ..writeByte(17)
      ..write(obj.showNextEpisodeAutoPlay);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlayerSettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
