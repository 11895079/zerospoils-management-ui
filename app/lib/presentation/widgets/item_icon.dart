library;

import 'package:flutter/material.dart';
import '../../domain/models/item_model.dart';
import '../../core/utils/item_icon_library.dart';

/// Consistent item icon widget for use across inventory list, detail, and edit screens
class ItemIcon extends StatelessWidget {
  final String itemName;
  final ItemCategory category;
  final double size;
  final Color? color;
  final bool showBackground;
  final BorderRadius? borderRadius;

  const ItemIcon({
    super.key,
    required this.itemName,
    required this.category,
    this.size = 24,
    this.color,
    this.showBackground = false,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final icon = ItemIconLibrary.getIconForItem(itemName, category: category);
    final iconColor = color ?? Theme.of(context).primaryColor;

    Widget iconWidget = Icon(icon, size: size, color: iconColor);

    if (showBackground) {
      final bgRadius = borderRadius ?? BorderRadius.circular(8);
      iconWidget = Container(
        width: size + 12,
        height: size + 12,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          borderRadius: bgRadius,
        ),
        child: Center(child: iconWidget),
      );
    }

    return iconWidget;
  }
}

/// Displays both icon and category label for items in lists
class ItemIconWithLabel extends StatelessWidget {
  final String itemName;
  final ItemCategory category;
  final double iconSize;
  final TextStyle? labelStyle;
  final Axis direction;

  const ItemIconWithLabel({
    super.key,
    required this.itemName,
    required this.category,
    this.iconSize = 20,
    this.labelStyle,
    this.direction = Axis.horizontal,
  });

  @override
  Widget build(BuildContext context) {
    final icon = ItemIcon(
      itemName: itemName,
      category: category,
      size: iconSize,
      showBackground: true,
    );

    final label = Text(
      category.displayName,
      style: labelStyle ?? Theme.of(context).textTheme.labelSmall,
    );

    if (direction == Axis.horizontal) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [icon, const SizedBox(width: 8), label],
      );
    } else {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [icon, const SizedBox(height: 4), label],
      );
    }
  }
}
