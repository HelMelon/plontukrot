import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import 'package:plontukrot/l10n/app_localizations.dart';

import '../../../../core/theme/theme_context.dart';
import '../../../../core/widgets/focusable_tap.dart';
import '../../../../core/season/fertilizing_season_controller.dart';
import '../../../../models/fertilizing_frequency.dart';
import '../../../../models/plant.dart';
import '../../pages/plant_details_page.dart';
import '../common/plant_image.dart';
import '../common/quarantine_badge.dart';

extension CapitalizeString on String {
  String toTitleCase() {
    if (trim().isEmpty) return '';

    return split(' ').where((word) => word.isNotEmpty).map((word) {
      if (word.length == 1) return word.toUpperCase();
      return '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}';
    }).join(' ');
  }
}

class PlantCard extends StatelessWidget {
  final Plant plant;
  final bool isSelected;
  final bool preferSpeciesAsTitle;
  final int propagationBatchCount;
  final double? moisture;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const PlantCard({
    super.key,
    required this.plant,
    this.isSelected = false,
    this.preferSpeciesAsTitle = false,
    this.propagationBatchCount = 0,
    this.moisture,
    this.onTap,
    this.onLongPress,
  });

  static const double _mobileDividerHeight = 16;

  static bool isLandscape(BuildContext context) {
    return MediaQuery.orientationOf(context) == Orientation.landscape;
  }

  /// Grid cell height: compact mobile layout, or wide layout in landscape.
  static double? gridMainAxisExtent(
    BuildContext context, {
    required double cellWidth,
    required bool compactGrid,
  }) {
    if (compactGrid) {
      return mobileGridMainAxisExtent(context, cellWidth);
    }
    if (isLandscape(context)) {
      return cellWidth + _wideLandscapeFooterHeight(context);
    }
    return null;
  }

  /// Mobile grid cell height: square photo + text (2+2 lines) + care stats.
  static double mobileGridMainAxisExtent(
    BuildContext context,
    double cellWidth,
  ) {
    return cellWidth + _mobileFooterHeight(context);
  }

  static double _mobileFooterHeight(BuildContext context) {
    return _mobileTextBlockHeight(context) + _mobileStatsBlockHeight(context);
  }

  static double _mobileTextBlockHeight(BuildContext context) {
    final spacing = context.spacing;
    final padding = _mobileFooterPadding(spacing);
    return padding.vertical +
        _mobileNicknameBlockHeight(context) +
        spacing.xxs +
        _mobileSpeciesBlockHeight(context);
  }

  static double _mobileNicknameBlockHeight(BuildContext context) {
    return _twoLineBlockHeight(
      _mobileNicknameStyle(context.typography, context.colors.primary),
    );
  }

  static double _mobileSpeciesBlockHeight(BuildContext context) {
    return _twoLineBlockHeight(
      _mobileSpeciesStyle(context.typography, context.colors.textSecondary),
    );
  }

  static TextStyle _mobileNicknameStyle(
    AppTypographyTokens typography,
    Color color,
  ) {
    return typography.bodyEmphasis.copyWith(
      fontWeight: FontWeight.bold,
      letterSpacing: -0.3,
      color: color,
      height: 1.2,
    );
  }

  static TextStyle _mobileSpeciesStyle(
    AppTypographyTokens typography,
    Color color,
  ) {
    return typography.bodySmall.copyWith(
      color: color,
      height: 1.2,
    );
  }

  static double _twoLineBlockHeight(TextStyle style) {
    return _textLineHeight(style, style.height ?? 1.2) * 2;
  }

  static EdgeInsets _mobileFooterPadding(AppSpacingTokens spacing) {
    return EdgeInsets.all(spacing.sm);
  }

  static double _mobileStatsBlockHeight(BuildContext context) {
    final spacing = context.spacing;
    final statRowHeight = _statRowHeight(context);
    return _mobileDividerHeight + statRowHeight * 3 + spacing.xxs * 2;
  }

  static double _wideLandscapeFooterHeight(BuildContext context) {
    final spacing = context.spacing;
    final typography = context.typography;
    final titleHeight = _twoLineBlockHeight(
      typography.bodyEmphasis.copyWith(
        fontWeight: FontWeight.bold,
        height: 1.2,
      ),
    );
    final subtitleHeight = _twoLineBlockHeight(
      typography.bodySmall.copyWith(height: 1.2),
    );
    return spacing.sm * 2 +
        titleHeight +
        spacing.xxs +
        subtitleHeight +
        _mobileStatsBlockHeight(context);
  }

  static double _statRowHeight(BuildContext context) {
    final typography = context.typography;
    final dimensions = context.dimensions;
    return _textLineHeight(typography.caption, 1.1)
        .clamp(dimensions.iconSm, double.infinity);
  }

  static double _textLineHeight(TextStyle style, double heightFactor) {
    return (style.fontSize ?? 14) * heightFactor;
  }

  String _dateLabel(DateTime? date, String empty) {
    if (date == null) return empty;
    return DateFormat('d.MM').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final radii = context.radii;
    final spacing = context.spacing;
    final typography = context.typography;
    final dimensions = context.dimensions;
    final imageUrl = plant.listImageUrl;
    final fullUrl = plant.imageUrl?.trim();
    final hasImage = imageUrl != null;
    final isMobile = MediaQuery.sizeOf(context).width < 600;
    final useColumnStats = isMobile || isLandscape(context);
    final emptyDate = l10n.profileEmDash;
    final fertilizedLabel = _dateLabel(plant.lastFertilizedAt, emptyDate);
    final wateredLabel = _dateLabel(plant.lastWateredAt, emptyDate);
    final batchesLabel = '$propagationBatchCount';
    final quarantineSeason = plant.quarantineUntil == null
        ? null
        : FertilizingSeasonController.instance.settings
            .growthSeasonForDate(plant.quarantineUntil!);
    final fertilizingOverdue = isFertilizingOverdue(
      frequencyDays: plant.fertilizingFrequencyDays,
      lastFertilizedAt: plant.lastFertilizedAt,
      createdAt: plant.createdAt,
      isArchived: plant.isArchived,
      quarantineUntil: plant.quarantineUntil,
      quarantineSeason: quarantineSeason,
    );
    final fertilizingDueAt = fertilizingOverdue
        ? nextFertilizingDate(
            frequencyDays: plant.fertilizingFrequencyDays,
            lastFertilizedAt: plant.lastFertilizedAt,
            createdAt: plant.createdAt,
            quarantineUntil: plant.quarantineUntil,
            quarantineSeason: quarantineSeason,
          )
        : null;
    final fertilizingStatLabel = fertilizingOverdue && fertilizingDueAt != null
        ? _dateLabel(fertilizingDueAt, emptyDate)
        : fertilizedLabel;

    final speciesBase =
        (plant.species.isEmpty ? l10n.commonUntitled : plant.species)
            .toTitleCase();
    final cultivars = plant.cultivarsDisplay.toTitleCase();
    final species =
        cultivars.isEmpty ? speciesBase : '$speciesBase · $cultivars';
    final nickname = plant.nickname.toTitleCase();
    final hasNickname = nickname.trim().isNotEmpty;
    final showSpeciesOnTop = preferSpeciesAsTitle || !hasNickname;
    final title = showSpeciesOnTop ? species : nickname;
    final subtitle =
        showSpeciesOnTop ? (hasNickname ? nickname : null) : species;
    final mobileNicknameStyle =
        PlantCard._mobileNicknameStyle(typography, colors.primary);
    final mobileSpeciesStyle =
        PlantCard._mobileSpeciesStyle(typography, colors.textSecondary);
    final semanticsLabel = [
      if (hasNickname) nickname,
      species,
      if (plant.isInQuarantine()) l10n.a11yPlantQuarantine,
      if (fertilizingOverdue && fertilizingDueAt != null)
        l10n.a11yFertilizingDue(_dateLabel(fertilizingDueAt, emptyDate))
      else
        l10n.a11yLastFertilized(fertilizedLabel),
      l10n.a11yLastWatered(wateredLabel),
      l10n.a11yPropagationBatches(propagationBatchCount),
    ].join('. ');

    return Semantics(
      button: true,
      selected: isSelected,
      label: semanticsLabel,
      child: FocusableTap(
        borderRadius: BorderRadius.circular(radii.md),
        onTap: onTap ??
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => PlantDetailsPage(plantId: plant.id)),
              );
            },
        onLongPress: onLongPress,
        child: Container(
          decoration: BoxDecoration(
            color: colors.modal,
            borderRadius: BorderRadius.circular(radii.md),
            border: Border.all(
              color: isSelected
                  ? colors.primary
                  : colors.outline.withValues(alpha: 0.3),
              width: isSelected ? 3 : 1,
            ),
            boxShadow: context.shadows.card,
          ),
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(radii.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AspectRatio(
                      aspectRatio: 1.0,
                      child: hasImage
                          ? PlantImage(
                              imageUrl: imageUrl,
                              fallbackUrl: fullUrl,
                              fit: BoxFit.cover,
                              alignment: Alignment.center,
                              memCacheWidth: 600,
                              excludeFromSemantics: true,
                              placeholder: const _PlantAssetPlaceholder(),
                              errorWidget: const _PlantAssetPlaceholder(),
                            )
                          : const _PlantAssetPlaceholder(),
                    ),
                    if (isMobile)
                      SizedBox(
                        height: _mobileFooterHeight(context),
                        child: ClipRect(
                          child: SingleChildScrollView(
                            physics: const NeverScrollableScrollPhysics(),
                            child: Padding(
                              padding: _mobileFooterPadding(spacing),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    height: _mobileNicknameBlockHeight(context),
                                    child: Align(
                                      alignment: Alignment.topLeft,
                                      child: Text(
                                        hasNickname ? nickname : '',
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: mobileNicknameStyle,
                                      ),
                                    ),
                                  ),
                                  spacing.vXxs,
                                  SizedBox(
                                    height: _mobileSpeciesBlockHeight(context),
                                    child: Align(
                                      alignment: Alignment.topLeft,
                                      child: Text(
                                        species,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: mobileSpeciesStyle,
                                      ),
                                    ),
                                  ),
                                  Divider(
                                    height: _mobileDividerHeight,
                                    color: colors.primary,
                                    thickness: 1,
                                  ),
                                  ExcludeSemantics(
                                    child: _buildStatsColumn(
                                      context,
                                      fertilizingStatLabel: fertilizingStatLabel,
                                      wateredLabel: wateredLabel,
                                      batchesLabel: batchesLabel,
                                      fertilizingOverdue: fertilizingOverdue,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      )
                    else
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.all(spacing.sm),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Text(
                                      title,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: typography.bodyEmphasis.copyWith(
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: -0.3,
                                        color: colors.primary,
                                        height: 1.2,
                                      ),
                                    ),
                                    if (subtitle != null) ...[
                                      spacing.vXxs,
                                      Text(
                                        subtitle,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: typography.bodySmall.copyWith(
                                          color: colors.textSecondary,
                                          height: 1.2,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Divider(
                                    height: useColumnStats
                                        ? _mobileDividerHeight
                                        : null,
                                    color: colors.primary,
                                    thickness: 1,
                                  ),
                                  ExcludeSemantics(
                                    child: useColumnStats
                                        ? _buildStatsColumn(
                                            context,
                                            fertilizingStatLabel:
                                                fertilizingStatLabel,
                                            wateredLabel: wateredLabel,
                                            batchesLabel: batchesLabel,
                                            fertilizingOverdue:
                                                fertilizingOverdue,
                                          )
                                        : Row(
                                            children: [
                                              Expanded(
                                                child: _StatChip(
                                                  icon: context.icons.fertilizing,
                                                  label: fertilizingStatLabel,
                                                  iconColor: fertilizingOverdue
                                                      ? colors.error
                                                      : null,
                                                  labelColor: fertilizingOverdue
                                                      ? colors.error
                                                      : null,
                                                ),
                                              ),
                                              spacing.hXxs,
                                              Expanded(
                                                child: _StatChip(
                                                  icon: context.icons.watering,
                                                  label: wateredLabel,
                                                ),
                                              ),
                                              spacing.hXxs,
                                              Expanded(
                                                child: _StatChip(
                                                  hugeIcon:
                                                      context.icons.propagations,
                                                  label: batchesLabel,
                                                ),
                                              ),
                                            ],
                                          ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (fertilizingOverdue)
                Positioned(
                  top: isSelected ? null : spacing.xs,
                  bottom: isSelected ? spacing.xs : null,
                  right: spacing.xs,
                  child: ExcludeSemantics(
                    child: _FertilizingOverdueBadge(
                      tooltip: fertilizingDueAt != null
                          ? l10n.a11yFertilizingDue(
                              _dateLabel(fertilizingDueAt, emptyDate),
                            )
                          : l10n.a11yFertilizingOverdue,
                    ),
                  ),
                ),
              if (isSelected)
                Positioned(
                  top: spacing.xs,
                  right: spacing.xs,
                  child: ExcludeSemantics(
                    child: CircleAvatar(
                      radius: 14,
                      backgroundColor: colors.primary,
                      child: Icon(
                        context.icons.check,
                        color: colors.onPrimary,
                        size: dimensions.iconMd,
                      ),
                    ),
                  ),
                ),
              if (moisture != null || plant.isInQuarantine())
                Positioned(
                  top: spacing.xs,
                  left: spacing.xs,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (moisture != null)
                        ExcludeSemantics(
                          child: _MoistureBadge(moisture: moisture!),
                        ),
                      if (moisture != null && plant.isInQuarantine())
                        SizedBox(height: spacing.xs),
                      if (plant.isInQuarantine()) const QuarantineBadge(),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsColumn(
    BuildContext context, {
    required String fertilizingStatLabel,
    required String wateredLabel,
    required String batchesLabel,
    required bool fertilizingOverdue,
  }) {
    final spacing = context.spacing;
    final statRowHeight = _statRowHeight(context);
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: statRowHeight,
          child: _StatChip(
            icon: context.icons.fertilizing,
            label: fertilizingStatLabel,
            iconColor: fertilizingOverdue ? colors.error : null,
            labelColor: fertilizingOverdue ? colors.error : null,
          ),
        ),
        spacing.vXxs,
        SizedBox(
          height: statRowHeight,
          child: _StatChip(
            icon: context.icons.watering,
            label: wateredLabel,
          ),
        ),
        spacing.vXxs,
        SizedBox(
          height: statRowHeight,
          child: _StatChip(
            hugeIcon: context.icons.propagations,
            label: batchesLabel,
          ),
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData? icon;
  final List<List<dynamic>>? hugeIcon;
  final String label;
  final Color? iconColor;
  final Color? labelColor;

  const _StatChip({
    this.icon,
    this.hugeIcon,
    required this.label,
    this.iconColor,
    this.labelColor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final spacing = context.spacing;
    final typography = context.typography;
    final iconSize = context.dimensions.iconSm;
    final resolvedIconColor = iconColor ?? colors.icon;
    final Widget leading;
    if (icon != null) {
      leading = Icon(icon, size: iconSize, color: resolvedIconColor);
    } else {
      leading = HugeIcon(
        icon: hugeIcon!,
        size: iconSize,
        color: colors.icon,
      );
    }

    return Row(
      children: [
        leading,
        SizedBox(width: spacing.xxs),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: typography.caption.copyWith(
              color: labelColor ?? colors.textSecondary,
              height: 1.1,
            ),
          ),
        ),
      ],
    );
  }
}

class _FertilizingOverdueBadge extends StatelessWidget {
  final String tooltip;

  const _FertilizingOverdueBadge({required this.tooltip});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final dimensions = context.dimensions;
    return Tooltip(
      message: tooltip,
      child: Container(
        padding: EdgeInsets.all(context.spacing.xxs),
        decoration: BoxDecoration(
          color: colors.error,
          shape: BoxShape.circle,
          boxShadow: context.shadows.card,
        ),
        child: Icon(
          context.icons.fertilizing,
          size: dimensions.iconMd,
          color: colors.onPrimary,
        ),
      ),
    );
  }
}

class _MoistureBadge extends StatelessWidget {
  final double moisture;

  const _MoistureBadge({required this.moisture});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    final dry = moisture < 20;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.spacing.xs,
        vertical: context.spacing.xxs,
      ),
      decoration: BoxDecoration(
        color: dry ? colors.error : colors.modal.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(context.radii.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          HugeIcon(
            icon: context.icons.humidity,
            size: context.dimensions.iconMd,
          ),
          SizedBox(width: context.spacing.xxs),
          Text(
            '${moisture.round()}%',
            style: typography.caption.copyWith(
              color: dry ? Colors.white : colors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlantAssetPlaceholder extends StatelessWidget {
  const _PlantAssetPlaceholder();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final dimensions = context.dimensions;
    return ExcludeSemantics(
      child: Container(
        color: colors.modal,
        child: Image.asset(
          'assets/images/default-img.webp',
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
          errorBuilder: (context, error, stackTrace) {
            return Center(
              child: Icon(
                context.icons.stage,
                color: colors.icon,
                size: dimensions.photoPlaceholder,
              ),
            );
          },
        ),
      ),
    );
  }
}
