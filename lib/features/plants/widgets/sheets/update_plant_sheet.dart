import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:plontukrot/l10n/app_localizations.dart';

import '../../../../core/theme/theme_context.dart';
import '../../../../models/plant.dart';
import '../../../../models/plant_member.dart';
import '../../../../models/variegation.dart';
import '../../../../core/season/fertilizing_season_controller.dart';
import '../../../../models/fertilizing_frequency.dart';
import '../../../../services/plant_service.dart';
import '../selectors/fertilizing_frequency_field.dart';
import '../selectors/plant_stage_selector.dart';
import '../selectors/plant_variegation_selector.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:plontukrot/core/widgets/accessible_progress_indicator.dart';
import 'package:plontukrot/core/widgets/sheet_drag_handle.dart';

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

class _MemberEditors {
  final TextEditingController cultivar;
  Variegation variegation;
  final String? sourcePlantId;

  _MemberEditors({
    required this.cultivar,
    required this.variegation,
    this.sourcePlantId,
  });

  void dispose() => cultivar.dispose();
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
  late final List<_MemberEditors> _members;

  bool isLoading = false;
  int selectedStage = 0;
  Variegation selectedVariegation = Variegation.none;
  int? fertilizingFrequencyDays;
  bool isFertilizingFrequencyCustom = false;
  String? genusError;
  String? speciesError;

  bool get _isGroup => widget.plant.isGroup;

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
    isFertilizingFrequencyCustom = widget.plant.isFertilizingFrequencyCustom;
    // Legacy plants predate the frequency field (null in Firestore). For
    // non-custom plants, resolve the auto value from the current season/stage
    // instead of showing a bare STOP.
    fertilizingFrequencyDays = isFertilizingFrequencyCustom
        ? widget.plant.fertilizingFrequencyDays
        : resolveFertilizingFrequencyDays(
            stage: selectedStage,
            seasonSettings: FertilizingSeasonController.instance.settings,
            isCustom: false,
            currentFrequencyDays: null,
          );
    selectedVariegation = widget.plant.variegation;

    _members = widget.plant.members.map((member) {
      return _MemberEditors(
        cultivar: TextEditingController(text: member.cultivar ?? ''),
        variegation: member.variegation,
        sourcePlantId: member.sourcePlantId,
      );
    }).toList();
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
    for (final member in _members) {
      member.dispose();
    }
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

    if (fertilizingFrequencyDays != null &&
        fertilizingFrequencyDays != fertilizingFrequencyStop &&
        (fertilizingFrequencyDays! < 1 ||
            fertilizingFrequencyDays! > 180)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.plantInvalidFertilizingFrequency)),
      );
      return;
    }

    List<PlantMember>? members;
    if (_isGroup) {
      members = _members
          .map(
            (m) => PlantMember(
              cultivar: m.cultivar.text.trim().isEmpty
                  ? null
                  : m.cultivar.text.trim(),
              variegation: m.variegation,
              sourcePlantId: m.sourcePlantId,
            ),
          )
          .toList();
      if (members.length < 2) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.plantMergeMembersRequired)),
        );
        return;
      }
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
        cultivar: _isGroup ? null : (cultivar.isEmpty ? null : cultivar),
        plantFamily: plantFamily.isEmpty ? null : plantFamily,
        variegation: _isGroup ? Variegation.none : selectedVariegation,
        tradingName: tradingName,
        nickname: nickname,
        wateringFrequency: wateringFrequency,
        initialLeafCount: initialLeafCount,
        stage: selectedStage,
        members: members,
        fertilizingFrequencyDays: fertilizingFrequencyDays,
        isFertilizingFrequencyCustom: isFertilizingFrequencyCustom,
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
                  Center(child: const SheetDragHandle()),
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
                          if (_isGroup) ...[
                            Text(
                              l10n.plantGroupMembers,
                              style: typography.label.copyWith(
                                color: colors.textSecondary,
                              ),
                            ),
                            spacing.vSm,
                            for (var i = 0; i < _members.length; i++) ...[
                              Text(
                                l10n.plantMergeMemberLabel(i + 1),
                                style: typography.bodyMedium,
                              ),
                              spacing.vXs,
                              TextField(
                                controller: _members[i].cultivar,
                                style: inputs.textStyle,
                                decoration: _fieldDecoration(
                                  labelText: l10n.plantCultivar,
                                  prefixIcon: _materialPrefixIcon(Icons.spa_outlined),
                                ),
                              ),
                              spacing.vSm,
                              PlantVariegationSelector(
                                selected: _members[i].variegation,
                                onChanged: (value) {
                                  setState(() {
                                    _members[i].variegation = value;
                                  });
                                },
                              ),
                              if (i < _members.length - 1) spacing.vMd,
                            ],
                          ] else ...[
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
                          ],
                          spacing.vMd,
                          TextField(
                            controller: tradingNameController,
                            style: inputs.textStyle,
                            decoration: _fieldDecoration(
                              labelText: l10n.plantTradingName,
                              prefixIcon: _materialPrefixIcon(Icons.storefront_outlined),
                            ),
                          ),
                          spacing.vMd,
                          TextField(
                            controller: plantFamilyController,
                            style: inputs.textStyle,
                            decoration: _fieldDecoration(
                              labelText: l10n.plantFamily,
                              prefixIcon: _materialPrefixIcon(Icons.family_restroom),
                            ),
                          ),
                          spacing.vMd,
                          TextField(
                            controller: nickNameController,
                            style: inputs.textStyle,
                            decoration: _fieldDecoration(
                              labelText: l10n.plantNickname,
                              prefixIcon: _hugePrefixIcon(HugeIcons.strokeRoundedHouseHeart),
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
                                if (!isFertilizingFrequencyCustom) {
                                  fertilizingFrequencyDays =
                                      resolveFertilizingFrequencyDays(
                                    stage: value,
                                    seasonSettings: FertilizingSeasonController
                                        .instance.settings,
                                    isCustom: false,
                                    currentFrequencyDays: null,
                                  );
                                }
                              });
                            },
                          ),
                          spacing.vMd,
                          FertilizingFrequencyField(
                            stage: selectedStage,
                            frequencyDays: fertilizingFrequencyDays,
                            isCustom: isFertilizingFrequencyCustom,
                            onFrequencyChanged: (value) {
                              setState(() => fertilizingFrequencyDays = value);
                            },
                            onCustomChanged: (value) {
                              setState(
                                () => isFertilizingFrequencyCustom = value,
                              );
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
                        onPressed: isLoading ? null : updatePlant,
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
