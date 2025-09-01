import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shonenx/features/settings/widgets/settings_item.dart';
import 'package:shonenx/features/settings/widgets/settings_section.dart';
import 'package:go_router/go_router.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          leading: IconButton.filledTonal(
              onPressed: () => context.pop(),
              icon: const Icon(Iconsax.arrow_left_2)),
          title: const Text('Settings'),
          forceMaterialTransparency: true,
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: ListView(
            children: [
              // 🟦 Account Section (Blue)
              SettingsSection(
                  title: 'Account',
                  titleColor: Colors.blue,
                  onTap: () {},
                  items: [
                    SettingsItem(
                      icon: const Icon(Iconsax.user, color: Colors.blue),
                      iconColor: Colors.blue,
                      title: 'Profile Settings',
                      description: 'AniList integration, account preferences',
                      onTap: () => context.push('/settings/account'),
                    ),
                  ]),
              const SizedBox(height: 10),

              // 🟥 Content & Playback Section (Red)
              SettingsSection(
                  title: 'Content & Playback',
                  titleColor: Colors.red,
                  onTap: () {},
                  items: [
                    SettingsItem(
                      icon: const Icon(Icons.source_outlined,
                          color: Colors.red),
                      iconColor: Colors.red,
                      title: 'Anime Sources',
                      description: 'Manage anime content providers',
                      onTap: () => context.push('/settings/anime-sources'),
                    ),
                    SettingsItem(
                      icon: const Icon(Iconsax.video_play, color: Colors.red),
                      iconColor: Colors.red,
                      title: 'Video Player',
                      description: 'Manage video player settings',
                      onTap: () => context.push('/settings/player'),
                    ),
                  ]),
              const SizedBox(height: 10),

              // 🟩 Appearance Section (Green)
              SettingsSection(
                  title: 'Appearance',
                  titleColor: Colors.green,
                  onTap: () {},
                  items: [
                    SettingsItem(
                      icon: const Icon(Iconsax.paintbucket,
                          color: Colors.green),
                      iconColor: Colors.green,
                      title: 'Theme Settings',
                      description: 'Customize app colors and appearance',
                      onTap: () => context.push('/settings/theme'),
                    ),
                    SettingsItem(
                      icon: const Icon(Iconsax.mobile, color: Colors.green),
                      iconColor: Colors.green,
                      title: 'UI Settings',
                      description: 'Customize the interface and layout',
                      onTap: () => context.push('/settings/ui'),
                    ),
                  ]),
              const SizedBox(height: 10),

              // 🟧 Support Section (Orange)
              SettingsSection(
                  title: 'Support',
                  titleColor: Colors.orange,
                  onTap: () {},
                  items: [
                    SettingsItem(
                      icon: const Icon(Iconsax.info_circle,
                          color: Colors.orange),
                      iconColor: Colors.orange,
                      title: 'About',
                      description: 'App information and licenses',
                      onTap: () => context.push('/settings/about'),
                    ),
                  ]),
              const SizedBox(height: 20)
            ],
          ),
        ));
  }
}