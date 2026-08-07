import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:plontukrot/l10n/app_localizations.dart';

import '../../../../core/theme/theme_context.dart';
import '../../../../models/variegation.dart';
import '../../../../services/plant_service.dart';
import '../../../../services/wish_list_service.dart';
import '../selectors/plant_stage_selector.dart';
import '../selectors/plant_variegation_selector.dart';
import 'package:hugeicons/hugeicons.dart';

class AddPlantSheet extends StatefulWidget {
  final String? initialTradingName;
  final String? wishListItemId;

  const AddPlantSheet({
    super.key,
    this.initialTradingName,
    this.wishListItemId,
  });

  @override
  State<AddPlantSheet> createState() => _AddPlantSheetState();
}

class _AddPlantSheetState extends State<AddPlantSheet> {
  late final TextEditingController genusController;
  late final TextEditingController speciesController;
  late final TextEditingController cultivarController;
  late final TextEditingController plantFamilyController;
  late final TextEditingController tradingNameController;
  final nickNameController = TextEditingController();
  late final TextEditingController wateringFrequencyController;
  late final TextEditingController initialLeafCountController;

  bool isLoading = false;
  int selectedStage = 0;
  Variegation selectedVariegation = Variegation.none;
  String? genusError;
  String? speciesError;

  @override
  void initState() {
    super.initState();
    genusController = TextEditingController();
    speciesController = TextEditingController();
    cultivarController = TextEditingController();
    plantFamilyController = TextEditingController();
    tradingNameController = TextEditingController(
      text: widget.initialTradingName ?? '',
    );
    wateringFrequencyController = TextEditingController();
    initialLeafCountController = TextEditingController(text: '0');
  }

  @override
  void dispose() {
    genusController.dispose();
    speciesController.dispose();
    cultivarController.dispose();
    plantFamilyController.dispose();
    tradingNameController.dispose();
    nickNameController.dispose();
    wateringFrequencyController.dispose();
    initialLeafCountController.dispose();
    super.dispose();
  }

  InputDecoration _fieldDecoration({
    required String labelText,
    String? errorText,
    required Widget prefixIcon,
  }) {
    final inputs = context.components.inputs;
    return inputs
        .decoration(
          labelText: labelText,
          prefixIcon: prefixIcon,
        )
        .copyWith(errorText: errorText);
  }

  /// Same token as Material — visual match; see [_hugePrefixIcon].
  double get _prefixIconSize => context.dimensions.iconXl;

  Widget _materialPrefixIcon(IconData icon) {
    return Icon(
      icon,
      color: context.colors.icon,
      size: _prefixIconSize,
    );
  }

  /// [InputDecorator] forces prefix min 48×48. Material [Icon] still paints at
  /// [size]; [HugeIcon]/[SvgPicture] scales up to fill that box unless the
  /// min constraints are broken with [UnconstrainedBox].
  Widget _hugePrefixIcon(List<List<dynamic>> icon) {
    final size = _prefixIconSize;
    return UnconstrainedBox(
      child: HugeIcon(
        icon: icon,
        color: context.colors.icon,
        size: size,
        strokeWidth: 1.5,
      ),
    );
  }

  Future<void> addPlant() async {
    final l10n = AppLocalizations.of(context);
    final genus = genusController.text.trim();
    final species = speciesController.text.trim();
    final cultivar = cultivarController.text.trim();
    final plantFamily = plantFamilyController.text.trim();
    final tradingName = tradingNameController.text.trim();
    final nickname = nickNameController.text.trim();
    final initialLeafRaw = initialLeafCountController.text.trim();
    final initialLeafCount =
        initialLeafRaw.isEmpty ? 0 : int.tryParse(initialLeafRaw);

    String? nextGenusError;
    String? nextSpeciesError;
    if (genus.isEmpty) {
      nextGenusError = l10n.plantGenusRequired;
    }
    if (species.isEmpty) {
      nextSpeciesError = l10n.plantSpeciesRequired;
    }
    if (nextGenusError != null || nextSpeciesError != null) {
      setState(() {
        genusError = nextGenusError;
        speciesError = nextSpeciesError;
      });
      return;
    }

    if (initialLeafCount == null || initialLeafCount < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.plantInvalidInitialLeafCount)),
      );
      return;
    }

    if (mounted) {
      setState(() {
        isLoading = true;
        genusError = null;
        speciesError = null;
      });
    }

    try {
      await PlantService().addPlant(
        genus: genus,
        species: species,
        cultivar: cultivar.isEmpty ? null : cultivar,
        plantFamily: plantFamily.isEmpty ? null : plantFamily,
        variegation: selectedVariegation,
        tradingName: tradingName,
        nickname: nickname,
        stage: selectedStage,
        initialLeafCount: initialLeafCount,
      );

      final wishListItemId = widget.wishListItemId;
      if (wishListItemId != null) {
        await WishListService().deleteItem(wishListItemId);
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
                        borderRadius:
                            BorderRadius.circular(sheets.handleRadius),
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
                      l10n.plantAdd,
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
                            controller: genusController,
                            style: inputs.textStyle,
                            onChanged: (_) {
                              if (genusError != null) {
                                setState(() => genusError = null);
                              }
                            },
                            decoration: _fieldDecoration(
                              labelText: l10n.plantGenus,
                              errorText: genusError,
                              prefixIcon: _materialPrefixIcon(Icons.park_outlined),
                            ),
                          ),
                          spacing.vMd,
                          TextField(
                            controller: speciesController,
                            style: inputs.textStyle,
                            onChanged: (_) {
                              if (speciesError != null) {
                                setState(() => speciesError = null);
                              }
                            },
                            decoration: _fieldDecoration(
                              labelText: l10n.plantSpecies,
                              errorText: speciesError,
                              prefixIcon: _materialPrefixIcon(Icons.eco),
                            ),
                          ),
                          spacing.vMd,
                          TextField(
                            controller: cultivarController,
                            style: inputs.textStyle,
                            decoration: _fieldDecoration(
                              labelText: l10n.plantCultivar,
                              prefixIcon: _materialPrefixIcon(Icons.spa_outlined),
                            ),
                          ),
                          spacing.vMd,
                          PlantVariegationSelector(
                            selected: selectedVariegation,
                            onChanged: (value) {
                              setState(() => selectedVariegation = value);
                            },
                          ),
                          spacing.vMd,
                          TextField(
                            controller: tradingNameController,
                            style: inputs.textStyle,
                            decoration: _fieldDecoration(
                              labelText: l10n.plantTradingName,
                              prefixIcon:
                                  _materialPrefixIcon(Icons.storefront_outlined),
                            ),
                          ),
                          spacing.vMd,
                          TextField(
                            controller: plantFamilyController,
                            style: inputs.textStyle,
                            decoration: _fieldDecoration(
                              labelText: l10n.plantFamily,
                              prefixIcon:
                                  _materialPrefixIcon(Icons.family_restroom),
                            ),
                          ),
                          spacing.vMd,
                          TextField(
                            controller: nickNameController,
                            style: inputs.textStyle,
                            decoration: _fieldDecoration(
                              labelText: l10n.plantNickname,
                              prefixIcon: _hugePrefixIcon(
                                HugeIcons.strokeRoundedHouseHeart,
                              ),
                            ),
                          ),
                          spacing.vMd,
                          Text(
                            l10n.plantGrowthStage,
                            style: typography.label.copyWith(
                              color: colors.textSecondary,
                            ),
                          ),
                          spacing.vXs,
                          PlantStageSelector(
                            selectedStage: selectedStage,
                            onChanged: (value) {
                              setState(() {
                                selectedStage = value;
                              });
                            },
                          ),
                          spacing.vMd,
                          TextField(
                            controller: wateringFrequencyController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            style: inputs.textStyle,
                            decoration: _fieldDecoration(
                              labelText: l10n.plantWateringFrequency,
                              prefixIcon: _materialPrefixIcon(Icons.water_drop),
                            ),
                          ),
                          spacing.vMd,
                          TextField(
                            controller: initialLeafCountController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            style: inputs.textStyle,
                            decoration: _fieldDecoration(
                              labelText: l10n.plantInitialLeafCount,
                              prefixIcon: _hugePrefixIcon(
                                HugeIcons.strokeRoundedLeaf01,
                              ),
                            ),
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
                        onPressed: isLoading ? null : addPlant,
                        child: isLoading
                            ? SizedBox(
                                width: dimensions.iconXl,
                                height: dimensions.iconXl,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: colors.onPrimary,
                                ),
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
