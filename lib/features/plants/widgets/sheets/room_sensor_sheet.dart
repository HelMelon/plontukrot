import 'package:flutter/material.dart';
import 'package:plontukrot/core/theme/theme_context.dart';
import 'package:plontukrot/core/widgets/accessible_progress_indicator.dart';
import 'package:plontukrot/core/widgets/app_modal.dart';
import 'package:plontukrot/core/widgets/sheet_drag_handle.dart';
import 'package:plontukrot/l10n/app_localizations.dart';

import '../../../../models/room.dart';
import '../../../../services/room_service.dart';

Future<void> showRoomSensorSheet({
  required BuildContext context,
  required String roomId,
  required String roomName,
}) {
  return showAppModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    enableDrag: true,
    builder: (_) => RoomSensorSheet(roomId: roomId, roomName: roomName),
  );
}

class RoomSensorSheet extends StatefulWidget {
  final String roomId;
  final String roomName;

  const RoomSensorSheet({
    super.key,
    required this.roomId,
    required this.roomName,
  });

  @override
  State<RoomSensorSheet> createState() => _RoomSensorSheetState();
}

class _RoomSensorSheetState extends State<RoomSensorSheet> {
  late final Future<List<RoomSensorProperty>> _reading;

  @override
  void initState() {
    super.initState();
    _reading = RoomService().fetchSensorReading(widget.roomId);
  }

  String _label(AppLocalizations l10n, String instance) {
    return switch (instance) {
      'temperature' => l10n.roomSensorTemperature,
      'humidity' => l10n.roomSensorHumidity,
      _ => instance,
    };
  }

  String _value(RoomSensorProperty property) {
    final value = property.value;
    if (value is num && property.instance == 'temperature') {
      return '${value.toStringAsFixed(1)}°C';
    }
    if (value is num && property.instance == 'humidity') {
      return '${value.toStringAsFixed(0)}%';
    }
    return '$value';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final spacing = context.spacing;
    final typography = context.typography;
    final sheets = context.components.sheets;
    final title = widget.roomName.trim().isEmpty
        ? l10n.roomSensorTitle
        : widget.roomName;

    return Material(
      color: colors.modal,
      borderRadius: sheets.topBorderRadius,
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: spacing.allMd,
          child: FutureBuilder<List<RoomSensorProperty>>(
            future: _reading,
            builder: (context, snapshot) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(child: SheetDragHandle()),
                  spacing.vMd,
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: typography.titleMedium,
                  ),
                  spacing.vSm,
                  if (snapshot.connectionState != ConnectionState.done)
                    Padding(
                      padding: spacing.allMd,
                      child: const Center(child: AccessibleProgressIndicator()),
                    )
                  else if (snapshot.hasError)
                    Text(
                      l10n.roomSensorUnavailable,
                      style: typography.bodyMedium.copyWith(color: colors.error),
                    )
                  else if ((snapshot.data ?? const []).isEmpty)
                    Text(
                      l10n.roomSensorNoData,
                      style: typography.bodyMedium.copyWith(
                        color: colors.textSecondary,
                      ),
                    )
                  else
                    for (final property in snapshot.data!)
                      Padding(
                        padding: EdgeInsets.only(bottom: spacing.xs),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _label(l10n, property.instance),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: typography.bodyMedium,
                              ),
                            ),
                            spacing.hSm,
                            Text(
                              _value(property),
                              style: typography.bodyEmphasis,
                            ),
                          ],
                        ),
                      ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
