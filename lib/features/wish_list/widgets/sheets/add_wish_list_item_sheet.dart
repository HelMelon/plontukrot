import 'package:flutter/material.dart';
import 'package:plontukrot/l10n/app_localizations.dart';

import '../../../../core/theme/theme_context.dart';
import '../../../../models/wish_list_item.dart';
import '../../../../services/wish_list_service.dart';
import 'package:plontukrot/core/widgets/accessible_progress_indicator.dart';

class AddWishListItemSheet extends StatefulWidget {
  final WishListItem? item;

  const AddWishListItemSheet({super.key, this.item});

  const AddWishListItemSheet.edit({
    super.key,
    required WishListItem this.item,
  });

  @override
  State<AddWishListItemSheet> createState() => _AddWishListItemSheetState();
}

class _AddWishListItemSheetState extends State<AddWishListItemSheet> {
  late final TextEditingController _nameEnController;
  late final TextEditingController _nameAltController;

  bool isLoading = false;
  String? nameEnError;
  String? nameAltError;

  bool get _isEditing => widget.item != null;

  @override
  void initState() {
    super.initState();
    _nameEnController = TextEditingController(text: widget.item?.nameEn ?? '');
    _nameAltController =
        TextEditingController(text: widget.item?.nameAlt ?? '');
  }

  @override
  void dispose() {
    _nameEnController.dispose();
    _nameAltController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final nameEn = _nameEnController.text.trim();
    final nameAlt = _nameAltController.text.trim();

    String? nextEnError;
    String? nextAltError;
    if (nameEn.isEmpty) {
      nextEnError = l10n.wishListNameEnRequired;
    }
    if (nameAlt.isEmpty) {
      nextAltError = l10n.wishListNameAltRequired;
    }
    if (nextEnError != null || nextAltError != null) {
      setState(() {
        nameEnError = nextEnError;
        nameAltError = nextAltError;
      });
      return;
    }

    setState(() {
      isLoading = true;
      nameEnError = null;
      nameAltError = null;
    });

    try {
      final service = WishListService();
      if (_isEditing) {
        await service.updateItem(
          id: widget.item!.id,
          nameEn: nameEn,
          nameAlt: nameAlt,
        );
      } else {
        await service.addItem(nameEn: nameEn, nameAlt: nameAlt);
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.commonError(e.toString()))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final media = MediaQuery.of(context);
    final maxHeight = media.size.height * 0.92;
    final colors = context.colors;
    final spacing = context.spacing;
    final sheets = context.components.sheets;
    final inputs = context.components.inputs;
    final typography = context.typography;
    final dimensions = context.dimensions;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: Material(
            color: colors.modal,
            borderRadius: sheets.topBorderRadius,
            clipBehavior: Clip.antiAlias,
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  spacing.vSm,
                  Center(
                    child: Container(
                      width: sheets.handleWidth,
                      height: sheets.handleHeight,
                      decoration: BoxDecoration(
                        color: sheets.handleColor,
                        borderRadius: BorderRadius.circular(sheets.handleRadius),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      sheets.contentPadding.left,
                      spacing.md,
                      sheets.contentPadding.right,
                      0,
                    ),
                    child: Text(
                      _isEditing ? l10n.wishListEdit : l10n.wishListAdd,
                      style: typography.titleLarge.copyWith(
                        letterSpacing: -1,
                      ),
                    ),
                  ),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        sheets.contentPadding.left,
                        spacing.md,
                        sheets.contentPadding.right,
                        spacing.sm,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                            controller: _nameEnController,
                            style: inputs.textStyle,
                            autofocus: true,
                            textCapitalization: TextCapitalization.sentences,
                            onChanged: (_) {
                              if (nameEnError != null) {
                                setState(() => nameEnError = null);
                              }
                            },
                            decoration: inputs
                                .decoration(
                                  labelText: l10n.wishListNameEn,
                                  prefixIcon: Icon(
                                    Icons.language,
                                    color: colors.icon,
                                  ),
                                )
                                .copyWith(errorText: nameEnError),
                          ),
                          spacing.vMd,
                          TextField(
                            controller: _nameAltController,
                            style: inputs.textStyle,
                            textCapitalization: TextCapitalization.sentences,
                            onChanged: (_) {
                              if (nameAltError != null) {
                                setState(() => nameAltError = null);
                              }
                            },
                            decoration: inputs
                                .decoration(
                                  labelText: l10n.wishListNameAlt,
                                  prefixIcon: Icon(
                                    Icons.translate,
                                    color: colors.icon,
                                  ),
                                )
                                .copyWith(errorText: nameAltError),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      sheets.contentPadding.left,
                      spacing.xs,
                      sheets.contentPadding.right,
                      spacing.md,
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      height: dimensions.buttonHeight,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _save,
                        child: isLoading
                            ? SizedBox(
                                width: dimensions.iconXl,
                                height: dimensions.iconXl,
                                child: AccessibleProgressIndicator(strokeWidth: 2, color: colors.onPrimary),
                              )
                            : Text(
                                l10n.commonSave,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
