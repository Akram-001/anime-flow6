import 'package:flutter/material.dart';
import 'package:shonenx/core/models/anilist/anilist_media_list.dart';
import 'package:shonenx/features/anime/view/widgets/card/anime_card_config.dart';

class AnimatedAnimeCard extends StatefulWidget {
  final Media? anime;
  final String tag;
  final VoidCallback? onTap;
  final AnimeCardMode mode; // Use the enum for type safety

  const AnimatedAnimeCard({
    super.key,
    required this.anime,
    required this.tag,
    this.onTap,
    this.mode = AnimeCardMode.defaults, // Default to the enum value
  });

  @override
  State<AnimatedAnimeCard> createState() => _AnimatedAnimeCardState();
}

class _AnimatedAnimeCardState extends State<AnimatedAnimeCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    // 1. Get the configuration for the current mode
    final config = cardConfigs[widget.mode]!;
    
    // 2. Get screen width once for responsive calculations
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    // 3. Use the config to determine size
    final width = isSmallScreen ? config.responsiveWidth.small : config.responsiveWidth.large;
    final height = isSmallScreen ? config.responsiveHeight.small : config.responsiveHeight.large;
    
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          width: width,
          height: height,
          margin: EdgeInsets.only(
            top: _isHovered ? 0 : 4,
            bottom: _isHovered ? 4 : 0,
          ),
          decoration: BoxDecoration(
            // 4. Use the config for the radius
            borderRadius: BorderRadius.circular(config.radius),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context)
                    .colorScheme
                    .shadow
                    .withOpacity(_isHovered ? 0.25 : 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          // 5. Use the builder function from the config to create the card content
          child: config.builder(
            anime: widget.anime,
            tag: widget.tag,
            isHovered: _isHovered,
          ),
        ),
      ),
    );
  }
}