import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:plontukrot/l10n/app_localizations.dart';

import '../../../../core/theme/theme_context.dart';
import '../../../../models/plant.dart';
import '../../../../models/variegation.dart';
import '../../../../services/plant_service.dart';
import '../selectors/plant_stage_selector.dart';
import '../selectors/plant_variegation_selector.dart';

class UpdatePlantSheet extends StatefulWidget {
  final String plantId;
  final Plant plant;

  const UpdatePlantSheet({
    super.key,
    required this.plantId,
    required this.plant,
  });

  @override
  State<UpdatePlantSheet> createState() => _UpdatePlantSheetState();
}

class _UpdatePlantSheetState extends State<UpdatePlantSheet> {
  final genusController = TextEditingController();
  final speciesController = TextEditingController();
  final cultivarController = TextEditingController();
  final plantFamilyController = TextEditingController();
  final tradingNameController = TextEditingController();
  final nickNameController = TextEditingController();
  final wateringFrequencyController = TextEditingController();
  final initialLeafCountController = TextEditingController();

  bool isLoading = false;
  int selectedStage = 0;
  Variegation selectedVariegation = Variegation.none;
  String? genusError;
  String? speciesError;

  @override
  void initState() {
    super.initState();

    genusController.text = widget.plant.genus;
    speciesController.text = widget.plant.species;
    cultivarController.text = widget.plant.cultivar ?? '';
    plantFamilyController.text = widget.plant.plantFamily ?? '';
    tradingNameController.text = widget.plant.tradingName;
    nickNameController.text = widget.plant.nickname;
    wateringFrequencyController.text =
        (widget.plant.wateringFrequency ?? '').toString();
    if (wateringFrequencyController.text == '0' ||
        wateringFrequencyController.text == 'null') {
      wateringFrequencyController.text = '';
    }
    initialLeafCountController.text = widget.plant.initialLeafCount.toString();
    selectedStage = widget.plant.stage;
    selectedVariegation = widget.plant.variegation;
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
    required IconData icon,
  }) {
    final colors = context.colors;
    final inputs = context.components.inputs;
    return inputs
        .decoration(
          labelText: labelText,
          prefixIcon: Icon(icon, color: colors.icon),
        )
        .copyWith(errorText: errorText);
  }

  Future<void> updatePlant() async {
    final l10n = AppLocalizations.of(context);
    final genus = genusController.text.trim();
    final species = speciesController.text.trim();
    final cultivar = cultivarController.text.trim();
    final plantFamily = plantFamilyController.text.trim();
    final tradingName = tradingNameController.text.trim();
    final nickname = nickNameController.text.trim();
    final wateringRaw = wateringFrequencyController.text.trim();
    final wateringFrequency =
        wateringRaw.isEmpty ? null : int.tryParse(wateringRaw);
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

    if (wateringRaw.isNotEmpty && wateringFrequency == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.plantInvalidWateringFrequency)),
      );
      return;
    }

    if (initialLeafCount == null || initialLeafCount < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.plantInvalidInitialLeafCount)),
      );
      return;
    }

    setState(() {
      isLoading = true;
      genusError = null;
      speciesError = null;
    });

    try {
      await PlantService().updatePlant(
        plantId: widget.plantId,
        genus: genus,
        species: species,
        cultivar: cultivar.isEmpty ? null : cultivar,
        plantFamily: plantFamily.isEmpty ? null : plantFamily,
        variegation: selectedVariegation,
        tradingName: tradingName,
        nickname: nickname,
        wateringFrequency: wateringFrequency,
        initialLeafCount: initialLeafCount,
        stage: selectedStage,
      );

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
                      l10n.plantEdit,
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
                              icon: Icons.park_outlined,
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
                              icon: Icons.eco,
                            ),
                          ),
                          spacing.vMd,
                          TextField(
                            controller: cultivarController,
                            style: inputs.textStyle,
                            decoration: _fieldDecoration(
                              labelText: l10n.plantCultivar,
                              icon: Icons.spa_outlined,
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
                              icon: Icons.storefront_outlined,
                            ),
                          ),
                          spacing.vMd,
                          TextField(
                            controller: plantFamilyController,
                            style: inputs.textStyle,
                            decoration: _fieldDecoration(
                              labelText: l10n.plantFamily,
                              icon: Icons.family_restroom,
                            ),
                          ),
                          spacing.vMd,
                          TextField(
                            controller: nickNameController,
                            style: inputs.textStyle,
                            decoration: _fieldDecoration(
                              labelText: l10n.plantNickname,
                              icon: Icons.local_florist,
                            ),
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
                              icon: Icons.water_drop,
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
                              icon: Icons.eco_outlined,
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
                        onPressed: isLoading ? null : updatePlant,
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
                                l10n.plantSaveChanges,
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
