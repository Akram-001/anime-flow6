import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:shonenx/core/models/anime/episode_model.dart';
import 'package:shonenx/core/models/anime/source_model.dart';
import 'package:shonenx/core/registery/anime_source_registery_provider.dart';
import 'package:shonenx/core/sources/anime/anime_provider.dart';
import 'package:shonenx/core/utils/app_logger.dart';
import 'package:shonenx/utils/extractors.dart' as extractor;
import 'package:shonenx/features/anime/view_model/playerStateProvider.dart';

@immutable
class EpisodeDataState {
  final List<EpisodeDataModel> episodes;
  final List<Source> sources;
  final List<Subtitle> subtitles;
  final List<Map<String, dynamic>> qualityOptions;

  final int? selectedQualityIdx;
  final int? selectedSourceIdx;
  final int? selectedEpisodeIdx;
  final int? selectedSubtitleIdx;
  final String selectedCategory;
  final String? selectedServer;

  final bool dubSubSupport;
  final bool episodesLoading;
  final bool sourceLoading;
  final String? error;

  const EpisodeDataState({
    this.episodes = const [],
    this.sources = const [],
    this.subtitles = const [],
    this.qualityOptions = const [],
    this.selectedQualityIdx,
    this.selectedSourceIdx,
    this.selectedEpisodeIdx,
    this.selectedSubtitleIdx,
    this.selectedCategory = 'sub',
    this.dubSubSupport = false,
    this.selectedServer,
    this.episodesLoading = true,
    this.sourceLoading = false,
    this.error,
  });

  EpisodeDataState copyWith({
    List<EpisodeDataModel>? episodes,
    List<Source>? sources,
    List<Subtitle>? subtitles,
    List<Map<String, dynamic>>? qualityOptions,
    int? selectedQualityIdx,
    int? selectedSourceIdx,
    int? selectedEpisodeIdx,
    int? selectedSubtitleIdx,
    String? selectedCategory,
    bool? dubSubSupport,
    String? selectedServer,
    bool? episodesLoading,
    bool? sourceLoading,
    String? error,
  }) {
    return EpisodeDataState(
      episodes: episodes ?? this.episodes,
      sources: sources ?? this.sources,
      subtitles: subtitles ?? this.subtitles,
      qualityOptions: qualityOptions ?? this.qualityOptions,
      selectedQualityIdx: selectedQualityIdx ?? this.selectedQualityIdx,
      selectedSourceIdx: selectedSourceIdx ?? this.selectedSourceIdx,
      selectedEpisodeIdx: selectedEpisodeIdx ?? this.selectedEpisodeIdx,
      selectedSubtitleIdx: selectedSubtitleIdx ?? this.selectedSubtitleIdx,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      dubSubSupport: dubSubSupport ?? this.dubSubSupport,
      selectedServer: selectedServer ?? this.selectedServer,
      episodesLoading: episodesLoading ?? this.episodesLoading,
      sourceLoading: sourceLoading ?? this.sourceLoading,
      error: error ?? this.error,
    );
  }
}

// The Notifier for fetching and holding episode data
class EpisodeDataNotifier extends AutoDisposeNotifier<EpisodeDataState> {
  AnimeProvider get _animeProvider => ref.read(selectedAnimeProvider)!;

  @override
  EpisodeDataState build() {
    return const EpisodeDataState();
  }

  Future<void> fetchEpisodes({
    required String animeId,
    int initialEpisodeIdx = 0,
    Duration startAt = Duration.zero,
  }) async {
    state = state.copyWith(episodesLoading: true, error: null);
    try {
      final episodes =
          (await _animeProvider.getEpisodes(animeId)).episodes ?? [];
      final servers = _animeProvider.getSupportedServers();
      final bool hasDubSubSupport = _animeProvider.getDubSubParamSupport();

      state = state.copyWith(
        episodesLoading: false,
        episodes: episodes,
        selectedServer: servers.isNotEmpty ? servers.last : null,
        dubSubSupport: hasDubSubSupport,
      );

      if (episodes.isNotEmpty) {
        await changeEpisode(initialEpisodeIdx, startAt: startAt);
      } else {
        state = state.copyWith(error: "No episodes found for this anime.");
      }
    } catch (e) {
      state = state.copyWith(
          episodesLoading: false, error: "Failed to fetch episodes: $e");
    }
  }

  // --- ADD THIS NEW METHOD ---
  Future<void> toggleDubSub() async {
    // Safety check in case this is called when not supported
    if (!state.dubSubSupport) return;

    // Determine the new category
    final newCategory = state.selectedCategory == 'sub' ? 'dub' : 'sub';

    // Get the current playback position to resume smoothly
    final currentPosition = ref.read(playerStateProvider).position;

    // Update the state with the new category
    state = state.copyWith(selectedCategory: newCategory);

    // Re-fetch the stream data for the new category
    await _fetchStreamData(startAt: currentPosition);
  }

  Future<void> changeEpisode(int episodeIdx,
      {Duration startAt = Duration.zero}) async {
    if (episodeIdx < 0 || episodeIdx >= state.episodes.length) {
      state = state.copyWith(error: "Invalid episode selected.");
      return;
    }
    state = state.copyWith(selectedEpisodeIdx: episodeIdx);
    await _fetchStreamData(startAt: startAt);
  }

  Future<void> updateCategoryAndRefresh(String category) async {
    state = state.copyWith(selectedCategory: category);
    await _fetchStreamData();
  }

  Future<void> updateServerAndRefresh(String server) async {
    state = state.copyWith(selectedServer: server);
    await _fetchStreamData();
  }

  Future<void> _fetchStreamData({Duration startAt = Duration.zero}) async {
    AppLogger.d(
        'Fetching stream data for episode index ${state.selectedEpisodeIdx}');
    if (state.selectedEpisodeIdx == null) {
      return;
    }

    state = state.copyWith(sourceLoading: true, error: null);
    try {
      final episode = state.episodes[state.selectedEpisodeIdx!];
      AppLogger.d(episode.id);
      final data = await _animeProvider.getSources(
        episode.id ?? '',
        episode.id ?? '',
        state.selectedServer,
        state.selectedCategory,
      );

      state = state.copyWith(
        sources: data.sources,
        subtitles: data.tracks,
        selectedSourceIdx: data.sources.isNotEmpty ? 0 : null,
      );

      // After fetching, immediately load and play the first source.
      if (state.selectedSourceIdx != null) {
        await _loadAndPlaySource(state.selectedSourceIdx!, startAt: startAt);
      } else {
        state =
            state.copyWith(sourceLoading: false, error: "No sources found.");
      }
    } catch (e) {
      state = state.copyWith(
          sourceLoading: false, error: "Failed to load stream: $e");
    }
  }

  Future<void> changeSubtitle(int subtitleIdx) async {
    final subtitle = state.subtitles[subtitleIdx];
    if (subtitle.url == null) return;
    await ref
        .read(playerStateProvider.notifier)
        .setSubtitle(SubtitleTrack.uri(state.subtitles[subtitleIdx].url!));
    state = state.copyWith(selectedSubtitleIdx: subtitleIdx);
  }

  // --- ADD THIS NEW METHOD ---
  Future<void> changeQuality(int qualityIdx) async {
    if (qualityIdx < 0 || qualityIdx >= state.qualityOptions.length) return;

    // 1. Get the current playback position from the other provider
    final currentPosition = ref.read(playerStateProvider).position;
    final newQualityUrl = state.qualityOptions[qualityIdx]['url'];

    if (newQualityUrl == null) {
      state = state.copyWith(error: "Selected quality has an invalid URL.");
      return;
    }

    // 2. Update our own state to reflect the new selection
    state = state.copyWith(selectedQualityIdx: qualityIdx);

    // 3. Command the player control provider to open the new source
    ref.read(playerStateProvider.notifier).open(newQualityUrl, currentPosition);
  }

  // --- ADD THIS NEW METHOD ---
  Future<void> changeSource(int sourceIdx) async {
    if (sourceIdx < 0 ||
        sourceIdx >= state.sources.length ||
        state.selectedSourceIdx == sourceIdx) return;

    final currentPosition = ref.read(playerStateProvider).position;
    state = state.copyWith(selectedSourceIdx: sourceIdx);
    await _loadAndPlaySource(sourceIdx, startAt: currentPosition);
  }

  Future<void> _loadAndPlaySource(int sourceIndex,
      {Duration startAt = Duration.zero}) async {
    state = state.copyWith(sourceLoading: true);
    try {
      final source = state.sources[sourceIndex];
      final qualities = await _extractQualitiesFromSource(source);

      state = state.copyWith(
        qualityOptions: qualities,
        selectedQualityIdx: qualities.isNotEmpty ? 0 : null,
      );

      final urlToPlay =
          qualities.isNotEmpty ? qualities.first['url'] : source.url;

      if (urlToPlay != null) {
        ref.read(playerStateProvider.notifier).open(urlToPlay, startAt);
      } else {
        state =
            state.copyWith(error: "No playable URL in the selected source.");
      }
    } catch (e) {
      state = state.copyWith(error: "Failed to load source: $e");
    } finally {
      state = state.copyWith(sourceLoading: false);
    }
  }

  // Helper method to extract qualities from a given source
  Future<List<Map<String, dynamic>>> _extractQualitiesFromSource(
      Source source) async {
    if (source.url == null) return [];

    try {
      // If the source is M3U8, extract qualities. Otherwise, treat it as a single source.
      if (source.isM3U8) {
        return await extractor.extractQualities(source.url!, {});
      } else {
        return [
          {'quality': source.quality ?? 'Default', 'url': source.url}
        ];
      }
    } catch (e) {
      // Fallback if extraction fails
      return [
        {'quality': source.quality ?? 'Default', 'url': source.url}
      ];
    }
  }
}

// The final provider for our data layer
final episodeDataProvider =
    AutoDisposeNotifierProvider<EpisodeDataNotifier, EpisodeDataState>(
        () => EpisodeDataNotifier());
