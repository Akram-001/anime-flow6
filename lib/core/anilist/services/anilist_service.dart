// lib/core/anilist/anilist_service.dart
import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:shonenx/core/anilist/graphql_client.dart';
import 'package:shonenx/core/anilist/queries.dart';
import 'package:shonenx/core/models/anilist/anilist_media_list.dart';
import 'package:shonenx/core/repositories/anime_repository.dart';
import 'package:shonenx/core/services/auth_provider_enum.dart';
import 'package:shonenx/core/utils/app_logger.dart';
import 'package:shonenx/features/auth/view_model/auth_notifier.dart';

/// Custom exception for Anilist service errors
class AnilistServiceException implements Exception {
  final String message;
  final dynamic error;

  AnilistServiceException(this.message, [this.error]);

  @override
  String toString() =>
      'AnilistServiceException: $message${error != null ? ' ($error)' : ''}';
}

/// Service class for interacting with AniList-like sources.
/// This implementation uses REST endpoints (Jikan as primary, Kitsu as backup),
/// and falls back to AniList GraphQL for authenticated user operations when token available.
class AnilistService implements AnimeRepository {
  final Ref _ref;

  AnilistService(this._ref);

  @override
  String get name => 'Anilist';

  static const _validStatuses = {
    'CURRENT',
    'COMPLETED',
    'PAUSED',
    'DROPPED',
    'PLANNING',
    'REPEATING',
  };

  // Timeouts and retry settings
  static const Duration _requestTimeout = Duration(seconds: 5);

  String get _primary => dotenv.env['API_URL'] ?? 'https://api.jikan.moe/v4';
  String get _backup => dotenv.env['BACKUP_API_URL'] ?? 'https://kitsu.io/api/edge';

  ({int userId, String accessToken})? _getAuthContext() {
    final authState = _ref.read(authProvider);

    if (!authState.isLoggedIn ||
        authState.authPlatform != AuthPlatform.anilist) {
      AppLogger.w('Anilist operation requires a logged-in Anilist user.');
      return null;
    }

    final userId = authState.user?.id;
    final accessToken = authState.anilistAccessToken;

    if (userId == null || accessToken == null || accessToken.isEmpty) {
      AppLogger.w(
          'Invalid user ID or access token for authenticated operation.');
      return null;
    }
    return (userId: userId, accessToken: accessToken);
  }

  // -----------------------
  // Helper: perform GET with fallback primary -> backup
  // -----------------------
  Future<http.Response> _getWithFallback(String primaryPath, String backupPath,
      {Map<String, String>? headers}) async {
    final primaryUri = Uri.parse(primaryPath);
    final backupUri = Uri.parse(backupPath);

    try {
      AppLogger.d('Trying primary API: $primaryUri');
      final resp = await http.get(primaryUri, headers: headers).timeout(_requestTimeout);
      if (resp.statusCode == 200) {
        return resp;
      } else {
        AppLogger.w('Primary API returned ${resp.statusCode}. Switching to backup.');
      }
    } catch (e, st) {
      AppLogger.w('Primary API failed: $e. Trying backup...', e, st);
    }

    // try backup
    try {
      AppLogger.d('Trying backup API: $backupUri');
      final resp = await http.get(backupUri, headers: headers).timeout(_requestTimeout);
      return resp;
    } catch (e, st) {
      AppLogger.e('Backup API failed as well', e, st);
      rethrow;
    }
  }

  // -----------------------
  // Mapping helpers: convert Jikan/Kitsu item -> AniList-like map for Media.fromJson
  // -----------------------
  Map<String, dynamic> _mapJikanToAniList(Map<String, dynamic> jikan) {
    // jikan structure: {mal_id, title, images: {jpg: {image_url}}, synopsis, score, ...}
    final id = jikan['mal_id'] ?? jikan['id'];
    final title = jikan['title'] ??
        (jikan['titles'] != null && jikan['titles'] is List && jikan['titles'].isNotEmpty
            ? jikan['titles'][0]
            : null);
    final image = (jikan['images'] != null && jikan['images']['jpg'] != null)
        ? jikan['images']['jpg']['image_url']
        : jikan['image_url'] ?? null;
    return {
      'id': id ?? 0,
      'title': {
        'romaji': title ?? '',
        'english': jikan['title_english'] ?? '',
        'native': jikan['title_japanese'] ?? ''
      },
      'coverImage': {'large': image ?? ''},
      'description': jikan['synopsis'] ?? jikan['summary'] ?? '',
      'averageScore': ((jikan['score'] is num) ? (jikan['score'] * 10).toInt() : null),
      'episodes': jikan['episodes'] ?? null,
      'startDate': jikan['aired']?['from'] ?? null,
      'genres': (jikan['genres'] is List)
          ? jikan['genres'].map((g) => {'name': g['name'] ?? g}).toList()
          : [],
    };
  }

  Map<String, dynamic> _mapKitsuToAniList(Map<String, dynamic> kitsu) {
    // kitsu item fields: id, attributes: {canonicalTitle, posterImage: {small, medium, large}, synopsis}
    final id = kitsu['id'] ?? (kitsu['mal_id'] ?? 0);
    final attr = kitsu['attributes'] ?? {};
    final title = attr['canonicalTitle'] ?? attr['titles']?['en_jp'] ?? '';
    final image = (attr['posterImage'] != null) ? (attr['posterImage']['large'] ?? attr['posterImage']['medium'] ?? attr['posterImage']['small']) : null;
    return {
      'id': int.tryParse(id?.toString() ?? '') ?? 0,
      'title': {
        'romaji': title,
        'english': attr['titles']?['en'] ?? '',
        'native': attr['titles']?['ja_jp'] ?? ''
      },
      'coverImage': {'large': image ?? ''},
      'description': attr['synopsis'] ?? '',
      'averageScore': (attr['averageRating'] != null) ? (double.tryParse(attr['averageRating'].toString()) != null ? (double.parse(attr['averageRating'].toString()) * 10).toInt() : null) : null,
      'episodes': attr['episodeCount'],
      'startDate': attr['startDate'],
      'genres': [], // Kitsu genre mapping requires extra call; leave empty
    };
  }

  // -----------------------
  // REST-based fetchers using Jikan/Kitsu with mapping
  // -----------------------

  Future<List<Media>> _searchByJikan(String title, int page, int perPage) async {
    final primary = '$_primary/anime?q=${Uri.encodeComponent(title)}&page=$page';
    final backup = '$_backup/anime?filter[text]=${Uri.encodeComponent(title)}&page[$page]';
    try {
      final resp = await _getWithFallback(primary, backup);
      final decoded = jsonDecode(resp.body);
      // Jikan: data is list under 'data'
      if (decoded is Map && decoded.containsKey('data')) {
        final list = decoded['data'] as List;
        final mapped = list.map((e) => Media.fromJson(_mapJikanToAniList(e as Map<String, dynamic>))).toList();
        return mapped;
      }
      // Kitsu structure: data: [{id, attributes: {...}}]
      if (decoded is Map && decoded.containsKey('data')) {
        final list = decoded['data'] as List;
        final mapped = list.map((e) => Media.fromJson(_mapKitsuToAniList(e['attributes'] as Map<String, dynamic>))).toList();
        return mapped;
      }
      return [];
    } catch (e, st) {
      AppLogger.e('Search by Jikan/Kitsu failed', e, st);
      return [];
    }
  }

  // Public search method
  @override
  Future<List<Media>> searchAnime(String title,
      {int page = 1, int perPage = 10}) async {
    // Prefer Jikan -> Kitsu
    final jikanUrl = '$_primary/anime?q=${Uri.encodeComponent(title)}&page=$page';
    final kitsuUrl = '$_backup/anime?filter[text]=${Uri.encodeComponent(title)}&page[$page]';
    try {
      final resp = await _getWithFallback(jikanUrl, kitsuUrl);
      final decoded = jsonDecode(resp.body);
      // Jikan returns { data: [...] }
      if (decoded is Map && decoded.containsKey('data')) {
        final list = decoded['data'] as List;
        return list.map((e) => Media.fromJson(_mapJikanToAniList(e as Map<String, dynamic>))).toList();
      }
      return [];
    } catch (e, st) {
      AppLogger.e('searchAnime failed', e, st);
      return [];
    }
  }

  // For endpoints like trending/popular: we try to use Jikan /top/anime then Kitsu alternatives.
  @override
  Future<List<Media>> getTrendingAnime() async {
    try {
      final primaryUrl = '$_primary/top/anime';
      final backupUrl = '$_backup/trending/anime'; // may not exist; fallback handled in _getWithFallback
      final resp = await _getWithFallback(primaryUrl, backupUrl);
      final decoded = jsonDecode(resp.body);
      if (decoded is Map && decoded.containsKey('data')) {
        final list = decoded['data'] as List;
        return list.map((e) => Media.fromJson(_mapJikanToAniList(e as Map<String, dynamic>))).toList();
      }
      return [];
    } catch (e, st) {
      AppLogger.e('getTrendingAnime failed', e, st);
      return [];
    }
  }

  @override
  Future<List<Media>> getPopularAnime() async {
    try {
      final primaryUrl = '$_primary/top/anime';
      final backupUrl = '$_backup/anime'; // maybe sorted on server; try as fallback
      final resp = await _getWithFallback(primaryUrl, backupUrl);
      final decoded = jsonDecode(resp.body);
      if (decoded is Map && decoded.containsKey('data')) {
        final list = decoded['data'] as List;
        return list.map((e) => Media.fromJson(_mapJikanToAniList(e as Map<String, dynamic>))).toList();
      }
      return [];
    } catch (e, st) {
      AppLogger.e('getPopularAnime failed', e, st);
      return [];
    }
  }

  @override
  Future<List<Media>> getTopRatedAnime() async {
    try {
      final primaryUrl = '$_primary/top/anime';
      final resp = await _getWithFallback(primaryUrl, '$_backup/anime');
      final decoded = jsonDecode(resp.body);
      if (decoded is Map && decoded.containsKey('data')) {
        final list = decoded['data'] as List;
        return list.map((e) => Media.fromJson(_mapJikanToAniList(e as Map<String, dynamic>))).toList();
      }
      return [];
    } catch (e, st) {
      AppLogger.e('getTopRatedAnime failed', e, st);
      return [];
    }
  }

  @override
  Future<List<Media>> getRecentlyUpdatedAnime() async {
    try {
      final primaryUrl = '$_primary/seasons/now';
      final resp = await _getWithFallback(primaryUrl, '$_backup/anime');
      final decoded = jsonDecode(resp.body);
      if (decoded is Map && decoded.containsKey('data')) {
        final list = decoded['data'] as List;
        return list.map((e) => Media.fromJson(_mapJikanToAniList(e as Map<String, dynamic>))).toList();
      }
      return [];
    } catch (e, st) {
      AppLogger.e('getRecentlyUpdatedAnime failed', e, st);
      return [];
    }
  }

  @override
  Future<List<Media>> getMostFavoriteAnime() async {
    // Jikan doesn't provide "most favorited" directly; use top endpoint as approximation
    return getTopRatedAnime();
  }

  @override
  Future<List<Media>> getMostWatchedAnime() async {
    // Approximate with trending/top
    return getTrendingAnime();
  }

  @override
  Future<List<Media>> getUpcomingAnime() async {
    try {
      final primaryUrl = '$_primary/seasons/upcoming';
      final resp = await _getWithFallback(primaryUrl, '$_backup/anime');
      final decoded = jsonDecode(resp.body);
      if (decoded is Map && decoded.containsKey('data')) {
        final list = decoded['data'] as List;
        return list.map((e) => Media.fromJson(_mapJikanToAniList(e as Map<String, dynamic>))).toList();
      }
      return [];
    } catch (e, st) {
      AppLogger.e('getUpcomingAnime failed', e, st);
      return [];
    }
  }

  @override
  Future<Media> getAnimeDetails(int animeId) async {
    try {
      // Jikan expects id integer
      final primaryUrl = '$_primary/anime/$animeId';
      final backupUrl = '$_backup/anime/$animeId';
      final resp = await _getWithFallback(primaryUrl, backupUrl);
      final decoded = jsonDecode(resp.body);
      if (decoded is Map) {
        // Jikan returns { data: { ... } }
        if (decoded.containsKey('data')) {
          final data = decoded['data'] as Map<String, dynamic>;
          return Media.fromJson(_mapJikanToAniList(data));
        }
        // Kitsu returns data: { id, attributes: {...} }
        if (decoded.containsKey('data') && decoded['data'] is Map) {
          final attr = decoded['data']['attributes'] as Map<String, dynamic>;
          return Media.fromJson(_mapKitsuToAniList(attr));
        }
      }
      return Media();
    } catch (e, st) {
      AppLogger.e('getAnimeDetails failed', e, st);
      return Media();
    }
  }

  // -----------------------
  // Methods that require user authentication — keep using GraphQL if token present
  // -----------------------
  @override
  Future<MediaListCollection> getUserAnimeList(
      {required String type, required String status}) async {
    final auth = _getAuthContext();
    if (auth == null) {
      return MediaListCollection(lists: []);
    }
    // Use GraphQL for user-specific operations (AniList)
    try {
      final data = await _executeGraphQLOperation<Map<String, dynamic>>(
        accessToken: auth.accessToken,
        query: AnilistQueries.userAnimeListQuery,
        variables: {'userId': auth.userId, 'status': status, 'type': type},
        operationName: 'GetUserAnimeList',
      );
      return data != null
          ? MediaListCollection.fromJson(data)
          : MediaListCollection(lists: []);
    } catch (e, st) {
      AppLogger.e('getUserAnimeList(GraphQL) failed', e, st);
      return MediaListCollection(lists: []);
    }
  }

  @override
  Future<List<Media>> getFavorites() async {
    final auth = _getAuthContext();
    if (auth == null) return [];
    try {
      final data = await _executeGraphQLOperation<Map<String, dynamic>>(
        accessToken: auth.accessToken,
        query: AnilistQueries.userFavoritesQuery,
        variables: {'userId': auth.userId},
        operationName: 'GetFavorites',
      );
      return _parseMediaList(data?['User']?['favourites']?['anime']?['nodes']);
    } catch (e, st) {
      AppLogger.e('getFavorites(GraphQL) failed', e, st);
      return [];
    }
  }

  // -----------------------
  // Reuse the old GraphQL executor for authenticated mutations (token required)
  // -----------------------
  Future<T?> _executeGraphQLOperation<T>({
    required String? accessToken,
    required String query,
    Map<String, dynamic>? variables,
    bool isMutation = false,
    String operationName = '',
  }) async {
    try {
      AppLogger.d('Executing $operationName with variables: $variables');
      final client = AnilistClient.getClient(accessToken: accessToken);
      final options = isMutation
          ? MutationOptions(
              document: gql(query),
              variables: variables ?? {},
              fetchPolicy: FetchPolicy.networkOnly,
            )
          : QueryOptions(
              document: gql(query),
              variables: variables ?? {},
              fetchPolicy: FetchPolicy.cacheAndNetwork,
            );

      final result = isMutation
          ? await client.mutate(options as MutationOptions)
          : await client.query(options as QueryOptions);

      if (result.hasException) {
        AppLogger.e('GraphQL Error in $operationName', result.exception,
            StackTrace.current);
        throw AnilistServiceException(
            'GraphQL operation failed', result.exception);
      }

      AppLogger.d('$operationName completed successfully');
      return result.data as T?;
    } catch (e, stackTrace) {
      AppLogger.e('Operation $operationName failed', e, stackTrace);
      throw AnilistServiceException('Failed to execute $operationName', e);
    }
  }

  // The rest of authenticated/modifying methods reuse GraphQL when necessary.
  Future<List<Media>> toggleFavorite({
    required int animeId,
    required String? accessToken,
  }) async {
    if (accessToken == null || accessToken.isEmpty) {
      AppLogger.w('Invalid accessToken for ToggleFavorite');
      return [];
    }

    try {
      final data = await _executeGraphQLOperation<Map<String, dynamic>>(
        accessToken: accessToken,
        query: AnilistQueries.toggleFavoriteQuery,
        variables: {'animeId': animeId},
        isMutation: true,
        operationName: 'ToggleFavorite',
      );

      return _parseMediaList(data?['ToggleFavourite']?['anime']?['nodes']);
    } catch (e, st) {
      AppLogger.e('toggleFavorite(GraphQL) failed', e, st);
      return [];
    }
  }

  Future<void> saveMediaProgress({
    required int mediaId,
    required String accessToken,
    required int episodeNumber,
  }) async {
    try {
      await _executeGraphQLOperation<Map<String, dynamic>>(
        accessToken: accessToken,
        query: AnilistQueries.saveMediaProgressQuery,
        variables: {'mediaId': mediaId, 'progress': episodeNumber},
        isMutation: true,
        operationName: 'SaveMediaProgress',
      );
    } catch (e, st) {
      AppLogger.e('saveMediaProgress(GraphQL) failed', e, st);
    }
  }

  Future<bool> isAnimeFavorite({
    required int animeId,
    required String accessToken,
  }) async {
    try {
      final data = await _executeGraphQLOperation<Map<String, dynamic>>(
        accessToken: accessToken,
        query: AnilistQueries.isAnimeFavoriteQuery,
        variables: {'animeId': animeId},
        operationName: 'IsAnimeFavorite',
      );
      return data?['Media']?['isFavourite'] as bool? ?? false;
    } catch (e, st) {
      AppLogger.e('isAnimeFavorite(GraphQL) failed', e, st);
      return false;
    }
  }

  Future<void> updateAnimeStatus({
    required int mediaId,
    required String accessToken,
    required String newStatus,
  }) async {
    final validatedStatus = validateMediaListStatus(newStatus);
    if (validatedStatus == 'INVALID') {
      AppLogger.w('Invalid MediaListStatus: $newStatus for UpdateAnimeStatus');
      throw AnilistServiceException('Invalid MediaListStatus: $newStatus');
    }

    try {
      final data = await _executeGraphQLOperation<Map<String, dynamic>>(
        accessToken: accessToken,
        query: '''
        mutation UpdateAnimeStatus(\$mediaId: Int!, \$status: MediaListStatus!) {
          SaveMediaListEntry(mediaId: \$mediaId, status: \$status, progress: 0) {
            id
            mediaId
            status
            progress
            score
          }
        }
      ''',
        variables: {'mediaId': mediaId, 'status': validatedStatus},
        isMutation: true,
        operationName: 'UpdateAnimeStatus',
      );

      if (data?['SaveMediaListEntry'] == null) {
        AppLogger.e('Failed to update anime status for mediaId: $mediaId');
        throw AnilistServiceException('Failed to update anime status');
      }
    } catch (e, st) {
      AppLogger.e('updateAnimeStatus(GraphQL) failed', e, st);
    }
  }

  Future<void> deleteAnimeEntry({
    required int entryId,
    required String accessToken,
  }) async {
    try {
      final data = await _executeGraphQLOperation<Map<String, dynamic>>(
        accessToken: accessToken,
        query: '''
        mutation DeleteMediaListEntry(\$id: Int!) {
          DeleteMediaListEntry(id: \$id) {
            deleted
          }
        }
      ''',
        variables: {'id': entryId},
        isMutation: true,
        operationName: 'DeleteAnimeEntry',
      );

      if (data?['DeleteMediaListEntry']?['deleted'] != true) {
        AppLogger.e('Failed to delete anime entry with id: $entryId');
        throw AnilistServiceException('Failed to delete anime entry');
      }
    } catch (e, st) {
      AppLogger.e('deleteAnimeEntry(GraphQL) failed', e, st);
    }
  }

  Future<Map<String, dynamic>?> getAnimeStatus({
    required String accessToken,
    required int userId,
    required int animeId,
  }) async {
    try {
      final data = await _executeGraphQLOperation<Map<String, dynamic>>(
        accessToken: accessToken,
        query: '''
        query GetAnimeStatus(\$userId: Int!, \$animeId: Int!) {
          MediaList(userId: \$userId, mediaId: \$animeId) {
            id
            status
          }
        }
      ''',
        variables: {'userId': userId, 'animeId': animeId},
        operationName: 'GetAnimeStatus',
      );
      return data?['MediaList'] as Map<String, dynamic>?;
    } catch (e, st) {
      AppLogger.e('getAnimeStatus(GraphQL) failed', e, st);
      return null;
    }
  }

  String validateMediaListStatus(String status) {
    final upperStatus = status.toUpperCase();
    if (!_validStatuses.contains(upperStatus)) {
      AppLogger.w(
          'Invalid MediaListStatus: $status. Valid values: $_validStatuses');
      return 'INVALID';
    }
    return upperStatus;
  }

  // Convert AniList GraphQL results to Media objects (keeps compatibility)
  List<Media> _parseMediaList(List<dynamic>? media) =>
      media?.map((json) => Media.fromJson(json)).toList() ?? [];
}

// Provider
final anilistServiceProvider = Provider<AnilistService>((ref) {
  return AnilistService(ref);
});
