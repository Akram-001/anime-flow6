import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../view_model/auth_notifier.dart';

class AniListLoginButton extends ConsumerWidget {
  const AniListLoginButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return Card(
      margin: EdgeInsets.zero,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // AniList Logo
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey[100],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl:
                      'https://anilist.co/img/icons/android-chrome-512x512.png',
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Colors.grey[200],
                    child: Icon(
                      Icons.image,
                      color: Colors.grey[400],
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: const Color(0xFF02A9FF),
                    child: const Center(
                      child: Text(
                        'AL',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(width: 16),

            // Title and subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'AniList',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _getSubtitleText(authState),
                    style: TextStyle(
                      fontSize: 12,
                      color: authState.isLoggedIn
                          ? const Color(0xFF02A9FF)
                          : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),

            // Action button or loading indicator
            if (authState.isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFF02A9FF),
                    ),
                  ),
                ),
              )
            else if (authState.isLoggedIn)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: Color(0xFF02A9FF),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () {
                      ref.read(authProvider.notifier).logout();
                    },
                    child: const Text('Logout'),
                  ),
                ],
              )
            else
              ElevatedButton(
                onPressed: () {
                  ref.read(authProvider.notifier).login();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF02A9FF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Login'),
              ),
          ],
        ),
      ),
    );
  }

  String _getSubtitleText(AuthState authState) {
    if (authState.isLoading) {
      return 'Connecting...';
    } else if (authState.isLoggedIn && authState.user != null) {
      return 'Logged in as ${authState.user!.name}';
    } else if (authState.isLoggedIn) {
      return 'Connected to AniList';
    } else {
      return 'Track your anime and manga';
    }
  }
}
