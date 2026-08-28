import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:plontukrot/l10n/app_localizations.dart';

import '../../../../core/theme/theme_context.dart';
import '../../../../core/widgets/accessible_progress_indicator.dart';
import '../../../../core/widgets/focusable_tap.dart';
import '../../../../models/genus_care_guide.dart';
import '../../../../services/genus_care_service.dart';

/// Card showing botanical overview and AI-generated care recommendations for a plant genus.
class GenusCareGuideCard extends StatefulWidget {
  final String genus;

  const GenusCareGuideCard({
    super.key,
    required this.genus,
  });

  @override
  State<GenusCareGuideCard> createState() => _GenusCareGuideCardState();
}

class _GenusCareGuideCardState extends State<GenusCareGuideCard> {
  final GenusCareService _service = GenusCareService();
  Future<GenusCareGuide?>? _careGuideFuture;
  bool _isExpanded = false;
  String? _loadedLocale;
  String? _loadedGenus;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _ensureGuideLoaded();
  }

  @override
  void didUpdateWidget(covariant GenusCareGuideCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.genus.trim().toLowerCase() !=
        widget.genus.trim().toLowerCase()) {
      _ensureGuideLoaded(force: true);
    }
  }

  void _ensureGuideLoaded({bool force = false}) {
    final genus = widget.genus.trim();
    if (genus.isEmpty) return;

    final locale = Localizations.localeOf(context).languageCode;
    if (!force &&
        _careGuideFuture != null &&
        _loadedLocale == locale &&
        _loadedGenus == genus.toLowerCase()) {
      return;
    }

    _loadedLocale = locale;
    _loadedGenus = genus.toLowerCase();
    _loadGuide(forceRefresh: force);
  }

  void _loadGuide({bool forceRefresh = false}) {
    final locale = Localizations.localeOf(context).languageCode;
    setState(() {
      _careGuideFuture = _service.getCareGuide(
        widget.genus,
        locale: locale,
        forceRefresh: forceRefresh,
      );
    });
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    final genus = widget.genus.trim();
    if (genus.isEmpty) {
      return const SizedBox.shrink();
    }

    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final spacing = context.spacing;
    final radii = context.radii;
    final typography = context.typography;
    final icons = context.icons;

    return FutureBuilder<GenusCareGuide?>(
      future: _careGuideFuture,
      builder: (context, snapshot) {
        if (_careGuideFuture == null ||
            snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            width: double.infinity,
            padding: spacing.allMd,
            decoration: BoxDecoration(
              color: colors.card,
              borderRadius: BorderRadius.circular(radii.lg),
              border: Border.all(
                color: colors.outline.withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icons.aiCare,
                  color: colors.primary,
                  size: 20,
                ),
                spacing.hSm,
                Expanded(
                  child: Text(
                    l10n.genusCareLoading,
                    style: typography.caption.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ),
                spacing.hSm,
                AccessibleProgressIndicator(
                  color: colors.primary,
                  size: 16,
                  strokeWidth: 2,
                ),
              ],
            ),
          );
        }

        if (snapshot.hasError) {
          return Container(
            width: double.infinity,
            padding: spacing.allMd,
            decoration: BoxDecoration(
              color: colors.card,
              borderRadius: BorderRadius.circular(radii.lg),
              border: Border.all(
                color: colors.outline.withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icons.aiCare,
                  color: colors.primary,
                  size: 20,
                ),
                spacing.hSm,
                Expanded(
                  child: Text(
                    l10n.genusCareTitle,
                    style: typography.titleSmall.copyWith(
                      color: colors.heading,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                FocusableTap(
                  onTap: () => _loadGuide(forceRefresh: true),
                  borderRadius: BorderRadius.circular(radii.sm),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: spacing.sm,
                      vertical: spacing.xs,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          icons.clear,
                          size: 16,
                          color: colors.primary,
                        ),
                        spacing.hXs,
                        Text(
                          l10n.genusCareRetry,
                          style: typography.captionSmall.copyWith(
                            color: colors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        final guide = snapshot.data;
        if (guide == null || guide.isEmpty) {
          return const SizedBox.shrink();
        }

        final items = <_CareItemData>[
          if (guide.light != null && guide.light!.isNotEmpty)
            _CareItemData(
              icon: icons.light,
              title: l10n.genusCareLight,
              value: guide.light!,
            ),
          if (guide.watering != null && guide.watering!.isNotEmpty)
            _CareItemData(
              icon: icons.watering,
              title: l10n.genusCareWatering,
              value: guide.watering!,
            ),
          if (guide.soil != null && guide.soil!.isNotEmpty)
            _CareItemData(
              icon: icons.repotting,
              title: l10n.genusCareSoil,
              value: guide.soil!,
            ),
          if (guide.fertilizing != null && guide.fertilizing!.isNotEmpty)
            _CareItemData(
              icon: icons.fertilizing,
              title: l10n.genusCareFertilizing,
              value: guide.fertilizing!,
            ),
          if (guide.humidity != null && guide.humidity!.isNotEmpty)
            _CareItemData(
              icon: icons.humidity,
              title: l10n.genusCareHumidity,
              value: guide.humidity!,
            ),
          if (guide.toxicity != null && guide.toxicity!.isNotEmpty)
            _CareItemData(
              icon: icons.toxicity,
              title: l10n.genusCareToxicity,
              value: guide.toxicity!,
              isWarning: true,
            ),
        ];

        final visibleItems =
            _isExpanded ? items : items.take(3).toList(growable: false);

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.circular(radii.lg),
            border: Border.all(
              color: colors.outline.withValues(alpha: 0.4),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Semantics(
                button: true,
                label: _isExpanded
                    ? l10n.a11yGenusCareCollapse
                    : l10n.a11yGenusCareExpand,
                expanded: _isExpanded,
                child: FocusableTap(
                  onTap: _toggleExpanded,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(radii.lg),
                    bottom: Radius.circular(_isExpanded ? 0 : radii.lg),
                  ),
                  child: Padding(
                    padding: spacing.allMd,
                    child: Row(
                      children: [
                        Icon(
                          icons.aiCare,
                          color: colors.primary,
                          size: 20,
                        ),
                        spacing.hSm,
                        Expanded(
                          child: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  l10n.genusCareTitle,
                                  style: typography.titleSmall.copyWith(
                                    color: colors.heading,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              spacing.hSm,
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: spacing.sm,
                                  vertical: spacing.xs / 2,
                                ),
                                decoration: BoxDecoration(
                                  color: colors.primary.withValues(alpha: 0.15),
                                  borderRadius:
                                      BorderRadius.circular(radii.sm / 2),
                                ),
                                child: Text(
                                  l10n.genusCareAiBadge,
                                  style: typography.captionSmall.copyWith(
                                    color: colors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          _isExpanded ? icons.chevronUp : icons.chevronDown,
                          color: colors.icon,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Content
              Padding(
                padding: EdgeInsets.fromLTRB(
                  spacing.md,
                  0,
                  spacing.md,
                  spacing.md,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (guide.origin != null && guide.origin!.isNotEmpty) ...[
                      Text(
                        guide.origin!,
                        style: typography.bodySmall.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                      spacing.vMd,
                    ],
                    for (int i = 0; i < visibleItems.length; i++) ...[
                      if (i > 0) spacing.vSm,
                      _buildCareTile(
                        context,
                        visibleItems[i],
                      ),
                    ],
                    if (items.length > 3) ...[
                      spacing.vSm,
                      Center(
                        child: FocusableTap(
                          onTap: _toggleExpanded,
                          borderRadius: BorderRadius.circular(radii.sm),
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: spacing.md,
                              vertical: spacing.xs,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _isExpanded
                                      ? l10n.genusCareCollapse
                                      : l10n.genusCareExpand,
                                  style: typography.captionSmall.copyWith(
                                    color: colors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                spacing.hXs,
                                Icon(
                                  _isExpanded
                                      ? icons.chevronUp
                                      : icons.chevronDown,
                                  color: colors.primary,
                                  size: 14,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCareTile(
    BuildContext context,
    _CareItemData item,
  ) {
    final colors = context.colors;
    final spacing = context.spacing;
    final radii = context.radii;
    final typography = context.typography;

    final tileBg = item.isWarning
        ? colors.warning.withValues(alpha: 0.1)
        : colors.screen.withValues(alpha: 0.6);
    final iconColor = item.isWarning ? colors.warning : colors.primary;
    final borderColor = item.isWarning
        ? colors.warning.withValues(alpha: 0.3)
        : colors.outline.withValues(alpha: 0.3);

    Widget iconWidget;
    if (item.icon is IconData) {
      iconWidget = Icon(
        item.icon as IconData,
        color: iconColor,
        size: 18,
      );
    } else if (item.icon is List<List<dynamic>>) {
      iconWidget = HugeIcon(
        icon: item.icon as List<List<dynamic>>,
        color: iconColor,
        size: 18,
      );
    } else {
      iconWidget = const SizedBox(width: 18, height: 18);
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: spacing.sm + 2,
        vertical: spacing.sm,
      ),
      decoration: BoxDecoration(
        color: tileBg,
        borderRadius: BorderRadius.circular(radii.md),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: spacing.xs / 2),
            child: ExcludeSemantics(child: iconWidget),
          ),
          spacing.hSm,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.title,
                  style: typography.caption.copyWith(
                    fontWeight: FontWeight.bold,
                    color: item.isWarning ? colors.warning : colors.heading,
                  ),
                ),
                spacing.vXxs,
                Text(
                  item.value,
                  style: typography.captionSmall.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CareItemData {
  final dynamic icon;
  final String title;
  final String value;
  final bool isWarning;

  const _CareItemData({
    required this.icon,
    required this.title,
    required this.value,
    this.isWarning = false,
  });
}
