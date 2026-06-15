import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/plant_service.dart';
import '../pages/plant_details_page.dart'; // Скорректируй путь к PlantDetailsPage, если нужно

class PlantSearchDelegate extends SearchDelegate {
  final String userId;

  PlantSearchDelegate({required this.userId});

  // Настройка темы для экрана поиска под цвета твоего приложения
  @override
  ThemeData appBarTheme(BuildContext context) {
    return Theme.of(context).copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: InputBorder.none,
        hintStyle: TextStyle(color: AppColors.textSecondary),
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(color: AppColors.heading),
      ),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear, color: AppColors.heading),
          onPressed: () => query = '',
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back, color: AppColors.heading),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) => _buildSearchWithStream();

  @override
  Widget buildSuggestions(BuildContext context) => _buildSearchWithStream();

  Widget _buildSearchWithStream() {
    final cleanQuery = query.trim().toLowerCase();

    // Если поисковая строка пустая, показываем подсказку и НЕ делаем фильтрацию
    if (cleanQuery.isEmpty) {
      return const ContainerWithBackground(
        child: Center(
          child: Text(
            'Type plant name...',
            style: TextStyle(color: AppColors.textPrimary),
          ),
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: PlantService().getPlants(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const ContainerWithBackground(
            child: Center(
              child: CircularProgressIndicator(color: AppColors.goldAccent),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const ContainerWithBackground(
            child: Center(
              child: Text(
                'No plants found',
                style: TextStyle(color: AppColors.textPrimary),
              ),
            ),
          );
        }

        // Жесткая фильтрация данных
        final filtered = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>?;
          if (data == null) return false;

          // Извлекаем поля, безопасно приводя к строке нижнего регистра
          final String name = (data['name'] ?? '')
              .toString()
              .trim()
              .toLowerCase();
          final String nickname = (data['nickname'] ?? '')
              .toString()
              .trim()
              .toLowerCase();

          // Если оба поля пустые — этот документ битый, пропускаем его
          if (name.isEmpty && nickname.isEmpty) return false;

          // Проверяем, содержит ли имя ИЛИ никнейм наш поисковый запрос
          return name.contains(cleanQuery) || nickname.contains(cleanQuery);
        }).toList();

        // Если после фильтрации ничего не осталось
        if (filtered.isEmpty) {
          return const ContainerWithBackground(
            child: Center(
              child: Text(
                'No matches found',
                style: TextStyle(color: AppColors.textPrimary),
              ),
            ),
          );
        }

        // Отрисовка списка результатов
        return ContainerWithBackground(
          child: ListView.builder(
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final plantDoc = filtered[index];
              final data = plantDoc.data() as Map<String, dynamic>;

              // Отображаем никнейм, а если его нет — имя (как в остальном твоем приложении)
              final displayName =
                  data['nickname'] ?? data['name'] ?? 'Unnamed Plant';

              return ListTile(
                leading: const Icon(
                  Icons.local_florist,
                  color: AppColors.goldAccent,
                ),
                title: Text(
                  displayName,
                  style: const TextStyle(
                    color: AppColors.heading,
                    fontSize: 16,
                  ),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PlantDetailsPage(plant: plantDoc),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}

// Вспомогательный виджет, чтобы задний фон поиска соответствовал стилю приложения
class ContainerWithBackground extends StatelessWidget {
  final Widget child;
  const ContainerWithBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      width: double.infinity,
      height: double.infinity,
      child: child,
    );
  }
}
