import 'package:flutter/material.dart';

enum SettingsItemType {
  normal,
  selectable,
  toggleable,
  slider,
  dropdown,
  segmentedToggle,
}

enum SettingsItemLayout {
  auto,
  horizontal,
  vertical,
}

class ResponsiveDimensions {
  final double iconContainerSize;
  final double iconSize;
  final double spacing;
  final double titleFontSize;
  final double descriptionFontSize;
  final EdgeInsets padding;

  ResponsiveDimensions({
    required this.iconContainerSize,
    required this.iconSize,
    required this.spacing,
    required this.titleFontSize,
    required this.descriptionFontSize,
    required this.padding,
  });
}

class SettingsItem extends StatelessWidget {
  final Widget? leading;
  final Icon? icon;
  final Color? iconColor;
  final Color accent;
  final String title;
  final String description;
  final VoidCallback? onTap;
  final double roundness;

  // Selection mode
  final SettingsItemType type;
  final bool isSelected;
  final bool isInSelectionMode;

  // Toggle
  final bool? toggleValue;
  final ValueChanged<bool>? onToggleChanged;

  // Slider
  final double? sliderValue;
  final double? sliderMin;
  final double? sliderMax;
  final int? sliderDivisions;
  final String? sliderSuffix;
  final ValueChanged<double>? onSliderChanged;

  // Dropdown
  final String? dropdownValue;
  final List<String>? dropdownItems;
  final ValueChanged<String?>? onDropdownChanged;

  // Segmented
  final int? segmentedSelectedIndex;
  final List<Widget>? segmentedOptions;
  final List<String>? segmentedLabels;
  final ValueChanged<int>? onSegmentedChanged;

  // Responsive
  final bool isCompact;

  // Custom trailing
  final List<Widget>? trailingWidgets;

  // Layout
  final SettingsItemLayout layoutType;

  const SettingsItem({
    super.key,
    this.icon,
    this.iconColor,
    this.accent = Colors.black, // ✅ صححت هنا
    required this.title,
    required this.description,
    this.leading,
    this.onTap,
    this.roundness = 12,
    this.type = SettingsItemType.normal,
    this.isSelected = false,
    this.isInSelectionMode = false,
    this.toggleValue,
    this.onToggleChanged,
    this.sliderValue,
    this.sliderMin,
    this.sliderMax,
    this.sliderDivisions,
    this.sliderSuffix,
    this.onSliderChanged,
    this.dropdownValue,
    this.dropdownItems,
    this.onDropdownChanged,
    this.segmentedSelectedIndex,
    this.segmentedOptions,
    this.segmentedLabels,
    this.onSegmentedChanged,
    this.isCompact = false,
    this.trailingWidgets,
    this.layoutType = SettingsItemLayout.auto,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: leading ??
          (icon != null
              ? IconTheme(
                  data: IconThemeData(
                    color: iconColor ?? accent,
                  ),
                  child: icon!,
                )
              : null),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: description.isNotEmpty ? Text(description) : null,
      onTap: onTap,
      trailing: _buildTrailing(),
    );
  }

  Widget? _buildTrailing() {
    switch (type) {
      case SettingsItemType.toggleable:
        return Switch(
          value: toggleValue ?? false,
          onChanged: onToggleChanged,
          activeColor: accent,
        );
      case SettingsItemType.slider:
        return SizedBox(
          width: 150,
          child: Slider(
            value: sliderValue ?? 0,
            min: sliderMin ?? 0,
            max: sliderMax ?? 100,
            divisions: sliderDivisions,
            label: "${sliderValue ?? 0}${sliderSuffix ?? ''}",
            onChanged: onSliderChanged,
          ),
        );
      case SettingsItemType.dropdown:
        return DropdownButton<String>(
          value: dropdownValue,
          items: dropdownItems
              ?.map((item) => DropdownMenuItem(
                    value: item,
                    child: Text(item),
                  ))
              .toList(),
          onChanged: onDropdownChanged,
        );
      default:
        return trailingWidgets != null
            ? Row(mainAxisSize: MainAxisSize.min, children: trailingWidgets!)
            : null;
    }
  }
}