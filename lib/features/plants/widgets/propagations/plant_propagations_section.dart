import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:plontukrot/core/l10n/app_localizations_x.dart';
import 'package:plontukrot/l10n/app_localizations.dart';

import '../../../../core/theme/theme_context.dart';
import '../../../../models/propagation.dart';
import '../../../../services/propagation_service.dart';
import '../common/expandable_side_scroll_list.dart';
import '../sheets/add_propagation_sheet.dart';
import '../sheets/propagation_details_sheet.dart';
import 'package:plontukrot/core/widgets/accessible_progress_indicator.dart';
import 'package:plontukrot/core/widgets/app_modal.dart';

class PlantPropagationsSection extends StatefulWidget {
  final String plantId;
  final String plantName;
  final String plantFamily;

  const PlantPropagationsSection({
    super.key,
    required this.plantId,
    required this.plantName,
    required this.plantFamily,
  });

  @override
  State<PlantPropagationsSection> createState() =>
      _PlantPropagationsSectionState();
}

class _PlantPropagationsSectionState extends State<PlantPropagationsSection> {
  late final Stream<List<Propagation>> _propagationsStream;

  @override
  void initState() {
    super.initState();
    _propagationsStream =
        PropagationService().watchPropagationsForPlant(widget.plantId);
  }

  Future<void> _openAdd(BuildContext context) async {
    await showAppModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddPropagationSheet(
        parentPlantId: widget.plantId,
        parentPlantName: widget.plantName,
        parentPlantFamily: widget.plantFamily,
      ),
    );
  }

  Future<void> _openDetails(
    BuildContext context,
    Propagation propagation,
  ) async {
    await showAppModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PropagationDetailsSheet(propagation: propagation),
    );
  }

  Widget _propagationTile(
    BuildContext context,
    Propagation item,
    AppLocalizations l10n,
    String dateLocale,
  ) {
    final colors = context.colors;
    final radii = context.radii;
    final spacing = context.spacing;
    final typography = context.typography;
    final title =
        '${l10n.stageTitle(item.stage)} · ${l10n.daysCount(item.daysSinceStart)}';
    final subtitle =
        '${l10n.propagationAliveWithMethod(item.quantityAlive, l10n.propagationMethodPlural(item.method))} · ${DateFormat('d MMM y', dateLocale).format(item.startedAt)}';
    return Material(
      color: colors.card,
      borderRadius: BorderRadius.circular(radii.md),
      child: Semantics(
        button: true,
        label: '$title. $subtitle',
        child: InkWell(
          onTap: () => _openDetails(context, item),
          borderRadius: BorderRadius.circular(radii.md),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(spacing.sm + 2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radii.md),
              border: Border.all(color: colors.outline),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: typography.bodyLarge.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colors.textPrimary,
                        ),
                      ),
                      spacing.vXxs,
                      Text(
                        subtitle,
                        style: typography.bodySmall.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                ExcludeSemantics(
                  child: Icon(
                    context.icons.chevronRight,
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final dateLocale = Localizations.localeOf(context).toString();
    final colors = context.colors;
    final radii = context.radii;
    final spacing = context.spacing;
    final typography = context.typography;
    final dimensions = context.dimensions;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.propagationTitle,
                style: typography.sectionTitle.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: () => _openAdd(context),
              icon: Icon(context.icons.add, size: dimensions.iconMd),
              label: Text(l10n.commonAdd),
              style: TextButton.styleFrom(
                foregroundColor: colors.primary,
              ),
            ),
          ],
        ),
        spacing.vXs,
        StreamBuilder<List<Propagation>>(
          stream: _propagationsStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return Padding(
                padding: EdgeInsets.symmetric(vertical: spacing.md),
                child: Center(
                  child: AccessibleProgressIndicator(color: colors.primary),
                ),
              );
            }

            final items = snapshot.data ?? const <Propagation>[];
            if (items.isEmpty) {
              return Container(
                width: double.infinity,
                padding: spacing.allMd,
                decoration: BoxDecoration(
                  color: colors.card,
                  borderRadius: BorderRadius.circular(radii.md),
                ),
                child: Text(
                  l10n.propagationEmptyActive,
                  style: typography.bodySmall,
                ),
              );
            }

            return ExpandableSideScrollList(
              itemCount: items.length,
              collapsedVisible: 3,
              expandedViewport: 5,
              itemExtent: 88,
              itemBuilder: (context, index) {
                return _propagationTile(
                  context,
                  items[index],
                  l10n,
                  dateLocale,
                );
              },
            );
          },
        ),
      ],
    );
  }
}
