import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:plontukrot/l10n/app_localizations.dart';

import '../../../core/features/feature_flags.dart';
import '../../../core/theme/theme_context.dart';
import '../../../core/widgets/accessible_progress_indicator.dart';
import '../../../core/widgets/app_modal.dart';
import '../../../core/widgets/prompt_text_dialog.dart';
import '../../../services/auth_service.dart';
import '../../../services/fertilizing_notification_service.dart';

/// Admin tab content: users table, archive, per-user flags, ban/unban, delete.
class AdminPanelTab extends StatefulWidget {
  const AdminPanelTab({super.key});

  @override
  State<AdminPanelTab> createState() => _AdminPanelTabState();
}

class _AdminPanelTabState extends State<AdminPanelTab> {
  final _userIdController = TextEditingController();
  bool _busy = false;
  bool _loadingUser = false;
  bool _loadingUsers = false;
  bool _loadingArchive = false;
  String? _errorText;
  AdminUserFeatures? _target;
  List<AdminUserSummary>? _users;
  List<AdminUserSummary>? _archived;

  @override
  void initState() {
    super.initState();
    final selfId = AuthService().currentUser?.uid;
    if (selfId != null && selfId.isNotEmpty) {
      _userIdController.text = selfId;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_bootstrap());
    });
  }

  Future<void> _bootstrap() async {
    await Future.wait<void>([
      _loadUsers(),
      if (_userIdController.text.trim().isNotEmpty) _loadUser(),
    ]);
  }

  @override
  void dispose() {
    _userIdController.dispose();
    super.dispose();
  }

  String _label(AppLocalizations l10n, FeatureFlag flag) {
    switch (flag) {
      case FeatureFlag.friends:
        return l10n.featureFlagFriends;
      case FeatureFlag.wishList:
        return l10n.featureFlagWishList;
      case FeatureFlag.finances:
        return l10n.featureFlagFinances;
      case FeatureFlag.propagations:
        return l10n.featureFlagPropagations;
      case FeatureFlag.archive:
        return l10n.featureFlagArchive;
      case FeatureFlag.genusCare:
        return l10n.featureFlagGenusCare;
      case FeatureFlag.soilSensors:
        return l10n.featureFlagSoilSensors;
      case FeatureFlag.telegramAlerts:
        return l10n.featureFlagTelegramAlerts;
      case FeatureFlag.balcony:
        return l10n.featureFlagBalcony;
      case FeatureFlag.fertilizingReminders:
        return l10n.featureFlagFertilizingReminders;
      case FeatureFlag.bulkActions:
        return l10n.featureFlagBulkActions;
    }
  }

  String _formatDeletedAt(DateTime? value) {
    if (value == null) return '—';
    return DateFormat.yMd().add_Hm().format(value.toLocal());
  }

  Future<void> _loadUsers() async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _loadingUsers = true;
      _errorText = null;
    });
    try {
      final users = await FeatureFlagsController.instance.listUsers();
      if (!mounted) return;
      setState(() => _users = users);
    } catch (e) {
      if (!mounted) return;
      final message = l10n.commonError(e.toString());
      setState(() => _errorText = message);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } finally {
      if (mounted) setState(() => _loadingUsers = false);
    }
  }

  Future<void> _loadArchive() async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _loadingArchive = true;
      _errorText = null;
    });
    try {
      final archived =
          await FeatureFlagsController.instance.listArchivedUsers();
      if (!mounted) return;
      setState(() => _archived = archived);
    } catch (e) {
      if (!mounted) return;
      final message = l10n.commonError(e.toString());
      setState(() => _errorText = message);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } finally {
      if (mounted) setState(() => _loadingArchive = false);
    }
  }

  Future<void> _copyUserId(String userId) async {
    await Clipboard.setData(ClipboardData(text: userId));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).adminIdCopied)),
    );
  }

  Future<void> _selectUser(AdminUserSummary user) async {
    _userIdController.text = user.userId;
    await _loadUser();
  }

  Future<void> _loadUser() async {
    final l10n = AppLocalizations.of(context);
    final uid = _userIdController.text.trim();
    if (uid.isEmpty) {
      setState(() {
        _errorText = l10n.featureFlagsUserIdRequired;
        _target = null;
      });
      return;
    }
    setState(() {
      _loadingUser = true;
      _errorText = null;
    });
    try {
      final snapshot =
          await FeatureFlagsController.instance.loadUserFeatures(uid);
      if (!mounted) return;
      setState(() => _target = snapshot);
    } catch (e) {
      if (!mounted) return;
      final message = l10n.commonError(e.toString());
      setState(() {
        _target = null;
        _errorText = message;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } finally {
      if (mounted) setState(() => _loadingUser = false);
    }
  }

  Future<void> _onFlagChanged(FeatureFlag flag, bool enabled) async {
    final target = _target;
    if (_busy || target == null) return;
    final l10n = AppLocalizations.of(context);
    setState(() => _busy = true);
    try {
      final snapshot = await FeatureFlagsController.instance.setUserFlag(
        userId: target.userId,
        flag: flag,
        enabled: enabled,
      );
      if (!mounted) return;
      setState(() => _target = snapshot);
      if (target.userId == AuthService().currentUser?.uid &&
          flag == FeatureFlag.fertilizingReminders) {
        if (enabled) {
          await FertilizingNotificationService.instance.initialize();
          unawaited(
            FertilizingNotificationService.instance.rescheduleAllActivePlants(),
          );
        } else {
          unawaited(FertilizingNotificationService.instance.cancelAll());
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.commonError(e.toString()))),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _banUser() async {
    final target = _target;
    if (_busy || target == null) return;
    final l10n = AppLocalizations.of(context);
    if (target.userId == FeatureFlagsController.adminUserId ||
        target.userId == AuthService().currentUser?.uid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.featureFlagsCannotBanSelf)),
      );
      return;
    }
    final reason = await showPromptTextDialog(
      context: context,
      title: l10n.featureFlagsBanTitle,
      labelText: l10n.featureFlagsBanReasonLabel,
      confirmLabel: l10n.featureFlagsBanConfirm,
      allowEmpty: false,
    );
    if (reason == null || reason.trim().isEmpty || !mounted) return;

    setState(() => _busy = true);
    try {
      final snapshot = await FeatureFlagsController.instance.banUser(
        userId: target.userId,
        reason: reason,
      );
      if (!mounted) return;
      setState(() => _target = snapshot);
      if (_users != null) {
        unawaited(_loadUsers());
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.commonError(e.toString()))),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _unbanUser() async {
    final target = _target;
    if (_busy || target == null) return;
    final l10n = AppLocalizations.of(context);
    final confirmed = await showAppDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.featureFlagsUnbanTitle),
        content: Text(l10n.featureFlagsUnbanConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.featureFlagsUnbanAction),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _busy = true);
    try {
      final snapshot =
          await FeatureFlagsController.instance.unbanUser(target.userId);
      if (!mounted) return;
      setState(() => _target = snapshot);
      if (_users != null) {
        unawaited(_loadUsers());
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.commonError(e.toString()))),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _softDeleteUser() async {
    final target = _target;
    if (_busy || target == null) return;
    final l10n = AppLocalizations.of(context);
    if (target.userId == FeatureFlagsController.adminUserId ||
        target.userId == AuthService().currentUser?.uid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.featureFlagsCannotDeleteSelf)),
      );
      return;
    }
    final reason = await showPromptTextDialog(
      context: context,
      title: l10n.featureFlagsDeleteTitle,
      labelText: l10n.featureFlagsDeleteReasonLabel,
      confirmLabel: l10n.featureFlagsDeleteConfirm,
      allowEmpty: false,
    );
    if (reason == null || reason.trim().isEmpty || !mounted) return;

    setState(() => _busy = true);
    try {
      final snapshot = await FeatureFlagsController.instance.softDeleteUser(
        userId: target.userId,
        reason: reason,
      );
      if (!mounted) return;
      setState(() => _target = snapshot);
      unawaited(_loadUsers());
      if (_archived != null) {
        unawaited(_loadArchive());
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.commonError(e.toString()))),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restoreUser() async {
    final target = _target;
    if (_busy || target == null) return;
    final l10n = AppLocalizations.of(context);
    final confirmed = await showAppDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.featureFlagsRestoreTitle),
        content: Text(l10n.featureFlagsRestoreConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.featureFlagsRestoreAction),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _busy = true);
    try {
      final snapshot =
          await FeatureFlagsController.instance.restoreUser(target.userId);
      if (!mounted) return;
      setState(() => _target = snapshot);
      unawaited(_loadUsers());
      if (_archived != null) {
        unawaited(_loadArchive());
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.commonError(e.toString()))),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _usersTable({
    required AppLocalizations l10n,
    required List<AdminUserSummary> users,
    required bool showDeletedAt,
  }) {
    final colors = context.colors;
    final spacing = context.spacing;
    final typography = context.typography;
    final dimensions = context.dimensions;
    final target = _target;
    final blocked = _busy || _loadingUser || _loadingUsers || _loadingArchive;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        showCheckboxColumn: false,
        columnSpacing: spacing.md,
        headingRowHeight: dimensions.buttonHeight,
        dataRowMinHeight: dimensions.buttonHeight,
        dataRowMaxHeight: dimensions.buttonHeight + spacing.md,
        columns: [
          DataColumn(label: Text(l10n.adminColumnName)),
          DataColumn(label: Text(l10n.adminColumnEmail)),
          DataColumn(label: Text(l10n.adminColumnId)),
          DataColumn(label: Text(l10n.adminColumnStatus)),
          if (showDeletedAt)
            DataColumn(label: Text(l10n.adminColumnDeletedAt)),
          DataColumn(label: Text(l10n.adminColumnActions)),
        ],
        rows: [
          for (final user in users)
            DataRow(
              selected: target?.userId == user.userId,
              onSelectChanged: blocked ? null : (_) => _selectUser(user),
              cells: [
                DataCell(
                  SizedBox(
                    width: 120,
                    child: Text(
                      (user.name ?? '').trim().isEmpty
                          ? l10n.commonUntitled
                          : user.name!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                DataCell(
                  SizedBox(
                    width: 160,
                    child: Text(
                      user.email ?? '—',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                DataCell(
                  SizedBox(
                    width: 140,
                    child: Text(
                      user.userId,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: typography.bodyMedium,
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    user.deleted
                        ? l10n.adminStatusDeleted
                        : user.banned
                            ? l10n.adminStatusBanned
                            : l10n.adminStatusActive,
                    style: typography.bodyMedium.copyWith(
                      color: user.deleted || user.banned
                          ? colors.error
                          : null,
                    ),
                  ),
                ),
                if (showDeletedAt)
                  DataCell(
                    Text(
                      _formatDeletedAt(user.deletedAt),
                      style: typography.bodyMedium,
                    ),
                  ),
                DataCell(
                  IconButton(
                    tooltip: l10n.adminCopyId,
                    onPressed:
                        blocked ? null : () => _copyUserId(user.userId),
                    icon: Icon(Icons.copy_outlined, color: colors.icon),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final spacing = context.spacing;
    final typography = context.typography;
    final dimensions = context.dimensions;
    final target = _target;
    final blocked = _busy || _loadingUser || _loadingUsers || _loadingArchive;
    final users = _users;
    final archived = _archived;

    return ListView(
      padding: EdgeInsets.fromLTRB(
        spacing.md,
        spacing.sm,
        spacing.md,
        spacing.xxxl,
      ),
      children: [
        Text(
          l10n.profileFeatureFlagsSubtitle,
          style: typography.bodyMedium,
        ),
        spacing.vMd,
        SizedBox(
          height: dimensions.buttonHeight,
          child: OutlinedButton(
            onPressed: blocked ? null : _loadUsers,
            child: _loadingUsers
                ? AccessibleProgressIndicator(
                    color: colors.primary,
                    size: dimensions.iconMd,
                  )
                : Text(l10n.adminShowUsers),
          ),
        ),
        spacing.vSm,
        SizedBox(
          height: dimensions.buttonHeight,
          child: OutlinedButton(
            onPressed: blocked ? null : _loadArchive,
            child: _loadingArchive
                ? AccessibleProgressIndicator(
                    color: colors.primary,
                    size: dimensions.iconMd,
                  )
                : Text(l10n.adminShowArchive),
          ),
        ),
        if (_errorText != null) ...[
          spacing.vSm,
          Text(
            _errorText!,
            style: typography.bodyMedium.copyWith(color: colors.error),
          ),
        ],
        if (users != null) ...[
          spacing.vMd,
          Text(
            l10n.adminUsersCount(users.length),
            style: typography.bodyEmphasis,
          ),
          spacing.vSm,
          _usersTable(l10n: l10n, users: users, showDeletedAt: false),
        ],
        if (archived != null) ...[
          spacing.vXl,
          Text(
            l10n.adminArchivedCount(archived.length),
            style: typography.bodyEmphasis,
          ),
          if (archived.isNotEmpty) ...[
            spacing.vSm,
            _usersTable(l10n: l10n, users: archived, showDeletedAt: true),
          ],
        ],
        spacing.vXl,
        Text(
          l10n.profileFeatureFlagsTitle,
          style: typography.sectionTitle.copyWith(fontWeight: FontWeight.bold),
        ),
        spacing.vSm,
        TextField(
          controller: _userIdController,
          enabled: !blocked,
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => _loadUser(),
          inputFormatters: [
            FilteringTextInputFormatter.deny(RegExp(r'\s')),
          ],
          decoration: InputDecoration(
            labelText: l10n.featureFlagsUserIdLabel,
          ),
        ),
        spacing.vSm,
        SizedBox(
          height: dimensions.buttonHeight,
          child: OutlinedButton(
            onPressed: blocked ? null : _loadUser,
            child: _loadingUser
                ? AccessibleProgressIndicator(
                    color: colors.primary,
                    size: dimensions.iconMd,
                  )
                : Text(l10n.featureFlagsLoadUser),
          ),
        ),
        if (target != null) ...[
          spacing.vXl,
          Text(
            l10n.featureFlagsForUser(target.userId),
            style: typography.bodyEmphasis,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (target.deleted) ...[
            spacing.vSm,
            Text(
              l10n.authDeletedMessage(
                target.deleteReason ?? l10n.featureFlagsBanReasonUnknown,
              ),
              style: typography.bodyMedium.copyWith(color: colors.error),
            ),
            if (target.deletedAt != null) ...[
              spacing.vXs,
              Text(
                _formatDeletedAt(target.deletedAt),
                style: typography.bodyMedium,
              ),
            ],
          ],
          spacing.vSm,
          for (final flag in FeatureFlag.values)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                _label(l10n, flag),
                style: typography.bodyEmphasis,
              ),
              value: target.isEnabled(flag),
              onChanged: blocked || target.deleted
                  ? null
                  : (enabled) => _onFlagChanged(flag, enabled),
            ),
          spacing.vXl,
          Text(
            l10n.featureFlagsBanSectionTitle,
            style: typography.sectionTitle.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          spacing.vSm,
          if (target.banned) ...[
            Text(
              l10n.authBannedMessage(
                target.banReason ?? l10n.featureFlagsBanReasonUnknown,
              ),
              style: typography.bodyMedium.copyWith(color: colors.error),
            ),
            spacing.vMd,
            SizedBox(
              height: dimensions.buttonHeight,
              child: OutlinedButton(
                onPressed: blocked || target.deleted ? null : _unbanUser,
                child: Text(l10n.featureFlagsUnbanAction),
              ),
            ),
          ] else ...[
            Text(
              l10n.featureFlagsBanHint,
              style: typography.bodyMedium,
            ),
            spacing.vMd,
            SizedBox(
              height: dimensions.buttonHeight,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.error,
                  foregroundColor: colors.onPrimary,
                ),
                onPressed: blocked ||
                        target.deleted ||
                        target.userId == FeatureFlagsController.adminUserId
                    ? null
                    : _banUser,
                child: Text(l10n.featureFlagsBanConfirm),
              ),
            ),
          ],
          spacing.vXl,
          Text(
            l10n.featureFlagsDeleteSectionTitle,
            style: typography.sectionTitle.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          spacing.vSm,
          if (target.deleted) ...[
            Text(
              l10n.featureFlagsRestoreConfirm,
              style: typography.bodyMedium,
            ),
            spacing.vMd,
            SizedBox(
              height: dimensions.buttonHeight,
              child: ElevatedButton(
                onPressed: blocked ? null : _restoreUser,
                child: Text(l10n.featureFlagsRestoreAction),
              ),
            ),
          ] else ...[
            Text(
              l10n.featureFlagsDeleteHint,
              style: typography.bodyMedium,
            ),
            spacing.vMd,
            SizedBox(
              height: dimensions.buttonHeight,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.error,
                  foregroundColor: colors.onPrimary,
                ),
                onPressed: blocked ||
                        target.userId == FeatureFlagsController.adminUserId
                    ? null
                    : _softDeleteUser,
                child: Text(l10n.featureFlagsDeleteConfirm),
              ),
            ),
          ],
        ],
      ],
    );
  }
}
