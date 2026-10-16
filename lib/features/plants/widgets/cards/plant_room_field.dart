import 'package:flutter/material.dart';
import 'package:plontukrot/core/widgets/focusable_tap.dart';
import 'package:plontukrot/l10n/app_localizations.dart';

import '../../../../core/theme/theme_context.dart';
import '../../../../models/plant.dart';
import '../../../../models/room.dart';
import '../../../../services/plant_service.dart';
import '../../../../services/room_service.dart';
import '../sheets/room_sensor_sheet.dart';
import '../sheets/select_plant_room_sheet.dart';

/// Shows where the plant stands. A sensor icon opens that room's readings.
class PlantRoomField extends StatelessWidget {
  final Plant plant;

  const PlantRoomField({super.key, required this.plant});

  Future<void> _pick(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final pick = await showSelectPlantRoomSheet(
      context: context,
      currentRoomId: plant.effectiveRoomId,
    );
    if (pick == null || pick.roomId == plant.effectiveRoomId) return;
    try {
      await PlantService().setPlantRoom(
        plantId: plant.id,
        roomId: pick.roomId,
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.commonError(''))),
      );
    }
  }

  String _label(AppLocalizations l10n, List<Room> rooms) {
    final id = plant.effectiveRoomId;
    if (id == null) return l10n.roomNone;
    for (final room in rooms) {
      if (room.id == id) return room.name;
    }
    if (id == Room.balconyId) return l10n.roomBalcony;
    return l10n.roomNone;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final service = RoomService();

    return StreamBuilder<List<Room>>(
      stream: service.watchRooms(),
      builder: (context, roomsSnapshot) {
        final rooms = roomsSnapshot.data ?? const <Room>[];
        final value = _label(l10n, rooms);
        return StreamBuilder<List<RoomSensorBinding>>(
          stream: service.watchSensors(),
          builder: (context, sensorsSnapshot) {
            final roomId = plant.effectiveRoomId;
            final hasSensor = roomId != null &&
                (sensorsSnapshot.data ?? const <RoomSensorBinding>[]).any(
                  (sensor) => sensor.roomId == roomId,
                );
            return _card(
              context,
              l10n: l10n,
              value: value,
              roomId: roomId,
              hasSensor: hasSensor,
            );
          },
        );
      },
    );
  }

  Widget _card(
    BuildContext context, {
    required AppLocalizations l10n,
    required String value,
    required String? roomId,
    required bool hasSensor,
  }) {
    final colors = context.colors;
    final spacing = context.spacing;
    final typography = context.typography;
    final radii = context.radii;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: spacing.sm,
        vertical: spacing.xxs,
      ),
      decoration: BoxDecoration(
        color: colors.modal,
        borderRadius: BorderRadius.circular(radii.sm),
        border: Border.all(color: colors.outline.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          ExcludeSemantics(
            child: Icon(
              context.icons.room,
              size: context.dimensions.iconMd,
              color: colors.icon,
            ),
          ),
          spacing.hSm,
          Expanded(
            child: Semantics(
              button: true,
              label: '${l10n.a11yPlantRoom}, $value',
              child: FocusableTap(
                borderRadius: BorderRadius.circular(radii.sm),
                onTap: () => _pick(context),
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: spacing.xs),
                  child: Text(
                    value,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: typography.bodyEmphasis.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (hasSensor && roomId != null)
            IconButton(
              tooltip: l10n.a11yRoomSensor,
              visualDensity: VisualDensity.compact,
              onPressed: () => showRoomSensorSheet(
                context: context,
                roomId: roomId,
                roomName: value,
              ),
              icon: Icon(
                context.icons.sensor,
                color: colors.success,
                size: context.dimensions.iconMd,
              ),
            ),
          IconButton(
            tooltip: l10n.a11yPlantRoom,
            visualDensity: VisualDensity.compact,
            onPressed: () => _pick(context),
            icon: Icon(
              context.icons.chevronRight,
              color: colors.icon,
              size: context.dimensions.iconMd,
            ),
          ),
        ],
      ),
    );
  }
}
