import 'package:flutter/material.dart';
import 'package:plontukrot/core/theme/theme_context.dart';
import 'package:plontukrot/core/widgets/app_modal.dart';
import 'package:plontukrot/l10n/app_localizations.dart';
import 'package:plontukrot/models/balcony_band.dart';
import 'package:plontukrot/models/plant.dart';
import 'package:plontukrot/services/plant_service.dart';
import '../../../home/widgets/balcony_history_sheet.dart';

/// A toggle to mark a plant as "on the balcony" for wintering, plus the
/// cold-tolerance band used by the balcony monitor to decide when to bring
/// it back inside.
class BalconyToggle extends StatefulWidget {
  final Plant plant;
  final String plantId;

  const BalconyToggle({super.key, required this.plant, required this.plantId});

  @override
  State<BalconyToggle> createState() => _BalconyToggleState();
}

class _BalconyToggleState extends State<BalconyToggle> {
  bool _busy = false;

  Future<void> _toggle(bool on) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      // Resolve the band from the plant's genus/species (and the DeepSeek
      // care guide) so a newly added plant gets a sensible cold-tolerance
      // default automatically.
      final band = await BalconyBandResolver.resolve(widget.plant);
      await PlantService().setOnBalcony(
        plantId: widget.plantId,
        onBalcony: on,
        band: band.value,
      );
    } catch (_) {
      // Surface a snackbar on failure; the stream will re-sync the switch.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).commonError(''))),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _openHistory() {
    showAppModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      builder: (_) => const BalconyHistorySheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final spacing = context.spacing;
    final typography = context.typography;
    final on = widget.plant.onBalcony;

    return FutureBuilder<BalconyBand>(
      future: BalconyBandResolver.resolve(widget.plant),
      builder: (context, snapshot) {
        final band = snapshot.data ?? BalconyBand.moderate;
        return _buildToggle(context, l10n, colors, spacing, typography, on, band);
      },
    );
  }

  Widget _buildToggle(
    BuildContext context,
    AppLocalizations l10n,
    AppColorTokens colors,
    AppSpacingTokens spacing,
    AppTypographyTokens typography,
    bool on,
    BalconyBand band,
  ) {

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: spacing.sm, vertical: spacing.xs),
      decoration: BoxDecoration(
        color: on ? colors.primary.withValues(alpha: 0.12) : colors.modal,
        borderRadius: BorderRadius.circular(context.radii.sm),
        border: Border.all(
          color: on ? colors.primary : colors.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            on ? Icons.landscape : Icons.home_outlined,
            color: on ? colors.primary : colors.icon,
            size: context.dimensions.iconMd,
          ),
          spacing.hSm,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  on ? l10n.balconyOn : l10n.balconyOff,
                  style: typography.bodyEmphasis.copyWith(
                    color: on ? colors.primary : colors.textPrimary,
                  ),
                ),
                Text(
                  l10n.balconyBandLabel(band.minTempC),
                  style: typography.caption.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: l10n.balconyHistoryTitle,
            onPressed: _openHistory,
            icon: Icon(
              Icons.history,
              color: colors.icon,
              size: context.dimensions.iconMd,
            ),
          ),
          Switch(
            value: on,
            onChanged: _busy ? null : _toggle,
          ),
        ],
      ),
    );
  }
}
