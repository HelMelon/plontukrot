import 'package:flutter/material.dart';
import 'package:plontukrot/core/app_version_info.dart';
import 'package:plontukrot/core/theme/theme_context.dart';
import 'package:plontukrot/l10n/app_localizations.dart';

/// Pinned footer: app name, semver, copyright year.
class AppFooter extends StatefulWidget {
  const AppFooter({super.key});

  @override
  State<AppFooter> createState() => _AppFooterState();
}

class _AppFooterState extends State<AppFooter> {
  late final Future<String> _versionFuture;

  @override
  void initState() {
    super.initState();
    _versionFuture = AppVersionInfo.versionLabel();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final year = DateTime.now().year.toString();

    return FutureBuilder<String>(
      future: _versionFuture,
      builder: (context, snapshot) {
        final version = snapshot.data ?? '...';
        final brand = l10n.appBrandName;
        final footer = context.components.footer;
        final meta = ' · · v.$version · · © $year';

        return Semantics(
          label: l10n.a11yAppFooter(brand, version, year),
          child: Material(
            color: colors.screen.withValues(alpha: 0.92),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: footer.padding,
                child: Center(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: brand,
                          style: footer.brandTextStyle,
                        ),
                        TextSpan(
                          text: meta,
                          style: footer.textStyle,
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
