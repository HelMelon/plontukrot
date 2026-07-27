import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../models/fertilizing_entry.dart';
import '../../../../services/fertilize_service.dart';
import '../fertilizer_composition_dialog.dart';
import 'add_fertilizing_sheet.dart';

class FertilizingHistorySheet extends StatefulWidget {
  final String plantId;

  const FertilizingHistorySheet({super.key, required this.plantId});

  @override
  State<FertilizingHistorySheet> createState() =>
      _FertilizingHistorySheetState();
}

class _FertilizingHistorySheetState extends State<FertilizingHistorySheet> {
  final FertilizeService _service = FertilizeService();
  String? _deleteModeId;

  Future<void> _showAddSheet() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => AddFertilizingSheet.forPlant(plantId: widget.plantId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade400,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text(
                'Fertilizing history',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: _showAddSheet,
                icon: const Icon(Icons.add),
                label: const Text('Add'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: StreamBuilder<List<FertilizingEntry>>(
              stream: _service.getFertilizingHistory(widget.plantId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text(snapshot.error.toString()));
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final items = snapshot.data!;

                if (items.isEmpty) {
                  return const Center(child: Text('No fertilizing yet'));
                }

                return ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = items[index];

                    return GestureDetector(
                      onTap: () {
                        showFertilizerCompositionDialog(
                          context: context,
                          title: item.fertilizerName,
                          components: item.components,
                          waterMl: item.waterMl,
                        );
                      },
                      onLongPress: () {
                        setState(() {
                          if (_deleteModeId == item.id) {
                            _deleteModeId = null;
                          } else {
                            _deleteModeId = item.id;
                          }
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.science,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.fertilizerName,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    DateFormat('d MMMM y')
                                        .format(item.appliedAt),
                                  ),
                                ],
                              ),
                            ),
                            if (_deleteModeId == item.id)
                              IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () async {
                                  final confirmed = await showDialog<bool>(
                                    context: context,
                                    builder: (context) {
                                      return AlertDialog(
                                        title: const Text('Delete fertilizing'),
                                        content: const Text(
                                          'Delete this record?',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, false),
                                            child: const Text('Cancel'),
                                          ),
                                          FilledButton(
                                            onPressed: () =>
                                                Navigator.pop(context, true),
                                            child: const Text('Delete'),
                                          ),
                                        ],
                                      );
                                    },
                                  );

                                  if (confirmed != true) return;

                                  await _service.deleteFertilizing(
                                    plantId: widget.plantId,
                                    fertilizingId: item.id,
                                  );

                                  if (mounted) {
                                    setState(() => _deleteModeId = null);
                                  }
                                },
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
