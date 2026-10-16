import 'package:flutter/material.dart';
import 'package:plontukrot/core/widgets/accessible_progress_indicator.dart';
import 'package:plontukrot/core/widgets/app_modal.dart';
import 'package:plontukrot/core/widgets/sheet_drag_handle.dart';
import 'package:plontukrot/l10n/app_localizations.dart';

import '../../../../core/theme/theme_context.dart';
import '../../../../models/room.dart';
import '../../../../services/room_service.dart';
import 'manage_rooms_sheet.dart';

/// A chosen room. [roomId] is null when the plant is not placed anywhere.
class RoomPick {
  final String? roomId;

  const RoomPick(this.roomId);
}

Future<RoomPick?> showSelectPlantRoomSheet({
  required BuildContext context,
  required String? currentRoomId,
  bool indicateCurrent = true,
}) {
  return showAppModalBottomSheet<RoomPick>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    enableDrag: true,
    builder: (_) => SelectPlantRoomSheet(
      currentRoomId: currentRoomId,
      indicateCurrent: indicateCurrent,
    ),
  );
}

class SelectPlantRoomSheet extends StatelessWidget {
  final String? currentRoomId;
  final bool indicateCurrent;

  const SelectPlantRoomSheet({
    super.key,
    required this.currentRoomId,
    this.indicateCurrent = true,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final spacing = context.spacing;
    final typography = context.typography;
    final sheets = context.components.sheets;

    return Material(
      color: colors.modal,
      borderRadius: sheets.topBorderRadius,
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        child: Padding(
          padding: spacing.allLg,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SheetDragHandle(),
              spacing.vMd,
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.roomsTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: typography.titleMedium,
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.a11yManageRooms,
                    onPressed: () => showManageRoomsSheet(context),
                    icon: Icon(context.icons.editOutlined),
                  ),
                ],
              ),
              spacing.vSm,
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.45,
                child: StreamBuilder<List<Room>>(
                  stream: RoomService().watchRooms(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          snapshot.error.toString(),
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }
                    if (!snapshot.hasData) {
                      return const Center(child: AccessibleProgressIndicator());
                    }
                    final rooms = snapshot.data!;
                    return ListView(
                      children: [
                        _tile(
                          context,
                          title: l10n.roomNone,
                          selected: indicateCurrent && currentRoomId == null,
                          onTap: () => Navigator.pop(context, const RoomPick(null)),
                        ),
                        for (final room in rooms)
                          _tile(
                            context,
                            title: room.name,
                            icon: context.icons.room,
                            selected: indicateCurrent && currentRoomId == room.id,
                            onTap: () =>
                                Navigator.pop(context, RoomPick(room.id)),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tile(
    BuildContext context, {
    required String title,
    String? subtitle,
    IconData? icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final colors = context.colors;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      selected: selected,
      leading: icon == null
          ? null
          : ExcludeSemantics(child: Icon(icon, color: colors.icon)),
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
      trailing: selected
          ? ExcludeSemantics(child: Icon(context.icons.check, color: colors.primary))
          : null,
      onTap: onTap,
    );
  }
}
