import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/core/anilist/services/anilist_service.dart';
import 'package:shonenx/core/repositories/anilist_repository.dart';
import 'package:shonenx/core/repositories/anime_repository.dart';
import 'package:shonenx/core/repositories/mal_repository.dart';
import 'package:shonenx/core/services/auth_provider_enum.dart';
import 'package:shonenx/features/auth/view_model/auth_notifier.dart';

final animeRepositoryProvider = Provider<AnimeRepository>((ref) {
  final auth = ref.watch(authProvider);

  if (auth.authPlatform == AuthPlatform.mal) {
    return MalRepository();
  } else {
    return AniListRepository(ref.read(anilistServiceProvider));
  }
});
