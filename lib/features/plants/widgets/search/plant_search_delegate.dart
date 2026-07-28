import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../models/plant.dart';
import '../../../../services/plant_service.dart';
import '../../pages/plant_details_page.dart';

class PlantSearchDelegate extends SearchDelegate {
  final String userId;

  PlantSearchDelegate({required this.userId});

  @override
  String get searchFieldLabel => 'Поиск растений...';

  @override
  ThemeData appBarTheme(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return theme.copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.heading),
      ),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 16,
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 12,
          horizontal: 16,
        ),
        filled: true,
        fillColor: AppColors.heading.withValues(alpha: 0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.goldAccent, width: 1.5),
        ),
      ),
      textTheme: theme.textTheme.copyWith(
        titleLarge: const TextStyle(
          color: AppColors.heading,
          fontSize: 18,
          decorationThickness: 0,
        ),
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColors.goldAccent,
        selectionColor: AppColors.goldAccent,
        selectionHandleColor: AppColors.goldAccent,
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

    return StreamBuilder<List<Plant>>(
      stream: PlantService().getPlants(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const ContainerWithBackground(
            child: Center(
              child: CircularProgressIndicator(color: AppColors.goldAccent),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const ContainerWithBackground(
            child: Center(
              child: Text(
                'В журнале нет растений',
                style: TextStyle(color: AppColors.textPrimary),
              ),
            ),
          );
        }

        final filtered = snapshot.data!.where((plant) {
          final name = plant.name.trim().toLowerCase();
          final nickname = plant.nickname.trim().toLowerCase();

          if (cleanQuery.isEmpty) return true;

          return name.contains(cleanQuery) || nickname.contains(cleanQuery);
        }).toList();

        if (filtered.isEmpty) {
          return const ContainerWithBackground(
            child: Center(
              child: Text(
                'Ничего не найдено',
                style: TextStyle(color: AppColors.textPrimary),
              ),
            ),
          );
        }

        return ContainerWithBackground(
          child: ListView.builder(
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final plant = filtered[index];

              String capitalizeWords(String text) {
                if (text.isEmpty) return '';
                return text
                    .split(' ')
                    .where((word) => word.isNotEmpty)
                    .map(
                      (word) =>
                          '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}',
                    )
                    .join(' ');
              }

              final String nickname = capitalizeWords(
                plant.nickname.trim(),
              );
              final String name = capitalizeWords(
                plant.name.trim(),
              );

              final String titleText;
              final String? subtitleText;

              if (nickname.isNotEmpty) {
                titleText = nickname;
                subtitleText = name.isNotEmpty ? '($name)' : null;
              } else {
                titleText = name.isNotEmpty ? name : 'Без названия';
                subtitleText = null;
              }

              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 6.0,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.heading.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.heading.withValues(alpha: 0.02),
                      width: 1,
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.goldAccent.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: () {
                          final String? imageUrl =
                              plant.imageUrl?.trim();

                          if (imageUrl != null && imageUrl.isNotEmpty) {
                            return Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              width: 40,
                              height: 40,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(
                                Icons.local_florist,
                                color: AppColors.goldAccent,
                                size: 22,
                              ),
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Center(
                                  child: SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        AppColors.goldAccent
                                            .withValues(alpha: 0.5),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          }

                          return const Icon(
                            Icons.local_florist,
                            color: AppColors.goldAccent,
                            size: 22,
                          );
                        }(),
                      ),
                    ),
                    title: Text(
                      titleText,
                      style: const TextStyle(
                        color: AppColors.heading,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: subtitleText != null
                        ? Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              subtitleText,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          )
                        : null,
                    trailing: const Icon(
                      Icons.chevron_right,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              PlantDetailsPage(plantId: plant.id),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

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
