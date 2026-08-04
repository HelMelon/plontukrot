import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:plontukrot/l10n/app_localizations.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
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
    return InputDecoration(
      labelText: labelText,
      errorText: errorText,
      labelStyle: const TextStyle(color: AppColors.textSecondary),
      filled: true,
      fillColor: AppColors.dark2,
      prefixIcon: Icon(icon, color: AppColors.accentLight),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: AppColors.greenDeep),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(
          color: AppColors.goldAccent,
          width: 1.5,
        ),
      ),
    );
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

    return AnimatedPadding(
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: Material(
            color: AppColors.backgroundSecondary,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            clipBehavior: Clip.antiAlias,
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  Center(
                    child: Container(
                      width: 50,
                      height: 5,
                      decoration: BoxDecoration(
                        color: AppColors.greenSoft,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 16, 22, 0),
                    child: Text(
                      l10n.plantEdit,
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -1,
                        color: AppColors.heading,
                      ),
                    ),
                  ),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(22, 16, 22, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                            controller: genusController,
                            style:
                                const TextStyle(color: AppColors.textPrimary),
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
                          const SizedBox(height: 18),
                          TextField(
                            controller: speciesController,
                            style:
                                const TextStyle(color: AppColors.textPrimary),
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
                          const SizedBox(height: 18),
                          TextField(
                            controller: cultivarController,
                            style:
                                const TextStyle(color: AppColors.textPrimary),
                            decoration: _fieldDecoration(
                              labelText: l10n.plantCultivar,
                              icon: Icons.spa_outlined,
                            ),
                          ),
                          const SizedBox(height: 18),
                          PlantVariegationSelector(
                            selected: selectedVariegation,
                            onChanged: (value) {
                              setState(() => selectedVariegation = value);
                            },
                          ),
                          const SizedBox(height: 18),
                          TextField(
                            controller: tradingNameController,
                            style:
                                const TextStyle(color: AppColors.textPrimary),
                            decoration: _fieldDecoration(
                              labelText: l10n.plantTradingName,
                              icon: Icons.storefront_outlined,
                            ),
                          ),
                          const SizedBox(height: 18),
                          TextField(
                            controller: plantFamilyController,
                            style:
                                const TextStyle(color: AppColors.textPrimary),
                            decoration: _fieldDecoration(
                              labelText: l10n.plantFamily,
                              icon: Icons.family_restroom,
                            ),
                          ),
                          const SizedBox(height: 18),
                          TextField(
                            controller: nickNameController,
                            style:
                                const TextStyle(color: AppColors.textPrimary),
                            decoration: _fieldDecoration(
                              labelText: l10n.plantNickname,
                              icon: Icons.local_florist,
                            ),
                          ),
                          const SizedBox(height: 18),
                          TextField(
                            controller: wateringFrequencyController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            style:
                                const TextStyle(color: AppColors.textPrimary),
                            decoration: _fieldDecoration(
                              labelText: l10n.plantWateringFrequency,
                              icon: Icons.water_drop,
                            ),
                          ),
                          const SizedBox(height: 18),
                          TextField(
                            controller: initialLeafCountController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            style:
                                const TextStyle(color: AppColors.textPrimary),
                            decoration: _fieldDecoration(
                              labelText: l10n.plantInitialLeafCount,
                              icon: Icons.eco_outlined,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            l10n.plantGrowthStage,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 10),
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
                    padding: const EdgeInsets.fromLTRB(22, 8, 22, 16),
                    child: SizedBox(
                      width: double.infinity,
                      height: AppTheme.buttonHeight,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : updatePlant,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.goldAccent,
                          foregroundColor: AppColors.dark1,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.dark1,
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
