import 'propagation_method.dart';

/// Stage values used by propagation (shared with [stageInfos]).
const int propagationStageStart = 1;
const int propagationStageBaby = 2;
const int propagationStageJuvenile = 3;

/// Whether the user must pick Детка / Ювенил when creating a batch.
bool requiresInitialStageChoice(PropagationMethod method) {
  return method == PropagationMethod.division;
}

/// Initial stage for a new propagation batch.
///
/// [divisionStage] is required when [method] is [PropagationMethod.division]
/// and must be [propagationStageBaby] or [propagationStageJuvenile].
int initialStageFor(
  PropagationMethod method, {
  int? divisionStage,
}) {
  switch (method) {
    case PropagationMethod.offset:
      return propagationStageBaby;
    case PropagationMethod.division:
      final stage = divisionStage ?? propagationStageBaby;
      if (stage != propagationStageBaby && stage != propagationStageJuvenile) {
        return propagationStageBaby;
      }
      return stage;
    case PropagationMethod.leaf:
    case PropagationMethod.leafFragment:
    case PropagationMethod.rhizome:
    case PropagationMethod.tuber:
    case PropagationMethod.cutting:
      return propagationStageStart;
  }
}
