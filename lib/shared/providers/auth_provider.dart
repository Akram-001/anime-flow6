import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/core/anilist/services/auth_service.dart';

final anilistAuthServiceProvider = Provider((ref) => AniListAuthService());
