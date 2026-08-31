import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:plontukrot/core/theme/theme_context.dart';
import 'package:plontukrot/core/widgets/app_modal.dart';
import 'package:plontukrot/l10n/app_localizations.dart';
import 'package:plontukrot/services/telegram_service.dart';
import 'package:url_launcher/url_launcher.dart';

/// Lets the user link their Telegram chat to their plontukrot account so
/// alerts (water the pot, bring the plant inside) reach them.
class TelegramLinkTile extends StatefulWidget {
  const TelegramLinkTile({super.key});

  @override
  State<TelegramLinkTile> createState() => _TelegramLinkTileState();
}

class _TelegramLinkTileState extends State<TelegramLinkTile> {
  final TelegramService _service = TelegramService();
  late final Stream<bool> _linkedStream;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _linkedStream = _service.watchLinked();
  }

  Future<void> _link() async {
    if (_busy) return;
    final l10n = AppLocalizations.of(context);
    setState(() => _busy = true);
    try {
      final link = await _service.createLink();
      if (!mounted) return;
      // Copy the deep-link so the user can paste it into Telegram, and offer
      // to open it directly.
      await Clipboard.setData(ClipboardData(text: link.deepLink));
      if (!mounted) return;
      final copied = await showAppDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.telegramLinkTitle),
          content: Text(l10n.telegramLinkCopied),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.commonCancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.telegramLinkOpen),
            ),
          ],
        ),
      );
      if (copied == true && mounted) {
        await launchUrl(
          Uri.parse(link.deepLink),
          mode: LaunchMode.externalApplication,
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.telegramLinkError)),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _unlink() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await _service.unlink();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).commonError(''))),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final typography = context.typography;

    return StreamBuilder<bool>(
      stream: _linkedStream,
      builder: (context, snapshot) {
        final linked = snapshot.data ?? false;
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: ExcludeSemantics(
            child: HugeIcon(
              icon: linked
                  ? HugeIcons.strokeRoundedCheckmarkCircle01
                  : HugeIcons.strokeRoundedTelegram,
              color: linked ? colors.success : colors.icon,
            ),
          ),
          title: Text(
            l10n.telegramLinkTitle,
            style: typography.bodyEmphasis,
          ),
          subtitle: Text(
            linked ? l10n.telegramLinkLinked : l10n.telegramLinkSubtitle,
            style: typography.bodySmall.copyWith(color: colors.textSecondary),
          ),
          trailing: ExcludeSemantics(
            child: Icon(context.icons.chevronRight, color: colors.icon),
          ),
          onTap: _busy
              ? null
              : linked
                  ? _unlink
                  : _link,
        );
      },
    );
  }
}
