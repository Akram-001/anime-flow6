import 'package:shonenx/core/anilist/services/anilist_service.dart';
import 'package:shonenx/core/models/anilist/anilist_media_list.dart';
import 'package:shonenx/core/repositories/anime_repository.dart';

class AniListRepository implements AnimeRepository {
  final AnilistService service;

  AniListRepository(this.service);

  @override
  Future<List<Media>> searchAnime(String title,
      {int page = 1, int perPage = 10}) {
    return service.searchAnime(title, page: page, perPage: perPage);
  }

  @override
  Future<Media> getAnimeDetails(int animeId) {
    return service.getAnimeDetails(animeId);
  }

  @override
  Future<List<Media>> getFavorites() {
    return service.getFavorites();
  }

  @override
  Future<List<Media>> getPopularAnime() {
    return service.getPopularAnime();
  }

  @override
  Future<List<Media>> getRecentlyUpdatedAnime() {
    return service.getRecentlyUpdatedAnime();
  }

  @override
  Future<List<Media>> getTopRatedAnime() {
    return service.getTopRatedAnime();
  }

  @override
  Future<List<Media>> getTrendingAnime() {
    return service.getTrendingAnime();
  }

  @override
  Future<List<Media>> getUpcomingAnime() {
    return service.getUpcomingAnime();
  }

  @override
  Future<MediaListCollection> getUserAnimeList(
      {required String type, required String status}) {
    return service.getUserAnimeList(type: type, status: status);
  }

  @override
  String get name => 'anilist';
}
