import 'package:flutter/material.dart';
import 'package:plontukrot/l10n/app_localizations.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/prompt_text_dialog.dart';
import '../../../../models/fertilizer_ingredient.dart';
import '../../../../services/fertilize_service.dart';

class ManageFertilizerIngredientsSheet extends StatefulWidget {
  final void Function(String oldName, String newName)? onRenamed;
  final void Function(String name)? onDeleted;

  const ManageFertilizerIngredientsSheet({
    super.key,
    this.onRenamed,
    this.onDeleted,
  });

  @override
  State<ManageFertilizerIngredientsSheet> createState() =>
      _ManageFertilizerIngredientsSheetState();
}

class _ManageFertilizerIngredientsSheetState
    extends State<ManageFertilizerIngredientsSheet> {
  final _service = FertilizeService();

  Future<String?> _promptName({
    required String title,
    String initial = '',
  }) {
    final l10n = AppLocalizations.of(context);
    return showPromptTextDialog(
      context: context,
      title: title,
      initial: initial,
      hintText: l10n.fertilizingIngredientNameHint,
      confirmLabel: l10n.commonSave,
    );
  }

  Future<void> _add() async {
    final l10n = AppLocalizations.of(context);
    final name = await _promptName(title: l10n.fertilizingAddIngredient);
    if (name == null) return;
    await _service.addIngredient(name: name);
  }

  Future<void> _edit(FertilizerIngredient ingredient) async {
    final l10n = AppLocalizations.of(context);
    final name = await _promptName(
      title: l10n.ingredientEditTitle,
      initial: ingredient.name,
    );
    if (name == null || name == ingredient.name) return;
    await _service.updateIngredient(
      ingredientId: ingredient.id,
      name: name,
    );
    widget.onRenamed?.call(ingredient.name, name);
  }

  Future<void> _delete(FertilizerIngredient ingredient) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.backgroundSecondary,
          title: Text(l10n.ingredientDeleteTitle),
          content: Text(l10n.catalogItemDeleteConfirm(ingredient.name)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.commonCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.commonDelete),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;
    await _service.deleteIngredient(ingredient.id);
    widget.onDeleted?.call(ingredient.name);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

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
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.manageFertilizerIngredientsTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: _add,
                  icon: const Icon(Icons.add),
                  label: Text(l10n.commonAdd),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.45,
              child: StreamBuilder<List<FertilizerIngredient>>(
                stream: _service.getIngredients(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text(snapshot.error.toString()));
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final items = snapshot.data!;
                  if (items.isEmpty) {
                    return Center(child: Text(l10n.emptyIngredients));
                  }

                  return ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          item.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: l10n.commonEdit,
                              visualDensity: VisualDensity.compact,
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: () => _edit(item),
                            ),
                            IconButton(
                              tooltip: l10n.commonDelete,
                              visualDensity: VisualDensity.compact,
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => _delete(item),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
