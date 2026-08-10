import 'package:flutter/material.dart';
import 'package:plontukrot/l10n/app_localizations.dart';

import '../../models/random_plant_display_name.dart';
import '../../services/plant_name_catalog_service.dart';
import '../theme/theme_context.dart';
import 'focusable_tap.dart';

/// Shows a random plant-style name suggestion under a display-name field.
class RandomPlantNameSuggestion extends StatefulWidget {
  final ValueChanged<String> onApply;
  final bool enabled;

  const RandomPlantNameSuggestion({
    super.key,
    required this.onApply,
    this.enabled = true,
  });

  @override
  State<RandomPlantNameSuggestion> createState() =>
      _RandomPlantNameSuggestionState();
}

class _RandomPlantNameSuggestionState extends State<RandomPlantNameSuggestion> {
  final _generator = RandomPlantDisplayName();
  String? _suggestion;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    await PlantNameCatalogService.instance.ensureLoaded();
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    final next = await _generator.next(l10n);
    if (!mounted) return;
    setState(() {
      _suggestion = next.isEmpty ? null : next;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final spacing = context.spacing;
    final typography = context.typography;
    final radii = context.radii;
    final suggestion = _suggestion;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.authPlantNameSuggestionHint,
          style: typography.bodySmall.copyWith(color: colors.textSecondary),
        ),
        spacing.vXs,
        Row(
          children: [
            Expanded(
              child: FocusableTap(
                enabled: widget.enabled && suggestion != null && !_loading,
                borderRadius: BorderRadius.circular(radii.sm),
                onTap: suggestion == null
                    ? null
                    : () => widget.onApply(suggestion),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: spacing.sm,
                    vertical: spacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: colors.card,
                    borderRadius: BorderRadius.circular(radii.sm),
                  ),
                  child: Text(
                    _loading
                        ? l10n.loading
                        : (suggestion ?? l10n.authPlantNameSuggestionEmpty),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: typography.bodyMedium.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                ),
              ),
            ),
            IconButton(
              tooltip: l10n.a11yRegeneratePlantNameSuggestion,
              onPressed: (!widget.enabled || _loading) ? null : _refresh,
              icon: Icon(Icons.refresh, color: colors.icon),
            ),
          ],
        ),
      ],
    );
  }
}
