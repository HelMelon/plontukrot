import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:plontukrot/core/l10n/app_localizations_x.dart';
import 'package:plontukrot/l10n/app_localizations.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/currency/app_currency.dart';
import '../../../core/currency/app_currency_controller.dart';
import '../../../core/locale/app_locale_controller.dart';
import '../../../core/privacy/privacy_constants.dart';
import '../../../core/theme/theme_context.dart';
import '../../../core/widgets/prompt_text_dialog.dart';
import '../../../models/app_user.dart';
import '../../../models/plant.dart';
import '../../../models/propagation.dart';
import '../../../services/auth_service.dart';
import '../../../services/firestore_service.dart';
import '../../../services/plant_service.dart';
import '../../../services/propagation_service.dart';
import '../../friends/pages/friends_page.dart';
import 'package:plontukrot/core/widgets/accessible_progress_indicator.dart';

class ProfilePage extends StatefulWidget {
  final AppUser user;

  const ProfilePage({super.key, required this.user});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late final Stream<List<Plant>> _plantsStream;
  late final Stream<List<Propagation>> _propagationsStream;
  late final Stream<UserProfileDoc> _profileStream;
  bool _busy = false;
  String? _busyMessage;

  @override
  void initState() {
    super.initState();
    _plantsStream = PlantService().getPlants();
    _propagationsStream = PropagationService().watchActivePropagations();
    _profileStream = FirestoreService().watchUserProfile();
  }

  String _currencyLabel(AppLocalizations l10n, AppCurrency currency) {
    return switch (currency) {
      AppCurrency.usd => l10n.settingsCurrencyUsd,
      AppCurrency.eur => l10n.settingsCurrencyEur,
      AppCurrency.rub => l10n.settingsCurrencyRub,
      AppCurrency.byn => l10n.settingsCurrencyByn,
    };
  }

  String? _modeValue(Iterable<String> values) {
    final counts = <String, int>{};
    for (final raw in values) {
      final value = raw.trim();
      if (value.isEmpty) continue;
      counts[value] = (counts[value] ?? 0) + 1;
    }
    if (counts.isEmpty) return null;
    String? best;
    var bestCount = 0;
    counts.forEach((key, count) {
      if (count > bestCount) {
        best = key;
        bestCount = count;
      }
    });
    return best;
  }

  Future<void> _openPrivacyPolicy() async {
    final uri = Uri.parse(kPrivacyPolicyUrl);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _exportPlantNames() async {
    if (_busy) return;
    final l10n = AppLocalizations.of(context);
    setState(() {
      _busy = true;
      _busyMessage = l10n.profileExportingPlants;
    });
    try {
      final plants = await PlantService().getPlants().first;
      if (!mounted) return;
      if (plants.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.profileExportPlantsEmpty)),
        );
        return;
      }

      int comparePlants(Plant a, Plant b) {
        final speciesCmp =
            a.species.toLowerCase().compareTo(b.species.toLowerCase());
        if (speciesCmp != 0) return speciesCmp;
        return a.nickname.toLowerCase().compareTo(b.nickname.toLowerCase());
      }

      Map<String, dynamic> plantPayload(Plant plant) => {
            'genus': plant.genus.trim(),
            'species': plant.species.trim(),
            'cultivar': plant.cultivarsDisplay,
            'nickname': plant.nickname.trim(),
          };

      final grouped = <int, List<Plant>>{};
      for (final plant in plants) {
        grouped.putIfAbsent(plant.stage, () => <Plant>[]).add(plant);
      }
      final stageKeys = grouped.keys.toList()..sort();

      final stages = <Map<String, dynamic>>[];
      for (final stage in stageKeys) {
        final stagePlants = List<Plant>.from(grouped[stage]!)..sort(comparePlants);
        stages.add({
          'stage': l10n.stageTitle(stage),
          'count': stagePlants.length,
          'plants': [for (final plant in stagePlants) plantPayload(plant)],
        });
      }

      final payload = <String, dynamic>{
        'uid': widget.user.uid,
        'exportedAt': DateTime.now().toUtc().toIso8601String(),
        'fields': ['cultivar', 'genus', 'nickname', 'species'],
        'count': plants.length,
        'stages': stages,
      };

      final dateStamp = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final fileName = 'plants-names-$dateStamp.json';
      final bytes = utf8.encode(
        const JsonEncoder.withIndent('  ').convert(payload),
      );

      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(
              bytes,
              mimeType: 'application/json',
              name: fileName,
            ),
          ],
          fileNameOverrides: [fileName],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.commonError(e.toString()))),
      );
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _busyMessage = null;
        });
      }
    }
  }

  Future<void> _signOut() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _busyMessage = null;
    });
    try {
      await AuthService().signOut();
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.commonError(e.toString()))),
      );
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _busyMessage = null;
        });
      }
    }
  }

  Future<void> _deleteAccount() async {
    if (_busy) return;
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.profileDeleteAccountConfirmTitle),
        content: Text(l10n.profileDeleteAccountConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.profileDeleteAccountConfirmAction),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final auth = AuthService();
    String? password;
    if (auth.requiresPasswordToDelete) {
      password = await showPromptTextDialog(
        context: context,
        title: l10n.profileDeleteAccountPasswordTitle,
        labelText: l10n.profileDeleteAccountPasswordHint,
        confirmLabel: l10n.profileDeleteAccountConfirmAction,
        obscureText: true,
        textCapitalization: TextCapitalization.none,
      );
      if (password == null || !mounted) return;
    }

    setState(() {
      _busy = true;
      _busyMessage = l10n.profileDeletingAccount;
    });
    try {
      await auth.deleteAccount(password: password);
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      if (!mounted) return;
      final kind = AuthService.classifyFailure(e);
      final message = switch (kind) {
        AuthFailureKind.cancelled => null,
        AuthFailureKind.network => l10n.authSignInNetworkError,
        AuthFailureKind.missingIdToken => l10n.authGoogleIdTokenMissing,
        AuthFailureKind.invalidEmail => l10n.authInvalidEmail,
        AuthFailureKind.weakPassword => l10n.authWeakPassword,
        AuthFailureKind.emailAlreadyInUse => l10n.authEmailAlreadyInUse,
        AuthFailureKind.invalidCredentials => l10n.authInvalidCredentials,
        AuthFailureKind.tooManyRequests => l10n.authTooManyRequests,
        AuthFailureKind.unknown => l10n.profileDeleteAccountFailed,
      };
      if (message == null) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _busyMessage = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final spacing = context.spacing;
    final radii = context.radii;
    final typography = context.typography;
    final dimensions = context.dimensions;
    final profileTheme = context.screens.profile;
    final localeController = AppLocaleController.instance;
    final currencyController = AppCurrencyController.instance;

    final languageOptions = <({String code, String label})>[
      (code: AppLocaleController.systemCode, label: l10n.settingsLanguageSystem),
      (code: 'en', label: l10n.settingsLanguageEnglish),
      (code: 'ru', label: l10n.settingsLanguageRussian),
      (code: 'de', label: l10n.settingsLanguageGerman),
      (code: 'fr', label: l10n.settingsLanguageFrench),
    ];

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(l10n.profileTitle),
      ),
      body: Stack(
        children: [
          ListView(
            padding: spacing.allMd,
            children: [
              StreamBuilder<UserProfileDoc>(
                stream: _profileStream,
                builder: (context, profileSnap) {
                  final profile = profileSnap.data;
                  final name = (profile?.name?.isNotEmpty == true)
                      ? profile!.name!
                      : (l10n.commonUntitled);
                  final email = profile?.email ?? '';
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: profileTheme.avatarSize,
                        height: profileTheme.avatarSize,
                        child: ClipOval(
                          child: widget.user.photoUrl != null &&
                                  widget.user.photoUrl!.isNotEmpty
                              ? Semantics(
                                  image: true,
                                  label: l10n.a11yProfilePhoto,
                                  child: ExcludeSemantics(
                                    child: Image.network(
                                      widget.user.photoUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Icon(
                                        Icons.person,
                                        color: colors.icon,
                                        size: dimensions.iconXl,
                                      ),
                                    ),
                                  ),
                                )
                              : ExcludeSemantics(
                                  child: Icon(
                                    Icons.person,
                                    color: colors.icon,
                                    size: dimensions.iconXl,
                                  ),
                                ),
                        ),
                      ),
                      spacing.hMd,
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: typography.titleMedium.copyWith(
                                color: colors.heading,
                              ),
                            ),
                            if (email.isNotEmpty) ...[
                              spacing.vXxs,
                              Text(
                                email,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: typography.bodySmall.copyWith(
                                  color: colors.textSecondary,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
              spacing.vXl,
              StreamBuilder<List<Plant>>(
                stream: _plantsStream,
                builder: (context, plantSnap) {
                  return StreamBuilder<List<Propagation>>(
                    stream: _propagationsStream,
                    builder: (context, propSnap) {
                      final plants = plantSnap.data ?? const <Plant>[];
                      final props = propSnap.data ?? const <Propagation>[];
                      final loading = (!plantSnap.hasData &&
                              plantSnap.connectionState ==
                                  ConnectionState.waiting) ||
                          (!propSnap.hasData &&
                              propSnap.connectionState ==
                                  ConnectionState.waiting);
                      final favoriteFamily = _modeValue(
                        plants.map((p) => p.plantFamily ?? ''),
                      );
                      final favoriteGenus = _modeValue(
                        plants.map((p) => p.genus),
                      );

                      return DecoratedBox(
                        decoration: BoxDecoration(
                          color: profileTheme.statCardColor,
                          borderRadius: BorderRadius.circular(radii.md),
                        ),
                        child: Padding(
                          padding: spacing.allMd,
                          child: loading
                              ? Center(
                                  child: Padding(
                                    padding: spacing.allMd,
                                    child: AccessibleProgressIndicator(
                                      color: colors.primary,
                                    ),
                                  ),
                                )
                              : Column(
                                  children: [
                                    _StatRow(
                                      label: l10n.profilePlantCount,
                                      value: '${plants.length}',
                                    ),
                                    spacing.vSm,
                                    _StatRow(
                                      label: l10n.profileFavoriteFamily,
                                      value: favoriteFamily ??
                                          l10n.profileEmDash,
                                    ),
                                    spacing.vSm,
                                    _StatRow(
                                      label: l10n.profileFavoriteGenus,
                                      value: favoriteGenus ??
                                          l10n.profileEmDash,
                                    ),
                                    spacing.vSm,
                                    _StatRow(
                                      label: l10n.profileActivePropagations,
                                      value: '${props.length}',
                                    ),
                                  ],
                                ),
                        ),
                      );
                    },
                  );
                },
              ),
              spacing.vXl,
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: ExcludeSemantics(
                  child: Icon(Icons.people_outline, color: colors.icon),
                ),
                title: Text(
                  l10n.profileFriends,
                  style: typography.bodyEmphasis,
                ),
                trailing: ExcludeSemantics(
                  child: Icon(Icons.chevron_right, color: colors.icon),
                ),
                onTap: _busy
                    ? null
                    : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const FriendsPage(),
                          ),
                        );
                      },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: ExcludeSemantics(
                  child: Icon(Icons.upload_file_outlined, color: colors.icon),
                ),
                title: Text(
                  l10n.profileExportPlants,
                  style: typography.bodyEmphasis,
                ),
                onTap: _busy ? null : _exportPlantNames,
              ),
              spacing.vXl,
              ListenableBuilder(
                listenable: Listenable.merge([
                  localeController,
                  currencyController,
                ]),
                builder: (context, _) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      DropdownButtonFormField<String>(
                        key: ValueKey(localeController.preferenceCode),
                        initialValue: localeController.preferenceCode,
                        isExpanded: true,
                        style: profileTheme.dropdownTextStyle,
                        decoration: InputDecoration(
                          labelText: l10n.settingsLanguage,
                        ),
                        items: [
                          for (final option in languageOptions)
                            DropdownMenuItem(
                              value: option.code,
                              child: Text(
                                option.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: profileTheme.dropdownTextStyle,
                              ),
                            ),
                        ],
                        onChanged: _busy
                            ? null
                            : (code) {
                                if (code == null) return;
                                localeController.setPreference(code);
                              },
                      ),
                      spacing.vMd,
                      DropdownButtonFormField<AppCurrency>(
                        key: ValueKey(currencyController.currency.code),
                        initialValue: currencyController.currency,
                        isExpanded: true,
                        style: profileTheme.dropdownTextStyle,
                        decoration: InputDecoration(
                          labelText: l10n.settingsCurrency,
                        ),
                        items: [
                          for (final currency in AppCurrency.values)
                            DropdownMenuItem(
                              value: currency,
                              child: Text(
                                '${_currencyLabel(l10n, currency)} · ${currency.code}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: profileTheme.dropdownTextStyle,
                              ),
                            ),
                        ],
                        onChanged: _busy
                            ? null
                            : (currency) {
                                if (currency == null) return;
                                currencyController.setCurrency(currency);
                              },
                      ),
                    ],
                  );
                },
              ),
              spacing.vXl,
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  l10n.profileConsentAccepted,
                  style: typography.bodyMedium,
                ),
                subtitle: TextButton(
                  onPressed: _openPrivacyPolicy,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    alignment: Alignment.centerLeft,
                  ),
                  child: Text(
                    l10n.privacyPolicyLink,
                    style: typography.bodyMedium.copyWith(
                      color: profileTheme.privacyLinkColor,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
              spacing.vXl,
              SizedBox(
                height: dimensions.buttonHeight,
                child: OutlinedButton(
                  onPressed: _busy ? null : _signOut,
                  child: Text(l10n.authSignOut),
                ),
              ),
              spacing.vMd,
              SizedBox(
                height: dimensions.buttonHeight,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: profileTheme.dangerButtonBackground,
                    foregroundColor: profileTheme.dangerButtonForeground,
                  ),
                  onPressed: _busy ? null : _deleteAccount,
                  child: Text(l10n.profileDeleteAccount),
                ),
              ),
              spacing.vXxxl,
            ],
          ),
          if (_busy)
            ColoredBox(
              color: colors.screen.withValues(alpha: 0.55),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AccessibleProgressIndicator(color: colors.primary),
                    if (_busyMessage != null) ...[
                      spacing.vMd,
                      Text(
                        _busyMessage!,
                        style: typography.bodyLarge,
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;

  const _StatRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final profileTheme = context.screens.profile;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Flexible(
          child: Text(
            label,
            style: profileTheme.statLabelStyle,
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: profileTheme.statValueStyle,
          ),
        ),
      ],
    );
  }
}
