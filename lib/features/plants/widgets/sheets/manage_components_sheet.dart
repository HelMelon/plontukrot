import 'package:flutter/material.dart';
import 'package:plontukrot/l10n/app_localizations.dart';

import '../../../../core/theme/theme_context.dart';
import '../../../../core/widgets/prompt_text_dialog.dart';
import '../../../../models/catalog_component.dart';
import '../../../../services/component_service.dart';
import 'package:plontukrot/core/widgets/accessible_progress_indicator.dart';
import 'package:plontukrot/core/widgets/sheet_drag_handle.dart';
import 'package:plontukrot/core/widgets/app_modal.dart';

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

    final existing = await _service.findComponentByName(name);
    if (existing != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.catalogItemAlreadyExists(name))),
      );
      return;
    }

    await _service.addComponent(name: name);
  }

  Future<void> _edit(CatalogComponent component) async {
    final l10n = AppLocalizations.of(context);
    final name = await _promptName(
      title: l10n.componentEditTitle,
      initial: component.name,
    );
    if (name == null || name == component.name) return;

    final existing = await _service.findComponentByName(name);
    if (existing != null && existing.id != component.id) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.catalogItemAlreadyExists(name))),
      );
      return;
    }

    await _service.updateComponent(
      componentId: component.id,
      name: name,
    );
    widget.onRenamed?.call(component.name, name);
  }

  Future<void> _delete(CatalogComponent component) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showAppDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: context.colors.modal,
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
    final spacing = context.spacing;
    final typography = context.typography;

    return SafeArea(
      child: Padding(
        padding: spacing.allLg,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SheetDragHandle(),
            spacing.vMd,
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.soilComponentsTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: typography.titleMedium,
                  ),
                ),
                spacing.hXs,
                FilledButton.icon(
                  onPressed: _add,
                  icon: Icon(context.icons.add),
                  label: Text(l10n.commonAdd),
                ),
              ],
            ),
            spacing.vSm,
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.45,
              child: StreamBuilder<List<CatalogComponent>>(
                stream: _service.getComponents(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text(snapshot.error.toString()));
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: AccessibleProgressIndicator());
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
                              icon: Icon(context.icons.editOutlined),
                              onPressed: () => _edit(item),
                            ),
                            IconButton(
                              tooltip: l10n.commonDelete,
                              visualDensity: VisualDensity.compact,
                              icon: Icon(context.icons.delete),
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
