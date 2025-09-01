import 'package:flutter/material.dart';
import 'package:shonenx/features/settings/widgets/settings_item.dart';

enum SettingsSectionLayout {
  list,
  grid,
}

class SettingsSection extends StatelessWidget {
  final String title;
  final Color titleColor;
  final VoidCallback? onTap;
  final List<SettingsItem> items;
  final double roundness;

  // Grid layout properties
  final SettingsSectionLayout layout;
  final int gridColumns;
  final double gridCrossAxisSpacing;
  final double gridMainAxisSpacing;
  final double gridChildAspectRatio;

  const SettingsSection({
    super.key,
    required this.title,
    required this.titleColor,
    this.onTap,
    required this.items,
    this.roundness = 12,
    this.layout = SettingsSectionLayout.list,
    this.gridColumns = 2,
    this.gridCrossAxisSpacing = 8.0,
    this.gridMainAxisSpacing = 8.0,
    this.gridChildAspectRatio = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title
        Padding(
          padding: const EdgeInsets.only(left: 4.0, bottom: 16.0),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: titleColor,
            ),
          ),
        ),

        // Settings items
        _buildItemsLayout(),
      ],
    );
  }

  Widget _buildItemsLayout() {
    switch (layout) {
      case SettingsSectionLayout.grid:
        return _buildGridLayout();
      case SettingsSectionLayout.list:
      default:
        return _buildListLayout();
    }
  }

  Widget _buildListLayout() {
    return Column(
      children: [
        ...items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;

          return Padding(
            padding: EdgeInsets.only(
              bottom: index < items.length - 1 ? 5.0 : 0.0,
            ),
            child: _buildSettingsItem(item, false),
          );
        }),
      ],
    );
  }

  Widget _buildGridLayout() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: gridColumns,
        crossAxisSpacing: gridCrossAxisSpacing,
        mainAxisSpacing: gridMainAxisSpacing,
        childAspectRatio: gridChildAspectRatio,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return _buildSettingsItem(items[index], true);
      },
    );
  }

  Widget _buildSettingsItem(SettingsItem item, bool isInGrid) {
    return SettingsItem(
      icon: item.icon,
      leading: item.leading,
      iconColor: item.iconColor,
      accent: item.accent,
      title: item.title,
      description: item.description,
      onTap: item.onTap,
      roundness: roundness,
      type: item.type,
      isSelected: item.isSelected,
      isInSelectionMode: item.isInSelectionMode,
      toggleValue: item.toggleValue,
      onToggleChanged: item.onToggleChanged,
      sliderValue: item.sliderValue,
      sliderMin: item.sliderMin,
      sliderMax: item.sliderMax,
      sliderDivisions: item.sliderDivisions,
      sliderSuffix: item.sliderSuffix,
      onSliderChanged: item.onSliderChanged,
      dropdownValue: item.dropdownValue,
      dropdownItems: item.dropdownItems,
      onDropdownChanged: item.onDropdownChanged,
      isCompact: isInGrid,
      segmentedSelectedIndex: item.segmentedSelectedIndex,
      segmentedOptions: item.segmentedOptions,
      segmentedLabels: item.segmentedLabels,
      onSegmentedChanged: item.onSegmentedChanged,
      trailingWidgets: item.trailingWidgets,
      layoutType: item.layoutType,
    );
  }
}
