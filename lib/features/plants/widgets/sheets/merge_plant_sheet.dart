import 'package:flutter/material.dart';
import 'package:plontukrot/l10n/app_localizations.dart';

import '../../../../core/theme/theme_context.dart';
import '../../../../models/plant.dart';
import '../../../../models/plant_member.dart';
import '../../../../models/variegation.dart';
import '../../../../services/plant_service.dart';
import '../selectors/plant_stage_selector.dart';
import '../selectors/plant_variegation_selector.dart';

class MergePlantSheet extends StatefulWidget {
  final List<Plant> sources;

  const MergePlantSheet({super.key, required this.sources});

  @override
  State<MergePlantSheet> createState() => _MergePlantSheetState();
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

class _MergePlantSheetState extends State<MergePlantSheet> {
  late final TextEditingController genusController;
  late final TextEditingController speciesController;
  late final TextEditingController plantFamilyController;
  late final TextEditingController tradingNameController;
  final nickNameController = TextEditingController();
  late final List<_MemberEditors> _members;

  bool isLoading = false;
  int selectedStage = 0;
  String? genusError;
  String? speciesError;

  @override
  void initState() {
    super.initState();
    final sources = widget.sources;
    final genus = sources.first.genus;
    final speciesSet = sources.map((p) => p.species.trim()).toSet();
    final familySet = sources
        .map((p) => (p.plantFamily ?? '').trim())
        .where((f) => f.isNotEmpty)
        .toSet();

    genusController = TextEditingController(text: genus);
    speciesController = TextEditingController(
      text: speciesSet.length == 1 ? speciesSet.first : '',
    );
    plantFamilyController = TextEditingController(
      text: familySet.length == 1 ? familySet.first : '',
    );
    tradingNameController = TextEditingController();

    _members = sources.map((plant) {
      return _MemberEditors(
        cultivar: TextEditingController(text: plant.cultivar ?? ''),
        variegation: plant.variegation,
        sourcePlantId: plant.id,
      );
    }).toList();
  }

  @override
  void dispose() {
    genusController.dispose();
    speciesController.dispose();
    plantFamilyController.dispose();
    tradingNameController.dispose();
    nickNameController.dispose();
    for (final member in _members) {
      member.dispose();
    }
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

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final genus = genusController.text.trim();
    final species = speciesController.text.trim();
    final plantFamily = plantFamilyController.text.trim();
    final tradingName = tradingNameController.text.trim();
    final nickname = nickNameController.text.trim();

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

    final members = _members
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

    setState(() {
      isLoading = true;
      genusError = null;
      speciesError = null;
    });

    try {
      await PlantService().mergePlants(
        sources: widget.sources,
        genus: genus,
        species: species,
        plantFamily: plantFamily.isEmpty ? null : plantFamily,
        members: members,
        tradingName: tradingName,
        nickname: nickname,
        stage: selectedStage,
      );
      if (mounted) Navigator.pop(context, true);
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
                      l10n.plantMergeTitle,
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
                            controller: plantFamilyController,
                            style: inputs.textStyle,
                            decoration: _fieldDecoration(
                              labelText: l10n.plantFamily,
                              icon: Icons.family_restroom,
                            ),
                          ),
                          spacing.vMd,
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
                                icon: Icons.spa_outlined,
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
                            controller: nickNameController,
                            style: inputs.textStyle,
                            decoration: _fieldDecoration(
                              labelText: l10n.plantNickname,
                              icon: Icons.local_florist,
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
                              setState(() => selectedStage = value);
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
                        onPressed: isLoading ? null : _save,
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
