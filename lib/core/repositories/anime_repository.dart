import '../models/anilist/anilist_media_list.dart';

abstract class AnimeRepository {
  String get name;
  Future<MediaListCollection> getUserAnimeList({required String type, required String status});
  Future<List<Media>> getFavorites();
  Future<List<Media>> searchAnime(String title, {int page = 1, int perPage = 10});
  Future<Media> getAnimeDetails(int animeId);
  Future<List<Media>> getTrendingAnime();
  Future<List<Media>> getPopularAnime();
  Future<List<Media>> getTopRatedAnime();
  Future<List<Media>> getRecentlyUpdatedAnime();
  Future<List<Media>> getUpcomingAnime();
}
