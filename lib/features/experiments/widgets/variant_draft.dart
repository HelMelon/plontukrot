import 'package:flutter/widgets.dart';

import '../../../models/experiment_variant.dart';

/// Editable variant state for [ExperimentFormSheet]. A null [id] means the
/// variant does not exist on the server yet — it will be created on save.
class VariantDraft {
  final String? id;
  final TextEditingController label;
  final TextEditingController description;

  VariantDraft({
    this.id,
    String label = '',
    String description = '',
  })  : label = TextEditingController(text: label),
        description = TextEditingController(text: description);

  factory VariantDraft.empty() => VariantDraft();

  factory VariantDraft.fromVariant(ExperimentVariant variant) => VariantDraft(
        id: variant.id,
        label: variant.label,
        description: variant.description ?? '',
      );

  bool get isExisting => id != null;

  Map<String, dynamic> toCreatePayload() => {
        'label': label.text.trim(),
        if (description.text.trim().isNotEmpty)
          'description': description.text.trim(),
      };

  void dispose() {
    label.dispose();
    description.dispose();
  }
}
