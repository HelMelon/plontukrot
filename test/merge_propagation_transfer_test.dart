import 'package:flutter_test/flutter_test.dart';
import 'package:plontukrot/models/merge_propagation_transfer.dart';
import 'package:plontukrot/models/propagation.dart';
import 'package:plontukrot/models/propagation_method.dart';
import 'package:plontukrot/models/propagation_status.dart';

Propagation _batch({
  required String id,
  required String parentPlantId,
  PropagationStatus status = PropagationStatus.active,
}) {
  return Propagation(
    id: id,
    parentPlantId: parentPlantId,
    parentPlantName: 'Hoya',
    parentPlantFamily: '',
    method: PropagationMethod.cutting,
    quantity: 2,
    quantityAlive: status == PropagationStatus.active ? 2 : 0,
    soldQuantity: status == PropagationStatus.sold ? 2 : 0,
    giftedQuantity: 0,
    tradedQuantity: 0,
    lostQuantity: 0,
    stage: 1,
    status: status,
    startedAt: DateTime(2026, 1, 1),
  );
}

void main() {
  const sources = ['plant-a', 'plant-b'];

  final batches = [
    _batch(id: 'active-a', parentPlantId: 'plant-a'),
    _batch(
      id: 'sold-b',
      parentPlantId: 'plant-b',
      status: PropagationStatus.sold,
    ),
    _batch(id: 'other', parentPlantId: 'plant-c'),
    _batch(id: 'orphan', parentPlantId: ''),
  ];

  group('propagationBatchesOnSourcePlants', () {
    test('keeps every batch of the plants being merged away', () {
      final owned = propagationBatchesOnSourcePlants(
        batches: batches,
        sourcePlantIds: sources,
      );
      expect(owned.map((batch) => batch.id), ['active-a', 'sold-b']);
    });

    test('is empty when no source has a batch', () {
      final owned = propagationBatchesOnSourcePlants(
        batches: batches,
        sourcePlantIds: const ['plant-d'],
      );
      expect(owned, isEmpty);
      expect(shouldAskToTransferPropagations(owned), isFalse);
    });

    test('ignores blank source ids', () {
      final owned = propagationBatchesOnSourcePlants(
        batches: batches,
        sourcePlantIds: const [''],
      );
      expect(owned, isEmpty);
    });
  });

  group('propagationBatchesToTransferOnMerge', () {
    test('asks only when a source plant has batches', () {
      final owned = propagationBatchesOnSourcePlants(
        batches: batches,
        sourcePlantIds: sources,
      );
      expect(shouldAskToTransferPropagations(owned), isTrue);
      expect(shouldAskToTransferPropagations(const []), isFalse);
    });

    test('confirm reassigns those batches onto the surviving plant', () {
      final moved = propagationBatchesToTransferOnMerge(
        batches: batches,
        sourcePlantIds: sources,
        transfer: true,
      );
      expect(moved.map((batch) => batch.id), ['active-a', 'sold-b']);
    });

    test('decline leaves current parents unchanged', () {
      final moved = propagationBatchesToTransferOnMerge(
        batches: batches,
        sourcePlantIds: sources,
        transfer: false,
      );
      expect(moved, isEmpty);
    });
  });
}
