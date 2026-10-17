import 'package:flutter/material.dart';
import 'package:plontukrot/l10n/app_localizations.dart';

import '../../../../core/theme/theme_context.dart';
import '../../../../core/widgets/focusable_tap.dart';
import '../../plants/widgets/common/pick_and_crop_plant_photo.dart';
import '../../plants/widgets/common/plant_image.dart';
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
              // Always occupy the same slot. Inserting the button only after
              // the second variant appears rebuilds the first card while its
              // description field is focused and can drop that text.
              ExcludeSemantics(
                excluding: !canRemove,
                child: Visibility(
                  visible: canRemove,
                  maintainState: true,
                  maintainAnimation: true,
                  child: Semantics(
                    button: true,
                    label: l10n.experimentsRemoveVariant,
                    child: IconButton(
                      onPressed:
                          canRemove ? () => _handleRemove(context) : null,
                      tooltip: canRemove ? l10n.experimentsRemoveVariant : null,
                      icon: Icon(context.icons.delete, color: colors.error),
                    ),
                  ),
                ),
              ),
            ],
          ),
          spacing.vXs,
          TextField(
            key: ObjectKey(draft.label),
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
            key: ObjectKey(draft.description),
            controller: draft.description,
            textCapitalization: TextCapitalization.sentences,
            maxLines: 2,
            style: inputs.textStyle,
            onChanged: (_) => onChanged(),
            decoration: inputs.decoration(
              labelText: l10n.experimentsVariantDescription,
            ),
          ),
          spacing.vSm,
          _VariantPhotoField(draft: draft),
        ],
      ),
    );
  }
}

/// Optional photo for one variant. Pick/crop reuses the plant photo flow.
/// The chosen bytes stay on [VariantDraft] until the form uploads them.
class _VariantPhotoField extends StatefulWidget {
  final VariantDraft draft;

  const _VariantPhotoField({required this.draft});

  @override
  State<_VariantPhotoField> createState() => _VariantPhotoFieldState();
}

class _VariantPhotoFieldState extends State<_VariantPhotoField> {
  Future<void> _pick() async {
    final bytes = await pickAndCropPlantPhoto(context);
    if (bytes == null || !mounted) return;
    setState(() {
      widget.draft.pickedBytes = bytes;
      widget.draft.imageCleared = false;
    });
  }

  void _clear() {
    setState(() {
      widget.draft.pickedBytes = null;
      widget.draft.imageUrl = null;
      widget.draft.imageCleared = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final spacing = context.spacing;
    final typography = context.typography;
    final size = context.dimensions.photoPreview;
    final radius = BorderRadius.circular(context.radii.lg);
    final draft = widget.draft;
    final hasPhoto = draft.hasPhoto;
    final actionLabel = hasPhoto
        ? l10n.experimentsVariantReplacePhoto
        : l10n.experimentsVariantAddPhoto;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Semantics(
          button: true,
          label: actionLabel,
          child: FocusableTap(
            onTap: _pick,
            borderRadius: radius,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: colors.card,
                borderRadius: radius,
                border: Border.all(color: colors.outline),
              ),
              clipBehavior: Clip.antiAlias,
              alignment: Alignment.center,
              child: _preview(draft, colors, size),
            ),
          ),
        ),
        spacing.hMd,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.experimentsVariantPhoto,
                style: typography.bodyLarge,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (hasPhoto)
                TextButton(
                  onPressed: _clear,
                  child: Text(l10n.commonClear),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _preview(VariantDraft draft, AppColorTokens colors, double size) {
    final bytes = draft.pickedBytes;
    if (bytes != null) {
      return ExcludeSemantics(
        child: Image.memory(
          bytes,
          fit: BoxFit.cover,
          width: size,
          height: size,
        ),
      );
    }
    final url = draft.imageUrl?.trim();
    if (!draft.imageCleared && url != null && url.isNotEmpty) {
      return PlantImage(
        imageUrl: url,
        fit: BoxFit.cover,
        width: size,
        height: size,
        excludeFromSemantics: true,
        placeholder: Icon(context.icons.image, color: colors.textSecondary),
        errorWidget: Icon(context.icons.image, color: colors.textSecondary),
      );
    }
    return ExcludeSemantics(
      child: Icon(context.icons.addPhotoOutlined, color: colors.textSecondary),
    );
  }
}
