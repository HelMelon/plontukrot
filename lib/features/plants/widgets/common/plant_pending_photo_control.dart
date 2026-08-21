import 'package:flutter/material.dart';
import 'package:plontukrot/l10n/app_localizations.dart';

import '../../../../core/theme/theme_context.dart';

/// Icon-only pending photo indicator (no image preview).
class PlantPendingPhotoControl extends StatelessWidget {
  final bool hasPhoto;
  final VoidCallback onPick;

  const PlantPendingPhotoControl({
    super.key,
    required this.hasPhoto,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final typography = context.typography;
    final label = hasPhoto ? l10n.plantPhotoAttached : l10n.plantPhotoAdd;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: ExcludeSemantics(
        child: Icon(
          hasPhoto
              ? context.icons.checkCircleOutlined
              : context.icons.addPhotoOutlined,
          color: colors.icon,
        ),
      ),
      title: Text(
        label,
        style: typography.bodyEmphasis,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      onTap: onPick,
    );
  }
}
