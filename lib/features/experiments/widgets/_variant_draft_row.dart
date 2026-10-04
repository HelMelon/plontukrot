import 'package:flutter/material.dart';
import 'package:plontukrot/l10n/app_localizations.dart';

import '../../../../core/theme/theme_context.dart';
import 'variant_draft.dart';

/// One editable variant card inside [ExperimentFormSheet]: name + optional
/// description, with a remove action. Existing variants ask for confirmation
/// (removing them deletes their participants and observations on save).
class VariantDraftRow extends StatelessWidget {
  final VariantDraft draft;
  final int index;
  final bool canRemove;
  final VoidCallback onRemove;
  final VoidCallback onChanged;
  final Future<bool> Function() onRemoveExisting;

  const VariantDraftRow({
    super.key,
    required this.draft,
    required this.index,
    required this.canRemove,
    required this.onRemove,
    required this.onChanged,
    required this.onRemoveExisting,
  });

  Future<void> _handleRemove(BuildContext context) async {
    if (draft.isExisting && !await onRemoveExisting()) return;
    onRemove();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final spacing = context.spacing;
    final cards = context.components.cards;
    final inputs = context.components.inputs;
    final typography = context.typography;

    return Container(
      padding: cards.padding,
      decoration: cards.decoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.experimentsVariantLabel,
                  style: typography.titleSmall.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ),
              if (canRemove)
                Semantics(
                  button: true,
                  label: l10n.experimentsRemoveVariant,
                  child: IconButton(
                    onPressed: () => _handleRemove(context),
                    tooltip: l10n.experimentsRemoveVariant,
                    icon: Icon(context.icons.delete, color: colors.error),
                  ),
                ),
            ],
          ),
          spacing.vXs,
          TextField(
            controller: draft.label,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.next,
            style: inputs.textStyle,
            onChanged: (_) => onChanged(),
            decoration: inputs.decoration(
              hintText: l10n.experimentsVariantLabelHint,
            ),
          ),
          spacing.vSm,
          TextField(
            controller: draft.description,
            textCapitalization: TextCapitalization.sentences,
            maxLines: 2,
            style: inputs.textStyle,
            onChanged: (_) => onChanged(),
            decoration: inputs.decoration(
              labelText: l10n.experimentsVariantDescription,
            ),
          ),
        ],
      ),
    );
  }
}
