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

class SettingsItem extends StatelessWidget {
  final Widget? leading;
  final Icon? icon;
  final Color? iconColor;
  final Color accent;
  final String title;
  final String description;
  final VoidCallback? onTap;
  final double roundness;

  // Selection
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

  // Extra
  final bool isCompact;
  final List<Widget>? trailingWidgets;
  final SettingsItemLayout layoutType;

  const SettingsItem({
    super.key,
    this.icon,
    this.iconColor,
    this.accent, // ✅ صار إجباري
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
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(roundness),
      ),
      child: ListTile(
        leading: _buildIcon(),
        title: Text(title),
        subtitle: description.isNotEmpty ? Text(description) : null,
        trailing: _buildTrailing(),
        onTap: onTap,
      ),
    );
  }

  Widget _buildIcon() {
    if (icon != null) {
      return Container(
        decoration: BoxDecoration(
          color: (iconColor ?? accent).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.all(8),
        child: Icon(
          icon!.icon,
          color: iconColor ?? accent,
        ),
      );
    }
    return leading ?? const SizedBox.shrink();
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
            label:
                '${(sliderValue ?? 0).toStringAsFixed(sliderDivisions != null ? 0 : 1)}${sliderSuffix ?? ''}',
            onChanged: onSliderChanged,
            activeColor: accent,
          ),
        );
      case SettingsItemType.dropdown:
        return DropdownButton<String>(
          value: dropdownValue,
          items: dropdownItems
              ?.map((e) => DropdownMenuItem(
                    value: e,
                    child: Text(e),
                  ))
              .toList(),
          onChanged: onDropdownChanged,
        );
      default:
        return trailingWidgets != null
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: trailingWidgets!,
              )
            : null;
    }
  }
}