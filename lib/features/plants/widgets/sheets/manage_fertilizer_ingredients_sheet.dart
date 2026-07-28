import 'package:flutter/material.dart';

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
    return showPromptTextDialog(
      context: context,
      title: title,
      initial: initial,
      hintText: 'Название ингредиента',
      confirmLabel: 'Сохранить',
    );
  }

  Future<void> _add() async {
    final name = await _promptName(title: 'Добавить ингредиент');
    if (name == null) return;
    await _service.addIngredient(name: name);
  }

  Future<void> _edit(FertilizerIngredient ingredient) async {
    final name = await _promptName(
      title: 'Изменить ингредиент',
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.backgroundSecondary,
          title: const Text('Удалить ингредиент'),
          content: Text('Удалить «${ingredient.name}» из каталога?'),
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
    await _service.deleteIngredient(ingredient.id);
    widget.onDeleted?.call(ingredient.name);
  }

  @override
  Widget build(BuildContext context) {
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
                const Text(
                  'Ингредиенты удобрений',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: _add,
                  icon: const Icon(Icons.add),
                  label: const Text('Добавить'),
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
                    return const Center(child: Text('Пока нет ингредиентов'));
                  }

                  return ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(item.name),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'Изменить',
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: () => _edit(item),
                            ),
                            IconButton(
                              tooltip: 'Удалить',
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
