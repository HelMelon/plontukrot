import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:plontukrot/l10n/app_localizations.dart';

import '../../../core/theme/theme_context.dart';
import '../../../core/widgets/app_bar_chrome_actions.dart';
import '../../../models/collection_visibility.dart';
import '../../../models/friend_request.dart';
import '../../../models/friendship.dart';
import '../../../models/incoming_gift.dart';
import '../../../models/plant.dart';
import '../../../services/auth_service.dart';
import '../../../services/user_profile_service.dart';
import '../../../services/friends_service.dart';
import '../../../services/gift_service.dart';
import '../../../services/plant_service.dart';
import 'friend_collection_page.dart';
import 'friend_wish_list_page.dart';
import 'package:plontukrot/core/widgets/app_modal.dart';

class FriendsPage extends StatefulWidget {
  const FriendsPage({super.key});

  @override
  State<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> {
  final _friendsService = FriendsService();
  final _giftService = GiftService();
  final _uidController = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _uidController.dispose();
    super.dispose();
  }

  Future<void> _sendRequest() async {
    final l10n = AppLocalizations.of(context);
    final target = _uidController.text.trim();
    if (target.isEmpty || _busy) return;
    setState(() => _busy = true);
    try {
      await _friendsService.sendFriendRequest(target);
      if (!mounted) return;
      _uidController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.friendsRequestSent)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.commonError(e.toString()))),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _copyMyUid() async {
    final uid = AuthService().currentUser?.uid;
    if (uid == null) return;
    await Clipboard.setData(ClipboardData(text: uid));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).profileUidCopied)),
    );
  }

  Future<void> _removeFriend(Friendship friend) async {
    final l10n = AppLocalizations.of(context);
    final name = _friendDisplayName(friend, l10n);
    final confirmed = await showAppDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.friendsRemove),
        content: Text(l10n.friendsRemoveConfirm(name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.friendsRemove),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _busy = true);
    try {
      await _friendsService.removeFriend(friend.friendUid);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.commonError(e.toString()))),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _friendDisplayName(Friendship friend, AppLocalizations l10n) {
    final name = friend.displayNameSnap?.trim();
    if (name != null && name.isNotEmpty) return name;
    return l10n.friendsUnknownName;
  }

  Future<void> _acceptGift(IncomingGift gift) async {
    final l10n = AppLocalizations.of(context);
    setState(() => _busy = true);
    try {
      await _giftService.acceptGift(gift);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.friendsGiftAccepted)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.commonError(e.toString()))),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _acceptFriendRequest(FriendRequest request) async {
    if (_busy) return;
    final l10n = AppLocalizations.of(context);
    setState(() => _busy = true);
    try {
      await _friendsService.acceptFriendRequest(request);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.commonError(e.toString()))),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _declineFriendRequest(FriendRequest request) async {
    if (_busy) return;
    final l10n = AppLocalizations.of(context);
    setState(() => _busy = true);
    try {
      await _friendsService.declineFriendRequest(request);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.commonError(e.toString()))),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final spacing = context.spacing;
    final typography = context.typography;
    final colors = context.colors;
    final dimensions = context.dimensions;
    final myUid = AuthService().currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(l10n.friendsTitle),
        actions: buildAppBarChromeActions(context),
      ),
      body: ListView(
        padding: EdgeInsets.all(spacing.lg),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.profileMyUid, style: typography.label),
                    SizedBox(height: spacing.xs),
                    SelectableText(
                      myUid,
                      style: typography.captionSmall,
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: l10n.profileCopyUid,
                onPressed: _copyMyUid,
                icon: Icon(context.icons.copy, color: colors.heading),
              ),
            ],
          ),
          StreamBuilder<UserProfileDoc>(
            stream: UserProfileService().watchUserProfile(),
            builder: (context, snap) {
              final visibility = snap.data?.collectionVisibility ??
                  CollectionVisibility.friends;
              return SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  l10n.profileCollectionVisibility,
                  style: typography.label,
                ),
                subtitle: Text(
                  visibility == CollectionVisibility.friends
                      ? l10n.profileCollectionFriends
                      : l10n.profileCollectionPrivate,
                  style: typography.captionSmall,
                ),
                value: visibility == CollectionVisibility.friends,
                onChanged: _busy
                    ? null
                    : (value) async {
                        await _friendsService.updateCollectionVisibility(
                          value
                              ? CollectionVisibility.friends
                              : CollectionVisibility.private,
                        );
                      },
              );
            },
          ),
          SizedBox(height: spacing.md),
          Text(l10n.friendsAddTitle, style: typography.sectionTitle),
          SizedBox(height: spacing.sm),
          TextField(
            controller: _uidController,
            decoration: InputDecoration(
              labelText: l10n.friendsAddHint,
              hintText: l10n.friendsAddHint,
              border: const OutlineInputBorder(),
            ),
            style: typography.bodyMedium,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _sendRequest(),
          ),
          SizedBox(height: spacing.sm),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: _busy ? null : _sendRequest,
              child: Text(l10n.friendsAddAction),
            ),
          ),
          SizedBox(height: spacing.xl),
          Text(l10n.friendsGiftsInbox, style: typography.sectionTitle),
          SizedBox(height: spacing.sm),
          StreamBuilder<List<IncomingGift>>(
            stream: _giftService.watchIncomingGifts(),
            builder: (context, snap) {
              final gifts = snap.data ?? const [];
              if (gifts.isEmpty) {
                return Text(l10n.friendsGiftEmpty, style: typography.bodySmall);
              }
              return Column(
                children: [
                  for (final gift in gifts)
                    Card(
                      child: Padding(
                        padding: EdgeInsets.all(spacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              gift.previewPlant.nickname.isNotEmpty
                                  ? gift.previewPlant.nickname
                                  : gift.previewPlant.species,
                              style: typography.bodyEmphasis,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: spacing.xs),
                            Text(
                              l10n.friendsGiftFrom(
                                gift.fromDisplayName?.isNotEmpty == true
                                    ? gift.fromDisplayName!
                                    : gift.fromUid,
                              ),
                              style: typography.captionSmall,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: spacing.md),
                            Wrap(
                              alignment: WrapAlignment.end,
                              spacing: spacing.xs,
                              runSpacing: spacing.xs,
                              children: [
                                TextButton(
                                  onPressed: _busy
                                      ? null
                                      : () => _giftService.declineGift(gift),
                                  child: Text(l10n.friendsGiftDecline),
                                ),
                                FilledButton(
                                  onPressed:
                                      _busy ? null : () => _acceptGift(gift),
                                  child: Text(l10n.friendsGiftAccept),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          SizedBox(height: spacing.xl),
          Text(l10n.friendsIncoming, style: typography.sectionTitle),
          StreamBuilder<List<FriendRequest>>(
            stream: _friendsService.watchIncomingRequests(),
            builder: (context, snap) {
              final requests = snap.data ?? const [];
              if (requests.isEmpty) {
                return Padding(
                  padding: EdgeInsets.only(top: spacing.sm),
                  child: Text('—', style: typography.bodySmall),
                );
              }
              return Column(
                children: [
                  for (final req in requests)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        req.fromDisplayName?.isNotEmpty == true
                            ? req.fromDisplayName!
                            : req.fromUid,
                        style: typography.bodyMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextButton(
                            onPressed: _busy
                                ? null
                                : () => _declineFriendRequest(req),
                            child: Text(l10n.friendsDecline),
                          ),
                          FilledButton(
                            onPressed: _busy
                                ? null
                                : () => _acceptFriendRequest(req),
                            child: Text(l10n.friendsAccept),
                          ),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
          SizedBox(height: spacing.lg),
          Text(l10n.friendsOutgoing, style: typography.sectionTitle),
          StreamBuilder<List<FriendRequest>>(
            stream: _friendsService.watchOutgoingRequests(),
            builder: (context, snap) {
              final requests = snap.data ?? const [];
              if (requests.isEmpty) {
                return Padding(
                  padding: EdgeInsets.only(top: spacing.sm),
                  child: Text('—', style: typography.bodySmall),
                );
              }
              return Column(
                children: [
                  for (final req in requests)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        req.toUid,
                        style: typography.bodyMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: TextButton(
                        onPressed: () =>
                            _friendsService.cancelOutgoingRequest(req),
                        child: Text(l10n.friendsCancelRequest),
                      ),
                    ),
                ],
              );
            },
          ),
          SizedBox(height: spacing.xl),
          Text(l10n.friendsTitle, style: typography.sectionTitle),
          StreamBuilder<List<Friendship>>(
            stream: _friendsService.watchFriends(),
            builder: (context, snap) {
              final friends = snap.data ?? const [];
              if (friends.isEmpty) {
                return Padding(
                  padding: EdgeInsets.only(top: spacing.sm),
                  child: Text(l10n.friendsEmpty, style: typography.bodySmall),
                );
              }
              return Column(
                children: [
                  for (final friend in friends)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: spacing.xs),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundImage: friend.photoUrlSnap != null
                                ? NetworkImage(friend.photoUrlSnap!)
                                : null,
                            child: friend.photoUrlSnap == null
                                ? Icon(context.icons.profile, color: colors.icon)
                                : null,
                          ),
                          SizedBox(width: spacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _friendDisplayName(friend, l10n),
                                  style: typography.bodyEmphasis,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                _FriendPlantCount(
                                  ownerUid: friend.friendUid,
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: spacing.xs),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _FriendActionIcon(
                                tooltip: l10n.friendsOpenWishList,
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => FriendWishListPage(
                                        friendship: friend,
                                      ),
                                    ),
                                  );
                                },
                                child: HugeIcon(
                                  icon: context.icons.wishlist,
                                  color: colors.icon,
                                  // Stroke HugeIcons read smaller than Material
                                  // icons at the same nominal size.
                                  size: dimensions.iconXl,
                                ),
                              ),
                              _FriendActionIcon(
                                tooltip: l10n.friendsOpenCollection,
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => FriendCollectionPage(
                                        friendship: friend,
                                      ),
                                    ),
                                  );
                                },
                                child: Icon(
                                  context.icons.collection,
                                  color: colors.icon,
                                  size: dimensions.iconLg,
                                ),
                              ),
                              _FriendActionIcon(
                                tooltip: l10n.friendsRemove,
                                onPressed: _busy
                                    ? null
                                    : () => _removeFriend(friend),
                                child: Icon(
                                  context.icons.friendRemove,
                                  color: colors.icon,
                                  size: dimensions.iconLg,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _FriendActionIcon extends StatelessWidget {
  final String tooltip;
  final VoidCallback? onPressed;
  final Widget child;

  const _FriendActionIcon({
    required this.tooltip,
    required this.onPressed,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final dimensions = context.dimensions;
    final side = dimensions.iconXl + spacing.sm;

    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      visualDensity: VisualDensity.compact,
      style: IconButton.styleFrom(
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: EdgeInsets.all(spacing.xs),
        minimumSize: Size(side, side),
        fixedSize: Size(side, side),
      ),
      icon: child,
    );
  }
}

class _FriendPlantCount extends StatelessWidget {
  final String ownerUid;

  const _FriendPlantCount({required this.ownerUid});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final spacing = context.spacing;
    final typography = context.typography;
    final dimensions = context.dimensions;

    return StreamBuilder<List<Plant>>(
      stream: PlantService().getPlantsForUser(ownerUid),
      builder: (context, snapshot) {
        if (snapshot.hasError || !snapshot.hasData) {
          return const SizedBox.shrink();
        }
        final count = snapshot.data!.length;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              context.icons.plantPlaceholder,
              size: dimensions.iconSm,
              color: colors.icon,
            ),
            SizedBox(width: spacing.xs),
            Text(
              '$count',
              style: typography.captionSmall,
            ),
          ],
        );
      },
    );
  }
}
