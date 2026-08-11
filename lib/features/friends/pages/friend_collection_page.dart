import 'package:flutter/material.dart';
import 'package:plontukrot/l10n/app_localizations.dart';

import '../../../core/theme/theme_context.dart';
import '../../../core/widgets/app_bar_chrome_actions.dart';
import '../../../models/collection_visibility.dart';
import '../../../models/friendship.dart';
import '../../../models/plant.dart';
import '../../../services/friends_service.dart';
import '../../../services/plant_service.dart';
import '../../plants/widgets/cards/plant_card.dart';
import 'friend_plant_details_page.dart';
import 'package:plontukrot/core/widgets/accessible_progress_indicator.dart';

class FriendCollectionPage extends StatefulWidget {
  final Friendship friendship;

  const FriendCollectionPage({super.key, required this.friendship});

  @override
  State<FriendCollectionPage> createState() => _FriendCollectionPageState();
}

class _FriendCollectionPageState extends State<FriendCollectionPage> {
  late final Future<Map<String, dynamic>?> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture =
        FriendsService().fetchPublicProfile(widget.friendship.friendUid);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final spacing = context.spacing;
    final typography = context.typography;
    final friend = widget.friendship;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          l10n.friendsCollectionTitle(friend.displayLabel),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: buildAppBarChromeActions(context),
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _profileFuture,
        builder: (context, profileSnap) {
          if (profileSnap.connectionState == ConnectionState.waiting) {
            return const Center(child: AccessibleProgressIndicator());
          }
          final visibility = CollectionVisibility.fromCode(
            profileSnap.data?['collectionVisibility'] as String?,
          );
          if (visibility == CollectionVisibility.private) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(spacing.xl),
                child: Text(
                  l10n.friendsCollectionPrivate,
                  style: typography.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return StreamBuilder<List<Plant>>(
            stream: PlantService().getPlantsForUser(friend.friendUid),
            builder: (context, snap) {
              if (snap.hasError) {
                return Center(
                  child: Text(
                    l10n.commonError(snap.error.toString()),
                    style: typography.bodyMedium,
                  ),
                );
              }
              if (!snap.hasData) {
                return const Center(child: AccessibleProgressIndicator());
              }
              final plants = snap.data!;
              if (plants.isEmpty) {
                return Center(
                  child: Text(
                    l10n.friendsCollectionEmpty,
                    style: typography.bodyMedium,
                  ),
                );
              }

              return GridView.builder(
                padding: EdgeInsets.all(spacing.md),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount:
                      MediaQuery.sizeOf(context).width >= 700 ? 3 : 2,
                  crossAxisSpacing: spacing.md,
                  mainAxisSpacing: spacing.md,
                  childAspectRatio: 0.72,
                ),
                itemCount: plants.length,
                itemBuilder: (context, index) {
                  final plant = plants[index];
                  return PlantCard(
                    plant: plant,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FriendPlantDetailsPage(
                            ownerUid: friend.friendUid,
                            plantId: plant.id,
                            ownerLabel: friend.displayLabel,
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
