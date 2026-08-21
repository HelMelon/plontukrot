import 'package:flutter/material.dart';
import 'package:plontukrot/l10n/app_localizations.dart';

import '../../features/plants/widgets/search/plant_search_delegate.dart';
import '../../features/profile/pages/profile_page.dart';
import '../../models/app_user.dart';
import '../../services/auth_service.dart';
import '../theme/theme_context.dart';
import 'focusable_tap.dart';

/// Shared AppBar trailing chrome: plant search + optional profile avatar.
List<Widget> buildAppBarChromeActions(
  BuildContext context, {
  AppUser? user,
  bool showProfile = true,
}) {
  final resolvedUser = user ?? AuthService().currentUser;
  if (resolvedUser == null) return const [];

  final l10n = AppLocalizations.of(context);
  final colors = context.colors;
  final spacing = context.spacing;
  final avatarSize = context.screens.home.avatarSize;

  return [
    IconButton(
      tooltip: l10n.a11yOpenSearch,
      onPressed: () {
        showSearch(
          context: context,
          delegate: PlantSearchDelegate(
            searchFieldLabel: l10n.homeSearchHint,
          ),
        );
      },
      icon: Icon(context.icons.search, color: colors.icon),
    ),
    if (showProfile)
      Padding(
        padding: EdgeInsets.symmetric(horizontal: spacing.xxs),
        child: Center(
          child: Semantics(
            button: true,
            label: l10n.a11yOpenProfile,
            child: Tooltip(
              message: l10n.profileTitle,
              child: FocusableTap(
                borderRadius: BorderRadius.circular(avatarSize / 2),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ProfilePage(user: resolvedUser),
                    ),
                  );
                },
                child: SizedBox(
                  width: avatarSize,
                  height: avatarSize,
                  child: ClipOval(
                    child: ExcludeSemantics(
                      child: resolvedUser.photoUrl != null &&
                              resolvedUser.photoUrl!.isNotEmpty
                          ? Image.network(
                              resolvedUser.photoUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Icon(
                                context.icons.profile,
                                color: colors.icon,
                              ),
                            )
                          : Icon(context.icons.profile, color: colors.icon),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
  ];
}
