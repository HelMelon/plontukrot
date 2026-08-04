import '../models/plant.dart';
import '../models/propagation.dart';

/// Parent label for the global propagations board.
///
/// Uses live [Plant] data when available (nickname + botanical name).
/// Does not write nickname onto the propagation document.
String propagationParentLabel({
  required Propagation propagation,
  Plant? parent,
}) {
  final fallback = propagation.parentPlantName.trim();
  if (parent == null) return fallback.isEmpty ? '—' : fallback;

  final botanical = [
    parent.genus.trim(),
    parent.species.trim(),
  ].where((part) => part.isNotEmpty).join(' ');

  final base = botanical.isNotEmpty
      ? botanical
      : (fallback.isNotEmpty ? fallback : '—');

  final nickname = parent.nickname.trim();
  if (nickname.isEmpty) return base;
  return '$base «$nickname»';
}
