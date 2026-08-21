import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:plontukrot/l10n/app_localizations.dart';

import '../../../../core/theme/theme_context.dart';
import '../../../../models/variegation.dart';
import '../../../../core/season/fertilizing_season_controller.dart';
import '../../../../models/fertilizing_frequency.dart';
import '../../../../services/plant_service.dart';
import '../../../../services/storage_service.dart';
import '../../../../services/wish_list_service.dart';
import '../common/pick_and_crop_plant_photo.dart';
import '../common/plant_pending_photo_control.dart';
import '../selectors/fertilizing_frequency_field.dart';
import '../selectors/plant_stage_selector.dart';
import '../selectors/plant_variegation_selector.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:plontukrot/core/widgets/accessible_progress_indicator.dart';
import 'package:plontukrot/core/widgets/sheet_drag_handle.dart';

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
  int? fertilizingFrequencyDays;
  bool isFertilizingFrequencyCustom = false;
  String? genusError;
  String? speciesError;
  Uint8List? _pendingPhotoBytes;

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
    wateringFrequencyController = TextEditingController(
      text: selectedStage == 0 ? '0' : '',
    );
    initialLeafCountController = TextEditingController(text: '0');
    fertilizingFrequencyDays = resolveFertilizingFrequencyDays(
      stage: selectedStage,
      seasonSettings: FertilizingSeasonController.instance.settings,
      isCustom: false,
      currentFrequencyDays: null,
    );
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

  Future<void> _pickPhoto() async {
    final bytes = await pickAndCropPlantPhoto(context);
    if (bytes == null || !mounted) return;
    setState(() => _pendingPhotoBytes = bytes);
  }

  Future<void> _uploadPendingPhoto(String plantId) async {
    final bytes = _pendingPhotoBytes;
    if (bytes == null) return;
    final upload = await StorageService().uploadPlantPhoto(
      imageBytes: bytes,
      plantId: plantId,
    );
    await PlantService().addPlantPhoto(
      plantId: plantId,
      photoId: upload.photoId,
      imageUrl: upload.imageUrl,
      imageThumbUrl: upload.imageThumbUrl,
    );
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

    if (mounted) {
      setState(() {
        isLoading = true;
        genusError = null;
        speciesError = null;
      });
    }

    try {
      final plantId = await PlantService().addPlant(
        genus: genus,
        species: species,
        cultivar: cultivar.isEmpty ? null : cultivar,
        plantFamily: plantFamily.isEmpty ? null : plantFamily,
        variegation: selectedVariegation,
        tradingName: tradingName,
        nickname: nickname,
        stage: selectedStage,
        initialLeafCount: initialLeafCount,
        wateringFrequency: wateringFrequency,
        fertilizingFrequencyDays: fertilizingFrequencyDays,
        isFertilizingFrequencyCustom: isFertilizingFrequencyCustom,
      );

      Object? photoError;
      try {
        await _uploadPendingPhoto(plantId);
      } catch (e) {
        photoError = e;
      }

      final wishListItemId = widget.wishListItemId;
      if (wishListItemId != null) {
        await WishListService().deleteItem(wishListItemId);
      }

      if (!mounted) return;
      if (photoError != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.plantUploadError(photoError.toString()))),
        );
      }
      Navigator.pop(context);
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
                          PlantPendingPhotoControl(
                            hasPhoto: _pendingPhotoBytes != null,
                            onPick: _pickPhoto,
                          ),
                          spacing.vMd,
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
                              prefixIcon: _materialPrefixIcon(context.icons.genus),
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
                              prefixIcon: _materialPrefixIcon(context.icons.species),
                            ),
                          ),
                          spacing.vMd,
                          TextField(
                            controller: cultivarController,
                            style: inputs.textStyle,
                            decoration: _fieldDecoration(
                              labelText: l10n.plantCultivar,
                              prefixIcon: _materialPrefixIcon(context.icons.cultivar),
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
                                  _materialPrefixIcon(context.icons.tradingName),
                            ),
                          ),
                          spacing.vMd,
                          TextField(
                            controller: plantFamilyController,
                            style: inputs.textStyle,
                            decoration: _fieldDecoration(
                              labelText: l10n.plantFamily,
                              prefixIcon:
                                  _materialPrefixIcon(context.icons.family),
                            ),
                          ),
                          spacing.vMd,
                          TextField(
                            controller: nickNameController,
                            style: inputs.textStyle,
                            decoration: _fieldDecoration(
                              labelText: l10n.plantNickname,
                              prefixIcon: _hugePrefixIcon(
                                context.icons.nickname,
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
                                if (value == 0) {
                                  wateringFrequencyController.text = '0';
                                }
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
                              prefixIcon: _materialPrefixIcon(context.icons.wateringFilled),
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
                                context.icons.leaf,
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
