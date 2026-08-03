import 'package:flutter/material.dart';
import 'package:plontukrot/l10n/app_localizations.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/prompt_text_dialog.dart';
import '../../../../models/catalog_component.dart';
import '../../../../services/component_service.dart';

class ManageComponentsSheet extends StatefulWidget {
  final void Function(String oldName, String newName)? onRenamed;
  final void Function(String name)? onDeleted;

  const ManageComponentsSheet({
    super.key,
    this.onRenamed,
    this.onDeleted,
  });

  @override
  State<ManageComponentsSheet> createState() => _ManageComponentsSheetState();
}

class _ManageComponentsSheetState extends State<ManageComponentsSheet> {
  final _service = ComponentService();

  Future<String?> _promptName({
    required String title,
    String initial = '',
  }) {
    final l10n = AppLocalizations.of(context);
    return showPromptTextDialog(
      context: context,
      title: title,
      initial: initial,
      hintText: l10n.componentNameHint,
      confirmLabel: l10n.commonSave,
    );
  }

  Future<void> _add() async {
    final l10n = AppLocalizations.of(context);
    final name = await _promptName(title: l10n.componentAddTitle);
    if (name == null) return;
    await _service.addComponent(name: name);
  }

  Future<void> _edit(CatalogComponent component) async {
    final l10n = AppLocalizations.of(context);
    final name = await _promptName(
      title: l10n.componentEditTitle,
      initial: component.name,
    );
    if (name == null || name == component.name) return;
    await _service.updateComponent(
      componentId: component.id,
      name: name,
    );
    widget.onRenamed?.call(component.name, name);
  }

  Future<void> _delete(CatalogComponent component) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.backgroundSecondary,
          title: Text(l10n.componentDeleteTitle),
          content: Text(l10n.catalogItemDeleteConfirm(component.name)),
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
    await _service.deleteComponent(component.id);
    widget.onDeleted?.call(component.name);
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
                    l10n.soilComponentsTitle,
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
              child: StreamBuilder<List<CatalogComponent>>(
                stream: _service.getComponents(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text(snapshot.error.toString()));
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final items = snapshot.data!;
                  if (items.isEmpty) {
                    return Center(child: Text(l10n.emptyComponents));
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
