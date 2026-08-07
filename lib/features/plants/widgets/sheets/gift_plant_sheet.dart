import 'package:flutter/material.dart';
import 'package:plontukrot/l10n/app_localizations.dart';

import '../../../../core/theme/theme_context.dart';
import '../../../../models/friendship.dart';
import '../../../../models/plant.dart';
import '../../../../services/friends_service.dart';
import '../../../../services/gift_service.dart';

Future<void> showGiftPlantSheet({
  required BuildContext context,
  required Plant plant,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _GiftPlantSheet(plant: plant),
  );
}

class _GiftPlantSheet extends StatefulWidget {
  final Plant plant;

  const _GiftPlantSheet({required this.plant});

  @override
  State<_GiftPlantSheet> createState() => _GiftPlantSheetState();
}

class _GiftPlantSheetState extends State<_GiftPlantSheet> {
  final _messageController = TextEditingController();
  Friendship? _selected;
  bool _busy = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final friend = _selected;
    if (friend == null || _busy) return;
    final l10n = AppLocalizations.of(context);
    setState(() => _busy = true);
    try {
      await GiftService().sendGift(
        plant: widget.plant,
        recipientUid: friend.friendUid,
        message: _messageController.text,
      );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.plantGiftSent)),
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final spacing = context.spacing;
    final radii = context.radii;
    final colors = context.colors;
    final typography = context.typography;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: BoxDecoration(
          color: colors.modal,
          borderRadius: BorderRadius.vertical(top: Radius.circular(radii.sheet)),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(spacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l10n.plantGiftTitle, style: typography.titleSmall),
                SizedBox(height: spacing.md),
                Text(l10n.plantGiftPickFriend, style: typography.label),
                SizedBox(height: spacing.sm),
                StreamBuilder<List<Friendship>>(
                  stream: FriendsService().watchFriends(),
                  builder: (context, snap) {
                    final friends = snap.data ?? const [];
                    if (friends.isEmpty) {
                      return Text(
                        l10n.plantGiftNoFriends,
                        style: typography.bodySmall,
                      );
                    }
                    return Column(
                      children: [
                        for (final friend in friends)
                          ListTile(
                            selected: _selected?.friendUid == friend.friendUid,
                            onTap: _busy
                                ? null
                                : () => setState(() => _selected = friend),
                            leading: Icon(
                              _selected?.friendUid == friend.friendUid
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_off,
                              color: colors.icon,
                            ),
                            title: Text(
                              friend.displayLabel,
                              style: typography.bodyMedium,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    );
                  },
                ),
                SizedBox(height: spacing.md),
                TextField(
                  controller: _messageController,
                  enabled: !_busy,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: l10n.plantGiftMessageHint,
                    border: const OutlineInputBorder(),
                  ),
                  style: typography.bodyMedium,
                ),
                SizedBox(height: spacing.lg),
                FilledButton(
                  onPressed: _busy || _selected == null ? null : _send,
                  child: Text(l10n.plantGiftConfirm),
                ),
                TextButton(
                  onPressed: _busy ? null : () => Navigator.pop(context),
                  child: Text(l10n.commonCancel),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
