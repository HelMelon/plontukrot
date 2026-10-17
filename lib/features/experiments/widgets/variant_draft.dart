import 'dart:typed_data';

import 'package:flutter/widgets.dart';

import '../../../models/experiment_variant.dart';

/// Editable variant state for [ExperimentFormSheet]. A null [id] means the
/// variant does not exist on the server yet — it will be created on save.
class VariantDraft {
  final String? id;
  final TextEditingController label;
  final TextEditingController description;

  /// Bytes chosen in this session. Uploaded on save, before the row exists.
  Uint8List? pickedBytes;

  /// URL already stored on the server, or set after a successful upload.
  String? imageUrl;

  /// The user removed the photo. Distinct from "never had one" so an edit
  /// can clear `image_url` instead of keeping the previous file.
  bool imageCleared;

  VariantDraft({
    this.id,
    String label = '',
    String description = '',
    this.imageUrl,
    this.imageCleared = false,
  })  : label = TextEditingController(text: label),
        description = TextEditingController(text: description);

  factory VariantDraft.empty() => VariantDraft();

  factory VariantDraft.fromVariant(ExperimentVariant variant) => VariantDraft(
        id: variant.id,
        label: variant.label,
        description: variant.description ?? '',
        imageUrl: variant.imageUrl,
      );

  bool get isExisting => id != null;

  bool get hasPhoto {
    if (pickedBytes != null) return true;
    if (imageCleared) return false;
    return imageUrl != null && imageUrl!.trim().isNotEmpty;
  }

  /// Put back text that a rebuild wiped. Empty snapshots are ignored, so a
  /// field the user actually cleared stays cleared.
  void restoreIfCleared({required String label, required String description}) {
    if (label.isNotEmpty && this.label.text.isEmpty) {
      this.label.text = label;
    }
    if (description.isNotEmpty && this.description.text.isEmpty) {
      this.description.text = description;
    }
  }

  /// URL to persist. [uploadedUrl] is the result of uploading [pickedBytes]
  /// during this save.
  String? imageUrlForSave(String? uploadedUrl) {
    if (pickedBytes != null) {
      final uploaded = uploadedUrl?.trim();
      if (uploaded != null && uploaded.isNotEmpty) return uploaded;
    }
    if (imageCleared) return null;
    final existing = imageUrl?.trim();
    if (existing == null || existing.isEmpty) return null;
    return existing;
  }

  Map<String, dynamic> toCreatePayload({String? imageUrl}) => {
        'label': label.text.trim(),
        if (description.text.trim().isNotEmpty)
          'description': description.text.trim(),
        if (imageUrl != null && imageUrl.trim().isNotEmpty)
          'image_url': imageUrl.trim(),
      };

  void dispose() {
    label.dispose();
    description.dispose();
  }
}
