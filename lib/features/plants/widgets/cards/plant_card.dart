import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../pages/plant_details_page.dart';

// 🔠 Безопасное расширение для капитализации каждого слова
extension CapitalizeString on String {
  String toTitleCase() {
    if (trim().isEmpty) return '';

    return split(' ') // Разделяем строку на список слов по пробелам
        .where((word) => word.isNotEmpty) // Убираем случайные двойные пробелы
        .map((word) {
          if (word.length == 1)
            return word.toUpperCase(); // Защита для слов из одной буквы
          return '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}';
        })
        .join(' '); // Соединяем слова обратно через пробел
  }
}

class PlantCard extends StatelessWidget {
  final QueryDocumentSnapshot plant;

  const PlantCard({super.key, required this.plant});

  @override
  Widget build(BuildContext context) {
    final data = plant.data() as Map<String, dynamic>;

    final imageUrl = data['imageUrl'] as String?;
    final hasImage = imageUrl != null && imageUrl.isNotEmpty;

    // 🏷️ Применяем капитализацию к именам при получении данных
    final name = (data['name'] as String? ?? 'Unnamed Plant').toTitleCase();
    final nickname = (data['nickname'] as String? ?? '').toTitleCase();
    final hasNickname = nickname.trim().isNotEmpty;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PlantDetailsPage(plant: plant)),
        );
      },
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 18),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.backgroundSecondary,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColors.greenDeep),
          boxShadow: [
            BoxShadow(
              color: AppColors.dark1.withOpacity(0.25),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 🔴 КРУГЛЫЙ АВАТАР БЕЗ НИЧЕГО
            SizedBox(
              width: 56,
              height: 56,
              child: ClipOval(
                child: hasImage
                    ? Image.network(
                        imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: AppColors.dark2,
                            child: const Icon(
                              Icons.eco,
                              color: AppColors.accentLight,
                              size: 26,
                            ),
                          );
                        },
                      )
                    : Container(
                        // ✨ ИСПРАВЛЕНО: удален color, так как задан decoration с градиентом
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.goldAccent,
                              AppColors.accentGreen,
                            ],
                          ),
                        ),
                        child: const Icon(
                          Icons.eco,
                          color: AppColors.accentLight,
                          size: 26,
                        ),
                      ),
              ),
            ),

            const SizedBox(width: 18),

            // CONTENT
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 👑 ЗАГОЛОВОК (Теперь автоматически переносится)
                  Text(
                    hasNickname ? nickname : name,
                    overflow: TextOverflow.clip,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                      color: AppColors.goldAccent,
                      height:
                          1.2, // ↕️ Небольшой межстрочный интервал, чтобы строки не слипались
                    ),
                  ),

                  // 🌿 ПОДЗАГОЛОВОК С ИМЕНЕМ (Показывается, только если есть никнейм)
                  if (hasNickname) ...[
                    const SizedBox(height: 4),
                    Text(
                      name,
                      maxLines:
                          2, // Ему тоже разрешим перенос на две строки, если имя длинное
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: AppColors.warmGray,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(width: 8),

            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textSecondary,
              size: 28,
            ),
          ],
        ),
      ),
    );
  }
}
