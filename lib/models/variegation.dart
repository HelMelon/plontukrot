import 'package:flutter/material.dart';

enum Variegation {
  none,
  aurea,
  alba,
  pink,
  splash,
  mint,
  multicolor,
  tricolor,
  unknown;

  String get storageValue => name;

  String get label => switch (this) {
        Variegation.none => 'Нет',
        Variegation.aurea => 'Аурея',
        Variegation.alba => 'Альба',
        Variegation.pink => 'Пинк',
        Variegation.splash => 'Сплеш',
        Variegation.mint => 'Минт',
        Variegation.multicolor => 'Мультиколор',
        Variegation.tricolor => 'Триколор',
        Variegation.unknown => 'Неизвестно',
      };

  IconData get icon => switch (this) {
        Variegation.aurea ||
        Variegation.alba ||
        Variegation.pink =>
          Icons.water_drop_sharp,
        Variegation.none ||
        Variegation.splash ||
        Variegation.mint ||
        Variegation.multicolor ||
        Variegation.tricolor ||
        Variegation.unknown =>
          Icons.palette,
      };

  Color get iconColor => switch (this) {
        Variegation.aurea => const Color(0xFFFFD54F),
        Variegation.alba => Colors.white,
        Variegation.pink => const Color(0xFFF48FB1),
        Variegation.none => const Color(0xFF9E9E9E),
        Variegation.splash ||
        Variegation.mint ||
        Variegation.multicolor ||
        Variegation.tricolor ||
        Variegation.unknown =>
          const Color(0xFF80CBC4),
      };

  bool get showIconNearSpecies => this != Variegation.none;

  static Variegation fromStorage(String? value) {
    final normalized = value?.trim().toLowerCase() ?? '';
    if (normalized.isEmpty) return Variegation.none;
    return Variegation.values.firstWhere(
      (item) => item.storageValue == normalized,
      orElse: () => Variegation.unknown,
    );
  }
}
