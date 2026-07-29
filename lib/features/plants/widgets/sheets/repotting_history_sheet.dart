import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../models/repotting_entry.dart';
import '../../../../services/repotting_service.dart';
import '../dialogs/soil_composition_dialog.dart';
import 'add_repotting_sheet.dart';

class RepottingHistorySheet extends StatefulWidget {
  final String plantId;

  const RepottingHistorySheet({super.key, required this.plantId});

  @override
  State<RepottingHistorySheet> createState() => _RepottingHistorySheetState();
}

class _RepottingHistorySheetState extends State<RepottingHistorySheet> {
  final RepottingService _service = RepottingService();

  Future<void> _showAddSheet() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => AddRepottingSheet(plantId: widget.plantId),
    );
  }

  Future<void> _showEditSheet(RepottingEntry entry) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => AddRepottingSheet.edit(
        plantId: widget.plantId,
        entry: entry,
      ),
    );
  }

  Future<void> _confirmDelete(String repottingId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Удалить пересадку'),
          content: const Text('Удалить эту запись?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Отмена'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Удалить'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    await _service.deleteRepotting(
      plantId: widget.plantId,
      repottingId: repottingId,
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
              const Expanded(
                child: Text(
                  'История пересадок',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: _showAddSheet,
                icon: const Icon(Icons.add),
                label: const Text('Добавить'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: StreamBuilder<List<RepottingEntry>>(
              stream: _service.getRepottingHistory(widget.plantId),
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
                    child: Text('Пока нет записей о пересадке'),
                  );
                }

                return ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final repottingId = item.id!;
                    final title = (item.soilName?.isNotEmpty == true)
                        ? item.soilName!
                        : 'Свой микс';

                    return InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        showSoilCompositionDialog(
                          context: context,
                          title: title,
                          components: item.components,
                        );
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
                              Icons.flaky,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    DateFormat('d MMMM y')
                                        .format(item.repottedAt),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                                  ),
                                  if (item.slowReleaseFertilizer) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Пролонгированное удобрение',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            IconButton(
                              tooltip: 'Изменить',
                              visualDensity: VisualDensity.compact,
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: () => _showEditSheet(item),
                            ),
                            IconButton(
                              tooltip: 'Удалить',
                              visualDensity: VisualDensity.compact,
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => _confirmDelete(repottingId),
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
