import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:plontukrot/l10n/app_localizations.dart';

import '../../../../core/theme/theme_context.dart';
import '../../../../models/plant.dart';
import '../../pages/plant_details_page.dart';

class PlantSearchDelegate extends SearchDelegate {
  final String userId;
  final Stream<List<Plant>> plantsStream;
  final String _searchFieldLabel;

  PlantSearchDelegate({
    required this.userId,
    required this.plantsStream,
    required String searchFieldLabel,
  }) : _searchFieldLabel = searchFieldLabel;

  @override
  String get searchFieldLabel => _searchFieldLabel;

  @override
  ThemeData appBarTheme(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final colors = context.colors;
    final radii = context.radii;
    final spacing = context.spacing;
    final typography = context.typography;
    final inputs = context.components.inputs;
    return theme.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: colors.screen,
        elevation: 0,
        iconTheme: IconThemeData(color: colors.icon),
      ),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: typography.bodyLarge.copyWith(
          color: colors.textSecondary,
        ),
        contentPadding: EdgeInsets.symmetric(
          vertical: spacing.sm,
          horizontal: spacing.md,
        ),
        filled: true,
        fillColor: colors.heading.withValues(alpha: 0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radii.md),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radii.md),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radii.md),
          borderSide: BorderSide(color: inputs.focusedBorder, width: 1.5),
        ),
      ),
      textTheme: theme.textTheme.copyWith(
        titleLarge: typography.titleSmall.copyWith(
          color: colors.heading,
          decorationThickness: 0,
        ),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: colors.primary,
        selectionColor: colors.primary,
        selectionHandleColor: colors.primary,
      ),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: Icon(Icons.clear, color: context.colors.icon),
          onPressed: () => query = '',
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back, color: context.colors.icon),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) => _buildSearchWithStream(context);

  @override
  Widget buildSuggestions(BuildContext context) =>
      _buildSearchWithStream(context);

  Widget _buildSearchWithStream(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final spacing = context.spacing;
    final radii = context.radii;
    final typography = context.typography;
    final dimensions = context.dimensions;
    final cleanQuery = query.trim().toLowerCase();

    return StreamBuilder<List<Plant>>(
      stream: plantsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return ContainerWithBackground(
            child: Center(
              child: CircularProgressIndicator(color: colors.primary),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return ContainerWithBackground(
            child: Center(
              child: Text(
                l10n.searchNoPlantsInJournal,
                style: typography.bodyLarge,
              ),
            ),
          );
        }

        final filtered = snapshot.data!.where((plant) {
          final species = plant.species.trim().toLowerCase();
          final nickname = plant.nickname.trim().toLowerCase();
          final genus = plant.genus.trim().toLowerCase();
          final cultivar = (plant.cultivar ?? '').trim().toLowerCase();

          if (cleanQuery.isEmpty) return true;

          return species.contains(cleanQuery) ||
              nickname.contains(cleanQuery) ||
              genus.contains(cleanQuery) ||
              cultivar.contains(cleanQuery);
        }).toList();

        if (filtered.isEmpty) {
          return ContainerWithBackground(
            child: Center(
              child: Text(
                l10n.searchNothingFound,
                style: typography.bodyLarge,
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
              final String species = capitalizeWords(
                plant.species.trim(),
              );

              final String titleText;
              final String? subtitleText;

              if (nickname.isNotEmpty) {
                titleText = nickname;
                subtitleText = species.isNotEmpty ? '($species)' : null;
              } else {
                titleText =
                    species.isNotEmpty ? species : l10n.commonUntitled;
                subtitleText = null;
              }
              return Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: spacing.md,
                  vertical: spacing.xs - 2,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: colors.heading.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(radii.md),
                    border: Border.all(
                      color: colors.heading.withValues(alpha: 0.02),
                      width: 1,
                    ),
                  ),
                  child: ListTile(
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: spacing.md,
                      vertical: spacing.xs,
                    ),
                    leading: Container(
                      width: dimensions.avatar,
                      height: dimensions.avatar,
                      decoration: BoxDecoration(
                        color: colors.primary.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(radii.pill),
                        child: () {
                          final String? imageUrl = plant.listImageUrl;

                          if (imageUrl != null) {
                            return CachedNetworkImage(
                              imageUrl: imageUrl,
                              fit: BoxFit.cover,
                              width: dimensions.avatar,
                              height: dimensions.avatar,
                              memCacheWidth: 80,
                              memCacheHeight: 80,
                              errorWidget: (context, url, error) => Icon(
                                Icons.local_florist,
                                color: colors.icon,
                                size: dimensions.iconXl,
                              ),
                              placeholder: (context, url) => Center(
                                child: SizedBox(
                                  width: dimensions.iconSm,
                                  height: dimensions.iconSm,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      colors.primary,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }

                          return Icon(
                            Icons.local_florist,
                            color: colors.primary,
                            size: dimensions.iconXl,
                          );
                        }(),
                      ),
                    ),
                    title: Text(
                      titleText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: typography.bodyLarge.copyWith(
                        color: colors.heading,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: subtitleText != null
                        ? Padding(
                            padding: EdgeInsets.only(top: spacing.xxs),
                            child: Text(
                              subtitleText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: typography.bodySmall.copyWith(
                                color: colors.textSecondary,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          )
                        : null,
                    trailing: Icon(
                      Icons.chevron_right,
                      color: colors.textSecondary,
                      size: dimensions.iconLg,
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
      color: context.colors.screen,
      width: double.infinity,
      height: double.infinity,
      child: child,
    );
  }
}
