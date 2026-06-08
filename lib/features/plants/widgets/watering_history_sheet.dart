import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../services/watering_service.dart';

class WateringHistorySheet extends StatefulWidget {
  final String plantId;

  const WateringHistorySheet({super.key, required this.plantId});

  @override
  State<WateringHistorySheet> createState() => _WateringHistorySheetState();
}

class _WateringHistorySheetState extends State<WateringHistorySheet> {
  final WateringService _service = WateringService();

  String? _deleteModeWateringId;

  Future<void> _showAddWateringSheet() async {
    DateTime selectedDate = DateTime.now();

    await showModalBottomSheet(
      context: context,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),

                    const SizedBox(height: 20),

                    const Text(
                      'Add Watering',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 20),

                    ListTile(
                      leading: const Icon(Icons.calendar_today),
                      title: Text(DateFormat('d MMMM y').format(selectedDate)),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );

                        if (picked != null) {
                          setModalState(() {
                            selectedDate = picked;
                          });
                        }
                      },
                    ),

                    const SizedBox(height: 16),

                    Row(
                      children: [
                        OutlinedButton(
                          onPressed: () {
                            setModalState(() {
                              selectedDate = DateTime.now();
                            });
                          },
                          child: const Text('Today'),
                        ),

                        const Spacer(),

                        FilledButton(
                          onPressed: () async {
                            await _service.addWatering(
                              plantId: widget.plantId,
                              wateredAt: selectedDate,
                            );

                            if (mounted) {
                              Navigator.pop(sheetContext);
                            }
                          },
                          child: const Text('Save'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
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
                'Watering History',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),

              const Spacer(),

              FilledButton.icon(
                onPressed: _showAddWateringSheet,
                icon: const Icon(Icons.add),
                label: const Text('Add watering'),
              ),
            ],
          ),

          const SizedBox(height: 20),

          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _service.getWateringHistory(widget.plantId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text(snapshot.error.toString()));
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final items = snapshot.data!;

                if (items.isEmpty) {
                  return const Center(
                    child: Text('No watering records yet 🌱'),
                  );
                }

                return ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final wateringId = item['id'] as String;
                    final wateredAt = item['wateredAt'] as DateTime;

                    return GestureDetector(
                      onLongPress: () {
                        setState(() {
                          if (_deleteModeWateringId == wateringId) {
                            _deleteModeWateringId = null;
                          } else {
                            _deleteModeWateringId = wateringId;
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
                              Icons.water_drop_rounded,
                              color: Theme.of(context).colorScheme.primary,
                            ),

                            const SizedBox(width: 12),

                            Expanded(
                              child: Text(
                                DateFormat('d MMMM y').format(wateredAt),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),

                            if (_deleteModeWateringId == wateringId)
                              IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () async {
                                  final confirmed = await showDialog<bool>(
                                    context: context,
                                    builder: (context) {
                                      return AlertDialog(
                                        title: const Text('Delete watering'),
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

                                  if (confirmed != true) {
                                    return;
                                  }

                                  await _service.deleteWatering(
                                    plantId: widget.plantId,
                                    wateringId: wateringId,
                                  );

                                  if (mounted) {
                                    setState(() {
                                      _deleteModeWateringId = null;
                                    });
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
