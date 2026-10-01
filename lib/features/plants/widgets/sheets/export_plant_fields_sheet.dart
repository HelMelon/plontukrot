import 'package:flutter/material.dart';
import 'package:plontukrot/core/widgets/app_modal.dart';
import 'package:plontukrot/core/widgets/field_error_text.dart';
import 'package:plontukrot/core/widgets/sheet_drag_handle.dart';
import 'package:plontukrot/l10n/app_localizations.dart';

import '../../../../core/theme/theme_context.dart';
import '../../export/plant_export.dart';

Future<PlantCatalogExportRequest?> showExportPlantFieldsSheet({
  required BuildContext context,
}) {
  return showAppModalBottomSheet<PlantCatalogExportRequest>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    enableDrag: true,
    builder: (_) => const ExportPlantFieldsSheet(),
  );
}

Future<PlantExportFormat?> showPlantExportFormatSheet({
  required BuildContext context,
}) {
  return showAppModalBottomSheet<PlantExportFormat>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    enableDrag: true,
    builder: (_) => const PlantExportFormatSheet(),
  );
}

class ExportPlantFieldsSheet extends StatefulWidget {
  const ExportPlantFieldsSheet({super.key});

  @override
  State<ExportPlantFieldsSheet> createState() => _ExportPlantFieldsSheetState();
}

class _ExportPlantFieldsSheetState extends State<ExportPlantFieldsSheet> {
  final Set<PlantExportField> _selected = PlantExportField.values.toSet();
  PlantExportFormat _format = PlantExportFormat.json;
  bool _showRequiredError = false;

  void _export() {
    if (_selected.isEmpty) {
      setState(() => _showRequiredError = true);
      return;
    }
    Navigator.of(context).pop(
      PlantCatalogExportRequest(
        fields: Set<PlantExportField>.from(_selected),
        format: _format,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final spacing = context.spacing;
    final sheets = context.components.sheets;
    final typography = context.typography;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.85;

    return Material(
      color: colors.modal,
      borderRadius: sheets.topBorderRadius,
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: SingleChildScrollView(
            padding: spacing.allMd,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SheetDragHandle(),
                spacing.vMd,
                Text(
                  l10n.exportFieldsTitle,
                  style: typography.titleMedium,
                ),
                spacing.vSm,
                for (final field in PlantExportField.values)
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _selected.contains(field),
                    title: Text(
                      plantExportFieldLabel(l10n, field),
                      style: typography.bodyMedium,
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                    onChanged: (checked) {
                      setState(() {
                        if (checked ?? false) {
                          _selected.add(field);
                        } else {
                          _selected.remove(field);
                        }
                        if (_selected.isNotEmpty) _showRequiredError = false;
                      });
                    },
                  ),
                if (_showRequiredError) ...[
                  spacing.vXs,
                  FieldErrorText(l10n.exportFieldsRequired),
                ],
                spacing.vMd,
                Text(
                  l10n.exportFormatTitle,
                  style: typography.titleMedium,
                ),
                spacing.vXs,
                _ExportFormatRadios(
                  format: _format,
                  onChanged: (format) => setState(() => _format = format),
                ),
                spacing.vMd,
                FilledButton(
                  onPressed: _export,
                  child: Text(l10n.wishListExport),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PlantExportFormatSheet extends StatefulWidget {
  const PlantExportFormatSheet({super.key});

  @override
  State<PlantExportFormatSheet> createState() => _PlantExportFormatSheetState();
}

class _PlantExportFormatSheetState extends State<PlantExportFormatSheet> {
  PlantExportFormat _format = PlantExportFormat.json;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final spacing = context.spacing;
    final sheets = context.components.sheets;
    final typography = context.typography;

    return Material(
      color: colors.modal,
      borderRadius: sheets.topBorderRadius,
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: spacing.allMd,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SheetDragHandle(),
              spacing.vMd,
              Text(
                l10n.exportFormatTitle,
                style: typography.titleMedium,
              ),
              spacing.vXs,
              _ExportFormatRadios(
                format: _format,
                onChanged: (format) => setState(() => _format = format),
              ),
              spacing.vMd,
              FilledButton(
                onPressed: () => Navigator.of(context).pop(_format),
                child: Text(l10n.wishListExport),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExportFormatRadios extends StatelessWidget {
  final PlantExportFormat format;
  final ValueChanged<PlantExportFormat> onChanged;

  const _ExportFormatRadios({
    required this.format,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final typography = context.typography;
    return RadioGroup<PlantExportFormat>(
      groupValue: format,
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
      child: Column(
        children: [
          RadioListTile<PlantExportFormat>(
            contentPadding: EdgeInsets.zero,
            value: PlantExportFormat.json,
            title: Text(l10n.exportFormatJson, style: typography.bodyMedium),
          ),
          RadioListTile<PlantExportFormat>(
            contentPadding: EdgeInsets.zero,
            value: PlantExportFormat.markdown,
            title: Text(
              l10n.exportFormatMarkdown,
              style: typography.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
