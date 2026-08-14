import 'package:plontukrot/l10n/app_localizations.dart';

import '../../models/fertilizer.dart';
import '../../models/fertilizer_application_method.dart';
import '../../models/fertilizer_dose.dart';
import '../../models/propagation_method.dart';
import '../../models/propagation_outcome.dart';
import '../../models/propagation_status.dart';
import '../../models/stage_info.dart';
import '../../models/variegation.dart';

extension AppLocalizationsStage on AppLocalizations {
  String stageTitle(int stage) {
    return switch (stage) {
      1 => stageStart,
      2 => stageBaby,
      3 => stageJuvenile,
      4 => stageAdult,
      _ => stageUnknown,
    };
  }

  List<String> stageChecklist(int stage) {
    return switch (stage) {
      1 => [
          stageStartCheck1,
          stageStartCheck2,
          stageStartCheck3,
          stageStartCheck4,
        ],
      2 => [
          stageBabyCheck1,
          stageBabyCheck2,
          stageBabyCheck3,
        ],
      3 => [
          stageJuvenileCheck1,
          stageJuvenileCheck2,
          stageJuvenileCheck3,
        ],
      4 => [
          stageAdultCheck1,
          stageAdultCheck2,
          stageAdultCheck3,
        ],
      _ => const <String>[],
    };
  }

  String stageInfoTitle(StageInfo stage) => stageTitle(stage.value);

  String fertilizingStageGenitive(int stage) {
    final normalized = stage <= 0 ? 1 : (stage > 4 ? 4 : stage);
    return switch (normalized) {
      1 => fertilizingStageGenitiveStart,
      2 => fertilizingStageGenitiveBaby,
      3 => fertilizingStageGenitiveJuvenile,
      4 => fertilizingStageGenitiveAdult,
      _ => fertilizingStageGenitiveStart,
    };
  }

  String propagationMethodLabel(PropagationMethod method) {
    return switch (method) {
      PropagationMethod.leaf => propagationMethodLeaf,
      PropagationMethod.leafFragment => propagationMethodLeafFragment,
      PropagationMethod.rhizome => propagationMethodRhizome,
      PropagationMethod.tuber => propagationMethodTuber,
      PropagationMethod.division => propagationMethodDivision,
      PropagationMethod.offset => propagationMethodOffset,
      PropagationMethod.cutting => propagationMethodCutting,
      PropagationMethod.microcloning => propagationMethodMicrocloning,
    };
  }

  String propagationMethodPlural(PropagationMethod method) {
    return switch (method) {
      PropagationMethod.leaf => propagationMethodLeafPlural,
      PropagationMethod.leafFragment => propagationMethodLeafFragmentPlural,
      PropagationMethod.rhizome => propagationMethodRhizomePlural,
      PropagationMethod.tuber => propagationMethodTuberPlural,
      PropagationMethod.division => propagationMethodDivisionPlural,
      PropagationMethod.offset => propagationMethodOffsetPlural,
      PropagationMethod.cutting => propagationMethodCuttingPlural,
      PropagationMethod.microcloning => propagationMethodMicrocloningPlural,
    };
  }

  String propagationStatusLabel(PropagationStatus status) {
    return switch (status) {
      PropagationStatus.active => propagationStatusActive,
      PropagationStatus.sold => propagationStatusSold,
      PropagationStatus.gifted => propagationStatusGifted,
      PropagationStatus.traded => propagationStatusTraded,
      PropagationStatus.lost => propagationStatusLost,
    };
  }

  String propagationOutcomeLabel(PropagationOutcome outcome) {
    return switch (outcome) {
      PropagationOutcome.sold => propagationSell,
      PropagationOutcome.gifted => propagationGift,
      PropagationOutcome.traded => propagationTrade,
      PropagationOutcome.lost => propagationLose,
    };
  }

  String variegationLabelOf(Variegation value) {
    return switch (value) {
      Variegation.none => variegationNone,
      Variegation.aurea => variegationAurea,
      Variegation.alba => variegationAlba,
      Variegation.pink => variegationPink,
      Variegation.splash => variegationSplash,
      Variegation.mint => variegationMint,
      Variegation.multicolor => variegationMulticolor,
      Variegation.tricolor => variegationTricolor,
      Variegation.unknown => variegationUnknown,
    };
  }

  String fertilizerKindLabel(FertilizerKind kind) {
    return switch (kind) {
      FertilizerKind.mix => fertilizerKindMix,
      FertilizerKind.purchased => fertilizerKindPurchased,
    };
  }

  String applicationMethodLabel(FertilizerApplicationMethod method) {
    return switch (method) {
      FertilizerApplicationMethod.root => fertilizingRoot,
      FertilizerApplicationMethod.foliar => fertilizingFoliar,
    };
  }

  String doseUnitLabel(FertilizerDoseUnit unit) {
    return unit == FertilizerDoseUnit.ml ? unitMl : unitGrams;
  }

  String fertilizerDoseLabel(FertilizerDose dose) {
    // `component` is usually UGC. Legacy/system purchased dose used Russian
    // "Доза" / language-neutral "dose" as a placeholder — map those in UI only.
    final raw = dose.component.trim();
    final name = (raw == 'dose' || raw == 'Доза')
        ? fertilizerDoseLabelPurchased
        : dose.component;
    return '$name · ${dose.amountLabel}${doseUnitLabel(dose.unit)}';
  }

  /// Resolve display label for a fertilizer snapshot without rewriting UGC.
  ///
  /// If [storedName] is present (user/catalog name), return it as-is.
  /// Otherwise show localized app fallback based on whether a catalog id exists.
  String fertilizerDisplayName({
    String? storedName,
    String? fertilizerId,
  }) {
    final trimmed = storedName?.trim();
    if (trimmed != null && trimmed.isNotEmpty) return trimmed;
    if (fertilizerId != null && fertilizerId.isNotEmpty) {
      return fertilizerUnknown;
    }
    return fertilizerCustomMix;
  }

  String soilDisplayName(String? soilName) {
    final trimmed = soilName?.trim();
    if (trimmed != null && trimmed.isNotEmpty) return trimmed;
    return soilCustomMix;
  }
}
