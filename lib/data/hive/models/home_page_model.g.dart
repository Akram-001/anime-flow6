// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_page_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HomePageModelAdapter extends TypeAdapter<HomePageModel> {
  @override
  final int typeId = 5;

  @override
  HomePageModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HomePageModel(
      trendingAnime: (fields[0] as List)
          .map((dynamic e) => (e as Map).cast<String, dynamic>())
          .toList(),
      popularAnime: (fields[1] as List)
          .map((dynamic e) => (e as Map).cast<String, dynamic>())
          .toList(),
      recentlyUpdated: (fields[2] as List)
          .map((dynamic e) => (e as Map).cast<String, dynamic>())
          .toList(),
      topRatedAnime: (fields[3] as List)
          .map((dynamic e) => (e as Map).cast<String, dynamic>())
          .toList(),
      mostFavoriteAnime: (fields[4] as List)
          .map((dynamic e) => (e as Map).cast<String, dynamic>())
          .toList(),
      mostWatchedAnime: (fields[5] as List)
          .map((dynamic e) => (e as Map).cast<String, dynamic>())
          .toList(),
      lastUpdated: fields[6] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, HomePageModel obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.trendingAnime)
      ..writeByte(1)
      ..write(obj.popularAnime)
      ..writeByte(2)
      ..write(obj.recentlyUpdated)
      ..writeByte(3)
      ..write(obj.topRatedAnime)
      ..writeByte(4)
      ..write(obj.mostFavoriteAnime)
      ..writeByte(5)
      ..write(obj.mostWatchedAnime)
      ..writeByte(6)
      ..write(obj.lastUpdated);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HomePageModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
