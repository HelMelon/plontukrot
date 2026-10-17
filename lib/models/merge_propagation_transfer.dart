import 'propagation.dart';

/// Propagation batches whose parent is one of the plants being merged away.
///
/// Includes every status. Decline leaves these records on their current parent.
List<Propagation> propagationBatchesOnSourcePlants({
  required Iterable<Propagation> batches,
  required Iterable<String> sourcePlantIds,
}) {
  final ids = <String>{
    for (final id in sourcePlantIds)
      if (id.isNotEmpty) id,
  };
  if (ids.isEmpty) return <Propagation>[];
  return [
    for (final batch in batches)
      if (batch.parentPlantId.isNotEmpty && ids.contains(batch.parentPlantId))
        batch,
  ];
}

/// Whether the merge sheet should ask before archiving [batchesOnSources].
bool shouldAskToTransferPropagations(Iterable<Propagation> batchesOnSources) {
  return batchesOnSources.isNotEmpty;
}

/// Batches to reassign onto the surviving group.
///
/// When [transfer] is false the list is empty, so parent links stay as they are.
List<Propagation> propagationBatchesToTransferOnMerge({
  required Iterable<Propagation> batches,
  required Iterable<String> sourcePlantIds,
  required bool transfer,
}) {
  if (!transfer) return const [];
  return propagationBatchesOnSourcePlants(
    batches: batches,
    sourcePlantIds: sourcePlantIds,
  );
}
