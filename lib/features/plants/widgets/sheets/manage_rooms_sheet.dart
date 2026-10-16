import 'package:flutter/material.dart';
import 'package:plontukrot/core/widgets/accessible_progress_indicator.dart';
import 'package:plontukrot/core/widgets/app_modal.dart';
import 'package:plontukrot/core/widgets/prompt_text_dialog.dart';
import 'package:plontukrot/core/widgets/sheet_drag_handle.dart';
import 'package:plontukrot/l10n/app_localizations.dart';

import '../../../../core/features/feature_flags.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../models/room.dart';
import '../../../../services/plant_service.dart';
import '../../../../services/room_service.dart';

Future<void> showManageRoomsSheet(BuildContext context) {
  return showAppModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    enableDrag: true,
    builder: (_) => const ManageRoomsSheet(),
  );
}

class ManageRoomsSheet extends StatefulWidget {
  const ManageRoomsSheet({super.key});

  @override
  State<ManageRoomsSheet> createState() => _ManageRoomsSheetState();
}

class _ManageRoomsSheetState extends State<ManageRoomsSheet> {
  final _service = RoomService();
  Map<String, String> _sensors = const {};

  @override
  void initState() {
    super.initState();
    _loadSensors();
  }

  Future<void> _loadSensors() async {
    try {
      final sensors = await _service.fetchSensors();
      if (!mounted) return;
      setState(() {
        _sensors = {for (final sensor in sensors) sensor.roomId: sensor.deviceId};
      });
    } catch (_) {}
  }

  Future<void> _editSensor(String roomId) async {
    final l10n = AppLocalizations.of(context);
    final value = await showPromptTextDialog(
      context: context,
      title: l10n.roomSensorTitle,
      initial: _sensors[roomId] ?? '',
      labelText: l10n.roomSensorIdLabel,
      hintText: l10n.roomSensorIdHint,
      allowEmpty: true,
      confirmLabel: l10n.commonSave,
    );
    if (value == null || !mounted) return;
    final deviceId = value.trim();
    try {
      if (deviceId.isEmpty) {
        await _service.clearSensor(roomId);
      } else {
        await _service.setSensor(roomId: roomId, deviceId: deviceId);
      }
      await FeatureFlagsController.instance.refresh();
      await _loadSensors();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.commonError(''))),
      );
    }
  }

  Widget? _sensorSubtitle(String roomId) {
    final deviceId = _sensors[roomId];
    if (deviceId == null || deviceId.isEmpty) return null;
    return Text(
      deviceId,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _sensorButton(String roomId) {
    final l10n = AppLocalizations.of(context);
    final hasSensor = (_sensors[roomId] ?? '').isNotEmpty;
    return IconButton(
      tooltip: l10n.a11yRoomSensor,
      isSelected: hasSensor,
      visualDensity: VisualDensity.compact,
      icon: Icon(
        context.icons.sensor,
        color: hasSensor ? context.colors.success : context.colors.error,
      ),
      onPressed: () => _editSensor(roomId),
    );
  }

  Future<String?> _promptName({
    required String title,
    String initial = '',
  }) {
    final l10n = AppLocalizations.of(context);
    return showPromptTextDialog(
      context: context,
      title: title,
      initial: initial,
      labelText: l10n.roomNameHint,
      confirmLabel: l10n.commonSave,
    );
  }

  Future<void> _add() async {
    final l10n = AppLocalizations.of(context);
    final name = await _promptName(title: l10n.roomAddTitle);
    if (name == null || !mounted) return;
    if (await _service.findRoomByName(name) != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.catalogItemAlreadyExists(name))),
      );
      return;
    }
    await _service.addRoom(name: name);
  }

  Future<void> _edit(Room room) async {
    final l10n = AppLocalizations.of(context);
    final name = await _promptName(
      title: l10n.roomEditTitle,
      initial: room.name,
    );
    if (name == null || name == room.name || !mounted) return;
    final existing = await _service.findRoomByName(name);
    if (existing != null && existing.id != room.id) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.catalogItemAlreadyExists(name))),
      );
      return;
    }
    await _service.updateRoom(roomId: room.id, name: name);
  }

  Future<void> _delete(Room room) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showAppDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: context.colors.modal,
          title: Text(l10n.roomDeleteTitle),
          content: Text(l10n.catalogItemDeleteConfirm(room.name)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.commonCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.commonDelete),
            ),
          ],
        );
      },
    );
    if (confirmed != true) return;
    await _service.deleteRoom(room.id);
    if (room.isBalcony) {
      await PlantService().recalculateAutoFertilizingFrequencies();
    }
  }

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
                  spacing.hXs,
                  FilledButton.icon(
                    onPressed: _add,
                    icon: Icon(context.icons.add),
                    label: Text(l10n.commonAdd),
                  ),
                ],
              ),
              spacing.vXs,
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  l10n.manageRoomsHint,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: typography.caption.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ),
              spacing.vSm,
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.45,
                child: StreamBuilder<List<Room>>(
                  stream: _service.watchRooms(),
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
                    final items = snapshot.data!;
                    if (items.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return ListView.separated(
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        return _roomTile(items[index], l10n);
                      },
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

  Widget _roomTile(Room room, AppLocalizations l10n) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: ExcludeSemantics(
        child: Icon(context.icons.room, color: context.colors.icon),
      ),
      title: Text(
        room.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: _sensorSubtitle(room.id),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _sensorButton(room.id),
          IconButton(
            tooltip: l10n.commonEdit,
            visualDensity: VisualDensity.compact,
            icon: Icon(context.icons.editOutlined),
            onPressed: () => _edit(room),
          ),
          IconButton(
            tooltip: l10n.commonDelete,
            visualDensity: VisualDensity.compact,
            icon: Icon(context.icons.delete),
            onPressed: () => _delete(room),
          ),
        ],
      ),
    );
  }
}
