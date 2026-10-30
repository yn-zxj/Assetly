import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../data/item_icons.dart';

/// Renders an item or space icon: Fluent 3D art when the value maps to the
/// bundled catalog, otherwise the legacy emoji character.
class ItemIconArt extends StatelessWidget {
  const ItemIconArt(this.icon, {super.key, this.size = 24});

  final String icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    final slug = itemIconSlug(icon);
    if (slug == null) {
      return Text(icon, style: TextStyle(fontSize: size * .8, height: 1.1));
    }
    return Image.asset(
      itemIconAsset(slug),
      width: size,
      height: size,
      filterQuality: FilterQuality.medium,
      cacheWidth: (size * MediaQuery.devicePixelRatioOf(context)).round(),
      errorBuilder: (context, error, stack) => Icon(
        LucideIcons.package,
        size: size * .8,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}
