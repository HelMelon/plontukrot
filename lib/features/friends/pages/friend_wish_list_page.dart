import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:plontukrot/l10n/app_localizations.dart';

import '../../../core/theme/theme_context.dart';
import '../../../models/collection_visibility.dart';
import '../../../models/friendship.dart';
import '../../../models/wish_list_item.dart';
import '../../../services/friends_service.dart';
import '../../../services/wish_list_service.dart';

class FriendWishListPage extends StatefulWidget {
  final Friendship friendship;

  const FriendWishListPage({super.key, required this.friendship});

  @override
  State<FriendWishListPage> createState() => _FriendWishListPageState();
}

class _FriendWishListPageState extends State<FriendWishListPage> {
  late final Future<Map<String, dynamic>?> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture =
        FriendsService().fetchPublicProfile(widget.friendship.friendUid);
  }

  Widget _itemTile(WishListItem item) {
    final colors = context.colors;
    final spacing = context.spacing;
    final typography = context.typography;
    final wishTheme = context.screens.wishList;

    return Container(
      padding: wishTheme.cardPadding,
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(wishTheme.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.nameAlt,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: typography.bodyLarge.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          spacing.vXxs,
          Text(
            item.nameEn,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: typography.bodyMedium.copyWith(
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final spacing = context.spacing;
    final typography = context.typography;
    final colors = context.colors;
    final dimensions = context.dimensions;
    final friend = widget.friendship;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          l10n.friendsWishListTitle(friend.displayLabel),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _profileFuture,
        builder: (context, profileSnap) {
          if (profileSnap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final visibility = CollectionVisibility.fromCode(
            profileSnap.data?['collectionVisibility'] as String?,
          );
          if (visibility == CollectionVisibility.private) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(spacing.xl),
                child: Text(
                  l10n.friendsWishListPrivate,
                  style: typography.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return StreamBuilder<List<WishListItem>>(
            stream: WishListService().watchItemsForUser(friend.friendUid),
            builder: (context, snap) {
              if (snap.hasError) {
                return Center(
                  child: Padding(
                    padding: spacing.allLg,
                    child: Text(
                      l10n.friendsWishListLoadError,
                      style: typography.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final items = snap.data!;
              if (items.isEmpty) {
                return Center(
                  child: Padding(
                    padding: EdgeInsets.all(spacing.xl),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        HugeIcon(
                          icon: HugeIcons.strokeRoundedBookHeart,
                          color: colors.icon,
                          size: dimensions.iconXl,
                        ),
                        spacing.vMd,
                        Text(
                          l10n.friendsWishListEmpty,
                          style: typography.bodyMedium.copyWith(
                            color: colors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.separated(
                padding: EdgeInsets.fromLTRB(
                  spacing.md,
                  spacing.sm,
                  spacing.md,
                  spacing.xl,
                ),
                itemCount: items.length,
                separatorBuilder: (_, __) => spacing.vSm,
                itemBuilder: (context, index) => _itemTile(items[index]),
              );
            },
          );
        },
      ),
    );
  }
}
