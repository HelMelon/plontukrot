import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('fr'),
    Locale('ru')
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'SKÖRD'**
  String get appName;

  /// No description provided for @brandTagline.
  ///
  /// In en, this message translates to:
  /// **'A journal of the fight for light and moisture. Sprouts are no guarantee. Only observation.'**
  String get brandTagline;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// No description provided for @commonDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// No description provided for @commonEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get commonEdit;

  /// No description provided for @commonAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get commonAdd;

  /// No description provided for @commonClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonClose;

  /// No description provided for @commonBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get commonBack;

  /// No description provided for @commonClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get commonClear;

  /// No description provided for @commonMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get commonMore;

  /// No description provided for @a11yShowPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get a11yShowPassword;

  /// No description provided for @a11yHidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get a11yHidePassword;

  /// No description provided for @a11yExitSelection.
  ///
  /// In en, this message translates to:
  /// **'Exit selection mode'**
  String get a11yExitSelection;

  /// No description provided for @a11yOpenSearch.
  ///
  /// In en, this message translates to:
  /// **'Open plant search'**
  String get a11yOpenSearch;

  /// No description provided for @a11yPlantPhoto.
  ///
  /// In en, this message translates to:
  /// **'Plant photo'**
  String get a11yPlantPhoto;

  /// No description provided for @a11yGalleryPhoto.
  ///
  /// In en, this message translates to:
  /// **'Photo {current} of {total}'**
  String a11yGalleryPhoto(int current, int total);

  /// No description provided for @a11yLeafCount.
  ///
  /// In en, this message translates to:
  /// **'Leaves on vine: {count}'**
  String a11yLeafCount(int count);

  /// No description provided for @a11ySelectDate.
  ///
  /// In en, this message translates to:
  /// **'Choose date: {date}'**
  String a11ySelectDate(String date);

  /// No description provided for @a11yProfilePhoto.
  ///
  /// In en, this message translates to:
  /// **'Profile photo'**
  String get a11yProfilePhoto;

  /// No description provided for @a11yOpenProfile.
  ///
  /// In en, this message translates to:
  /// **'Open profile'**
  String get a11yOpenProfile;

  /// No description provided for @a11yLastFertilized.
  ///
  /// In en, this message translates to:
  /// **'Last fertilized: {date}'**
  String a11yLastFertilized(String date);

  /// No description provided for @a11yLastWatered.
  ///
  /// In en, this message translates to:
  /// **'Last watered: {date}'**
  String a11yLastWatered(String date);

  /// No description provided for @a11yPropagationBatches.
  ///
  /// In en, this message translates to:
  /// **'Propagation batches: {count}'**
  String a11yPropagationBatches(int count);

  /// No description provided for @plantPhotoAdd.
  ///
  /// In en, this message translates to:
  /// **'Add photo'**
  String get plantPhotoAdd;

  /// No description provided for @plantPhotoAttached.
  ///
  /// In en, this message translates to:
  /// **'Photo selected'**
  String get plantPhotoAttached;

  /// No description provided for @commonToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get commonToday;

  /// No description provided for @commonError.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String commonError(String error);

  /// No description provided for @commonShowMore.
  ///
  /// In en, this message translates to:
  /// **'Show more'**
  String get commonShowMore;

  /// No description provided for @commonLoadMore.
  ///
  /// In en, this message translates to:
  /// **'Load more'**
  String get commonLoadMore;

  /// No description provided for @commonCollapse.
  ///
  /// In en, this message translates to:
  /// **'Collapse'**
  String get commonCollapse;

  /// No description provided for @commonManage.
  ///
  /// In en, this message translates to:
  /// **'Manage'**
  String get commonManage;

  /// No description provided for @commonOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get commonOk;

  /// No description provided for @commonNoDate.
  ///
  /// In en, this message translates to:
  /// **'No date'**
  String get commonNoDate;

  /// No description provided for @commonNoData.
  ///
  /// In en, this message translates to:
  /// **'No data'**
  String get commonNoData;

  /// No description provided for @commonUntitled.
  ///
  /// In en, this message translates to:
  /// **'Untitled'**
  String get commonUntitled;

  /// No description provided for @commonComposition.
  ///
  /// In en, this message translates to:
  /// **'Composition'**
  String get commonComposition;

  /// No description provided for @unitMl.
  ///
  /// In en, this message translates to:
  /// **'ml'**
  String get unitMl;

  /// No description provided for @unitGrams.
  ///
  /// In en, this message translates to:
  /// **'g'**
  String get unitGrams;

  /// No description provided for @unitPiecesShort.
  ///
  /// In en, this message translates to:
  /// **'pcs'**
  String get unitPiecesShort;

  /// No description provided for @unitMlWithValue.
  ///
  /// In en, this message translates to:
  /// **'{value} ml'**
  String unitMlWithValue(int value);

  /// No description provided for @milliliters.
  ///
  /// In en, this message translates to:
  /// **'Milliliters'**
  String get milliliters;

  /// No description provided for @grams.
  ///
  /// In en, this message translates to:
  /// **'Grams'**
  String get grams;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get loading;

  /// No description provided for @preparing.
  ///
  /// In en, this message translates to:
  /// **'Preparing…'**
  String get preparing;

  /// No description provided for @authSignInGoogle.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google'**
  String get authSignInGoogle;

  /// No description provided for @authSigningIn.
  ///
  /// In en, this message translates to:
  /// **'Signing in…'**
  String get authSigningIn;

  /// No description provided for @authSignInError.
  ///
  /// In en, this message translates to:
  /// **'Sign-in error: {error}'**
  String authSignInError(String error);

  /// No description provided for @authSignInNetworkError.
  ///
  /// In en, this message translates to:
  /// **'No internet connection. Check your network and try again.'**
  String get authSignInNetworkError;

  /// No description provided for @authSignInFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not sign in. Please try again.'**
  String get authSignInFailed;

  /// No description provided for @authGoogleIdTokenMissing.
  ///
  /// In en, this message translates to:
  /// **'Google did not return an ID token.'**
  String get authGoogleIdTokenMissing;

  /// No description provided for @authSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get authSignOut;

  /// No description provided for @authEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get authEmailLabel;

  /// No description provided for @authPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get authPasswordLabel;

  /// No description provided for @authDisplayNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Display name'**
  String get authDisplayNameLabel;

  /// No description provided for @authSignInEmail.
  ///
  /// In en, this message translates to:
  /// **'Sign in with email'**
  String get authSignInEmail;

  /// No description provided for @authSignInEmailTitle.
  ///
  /// In en, this message translates to:
  /// **'Email sign-in'**
  String get authSignInEmailTitle;

  /// No description provided for @authSignInEmailSubmit.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get authSignInEmailSubmit;

  /// No description provided for @authRegisterAction.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get authRegisterAction;

  /// No description provided for @authRegisterTitle.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get authRegisterTitle;

  /// No description provided for @authHaveAccountSignIn.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Sign in'**
  String get authHaveAccountSignIn;

  /// No description provided for @authNoAccountRegister.
  ///
  /// In en, this message translates to:
  /// **'No account? Register'**
  String get authNoAccountRegister;

  /// No description provided for @authOrDivider.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get authOrDivider;

  /// No description provided for @authRegistering.
  ///
  /// In en, this message translates to:
  /// **'Registering…'**
  String get authRegistering;

  /// No description provided for @authInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Check the email format.'**
  String get authInvalidEmail;

  /// No description provided for @authWeakPassword.
  ///
  /// In en, this message translates to:
  /// **'Password is too short (minimum 6 characters).'**
  String get authWeakPassword;

  /// No description provided for @authEmailAlreadyInUse.
  ///
  /// In en, this message translates to:
  /// **'This email is already registered.'**
  String get authEmailAlreadyInUse;

  /// No description provided for @authInvalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Incorrect email or password.'**
  String get authInvalidCredentials;

  /// No description provided for @authTooManyRequests.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Please wait and try again.'**
  String get authTooManyRequests;

  /// No description provided for @authFieldRequired.
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get authFieldRequired;

  /// No description provided for @authEmailVerificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm your email'**
  String get authEmailVerificationTitle;

  /// No description provided for @authEmailVerificationBody.
  ///
  /// In en, this message translates to:
  /// **'We sent a message to {email}. Open the link in the email, then tap “I’ve confirmed”.'**
  String authEmailVerificationBody(String email);

  /// No description provided for @authEmailVerificationCheck.
  ///
  /// In en, this message translates to:
  /// **'I’ve confirmed'**
  String get authEmailVerificationCheck;

  /// No description provided for @authEmailVerificationResend.
  ///
  /// In en, this message translates to:
  /// **'Resend email'**
  String get authEmailVerificationResend;

  /// No description provided for @authEmailVerificationResent.
  ///
  /// In en, this message translates to:
  /// **'Verification email sent again'**
  String get authEmailVerificationResent;

  /// No description provided for @authEmailVerificationPending.
  ///
  /// In en, this message translates to:
  /// **'Email is not confirmed yet. Check your inbox and try again.'**
  String get authEmailVerificationPending;

  /// No description provided for @authEmailVerificationChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking…'**
  String get authEmailVerificationChecking;

  /// No description provided for @profileDeleteAccountPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get profileDeleteAccountPasswordTitle;

  /// No description provided for @profileDeleteAccountPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Account password'**
  String get profileDeleteAccountPasswordHint;

  /// No description provided for @authConsentLabel.
  ///
  /// In en, this message translates to:
  /// **'I agree to the processing of personal data'**
  String get authConsentLabel;

  /// No description provided for @authConsentRequired.
  ///
  /// In en, this message translates to:
  /// **'Accept personal data processing to continue'**
  String get authConsentRequired;

  /// No description provided for @privacyPolicyLink.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicyLink;

  /// No description provided for @authConsentGateTitle.
  ///
  /// In en, this message translates to:
  /// **'Personal data consent'**
  String get authConsentGateTitle;

  /// No description provided for @authConsentGateBody.
  ///
  /// In en, this message translates to:
  /// **'To continue using the app, please accept the Privacy Policy.'**
  String get authConsentGateBody;

  /// No description provided for @authConsentContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get authConsentContinue;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @profileEmDash.
  ///
  /// In en, this message translates to:
  /// **'—'**
  String get profileEmDash;

  /// No description provided for @profilePlantCount.
  ///
  /// In en, this message translates to:
  /// **'Plants'**
  String get profilePlantCount;

  /// No description provided for @profileFavoriteFamily.
  ///
  /// In en, this message translates to:
  /// **'Favorite family'**
  String get profileFavoriteFamily;

  /// No description provided for @profileFavoriteGenus.
  ///
  /// In en, this message translates to:
  /// **'Favorite genus'**
  String get profileFavoriteGenus;

  /// No description provided for @profileActivePropagations.
  ///
  /// In en, this message translates to:
  /// **'On propagation'**
  String get profileActivePropagations;

  /// No description provided for @profileConsentAccepted.
  ///
  /// In en, this message translates to:
  /// **'Personal data consent recorded'**
  String get profileConsentAccepted;

  /// No description provided for @profileDeleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete profile'**
  String get profileDeleteAccount;

  /// No description provided for @profileDeleteAccountConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete profile?'**
  String get profileDeleteAccountConfirmTitle;

  /// No description provided for @profileDeleteAccountConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'This permanently deletes your account, plants, photos, and all related data. This cannot be undone.'**
  String get profileDeleteAccountConfirmBody;

  /// No description provided for @profileDeleteAccountConfirmAction.
  ///
  /// In en, this message translates to:
  /// **'Delete forever'**
  String get profileDeleteAccountConfirmAction;

  /// No description provided for @profileDeletingAccount.
  ///
  /// In en, this message translates to:
  /// **'Deleting profile…'**
  String get profileDeletingAccount;

  /// No description provided for @profileDeleteAccountError.
  ///
  /// In en, this message translates to:
  /// **'Could not delete profile: {error}'**
  String profileDeleteAccountError(String error);

  /// No description provided for @profileDeleteAccountFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not delete profile. Please try again.'**
  String get profileDeleteAccountFailed;

  /// No description provided for @profileFriends.
  ///
  /// In en, this message translates to:
  /// **'Friends'**
  String get profileFriends;

  /// No description provided for @profileExportPlants.
  ///
  /// In en, this message translates to:
  /// **'Export plant names'**
  String get profileExportPlants;

  /// No description provided for @profileExportPlantsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No plants to export'**
  String get profileExportPlantsEmpty;

  /// No description provided for @profileExportingPlants.
  ///
  /// In en, this message translates to:
  /// **'Exporting plants…'**
  String get profileExportingPlants;

  /// No description provided for @profileMyUid.
  ///
  /// In en, this message translates to:
  /// **'Your ID'**
  String get profileMyUid;

  /// No description provided for @profileCopyUid.
  ///
  /// In en, this message translates to:
  /// **'Copy ID'**
  String get profileCopyUid;

  /// No description provided for @profileUidCopied.
  ///
  /// In en, this message translates to:
  /// **'ID copied'**
  String get profileUidCopied;

  /// No description provided for @profileCollectionVisibility.
  ///
  /// In en, this message translates to:
  /// **'Collection visibility'**
  String get profileCollectionVisibility;

  /// No description provided for @profileCollectionFriends.
  ///
  /// In en, this message translates to:
  /// **'Friends can view'**
  String get profileCollectionFriends;

  /// No description provided for @profileCollectionPrivate.
  ///
  /// In en, this message translates to:
  /// **'Private'**
  String get profileCollectionPrivate;

  /// No description provided for @friendsTitle.
  ///
  /// In en, this message translates to:
  /// **'Friends'**
  String get friendsTitle;

  /// No description provided for @friendsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No friends yet'**
  String get friendsEmpty;

  /// No description provided for @friendsUnknownName.
  ///
  /// In en, this message translates to:
  /// **'Friend'**
  String get friendsUnknownName;

  /// No description provided for @friendsAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add friend'**
  String get friendsAddTitle;

  /// No description provided for @friendsAddHint.
  ///
  /// In en, this message translates to:
  /// **'Friend user ID'**
  String get friendsAddHint;

  /// No description provided for @friendsAddAction.
  ///
  /// In en, this message translates to:
  /// **'Send request'**
  String get friendsAddAction;

  /// No description provided for @friendsIncoming.
  ///
  /// In en, this message translates to:
  /// **'Incoming requests'**
  String get friendsIncoming;

  /// No description provided for @friendsOutgoing.
  ///
  /// In en, this message translates to:
  /// **'Outgoing requests'**
  String get friendsOutgoing;

  /// No description provided for @friendsAccept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get friendsAccept;

  /// No description provided for @friendsDecline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get friendsDecline;

  /// No description provided for @friendsCancelRequest.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get friendsCancelRequest;

  /// No description provided for @friendsRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove friend'**
  String get friendsRemove;

  /// No description provided for @friendsRemoveConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove {name} from friends?'**
  String friendsRemoveConfirm(String name);

  /// No description provided for @friendsRequestSent.
  ///
  /// In en, this message translates to:
  /// **'Friend request sent'**
  String get friendsRequestSent;

  /// No description provided for @friendsOpenCollection.
  ///
  /// In en, this message translates to:
  /// **'Collection'**
  String get friendsOpenCollection;

  /// No description provided for @friendsOpenWishList.
  ///
  /// In en, this message translates to:
  /// **'WishLeafs'**
  String get friendsOpenWishList;

  /// No description provided for @friendsGiftsInbox.
  ///
  /// In en, this message translates to:
  /// **'Plant gifts'**
  String get friendsGiftsInbox;

  /// No description provided for @friendsGiftFrom.
  ///
  /// In en, this message translates to:
  /// **'From {name}'**
  String friendsGiftFrom(String name);

  /// No description provided for @friendsGiftAccept.
  ///
  /// In en, this message translates to:
  /// **'Accept gift'**
  String get friendsGiftAccept;

  /// No description provided for @friendsGiftDecline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get friendsGiftDecline;

  /// No description provided for @friendsGiftAccepted.
  ///
  /// In en, this message translates to:
  /// **'Plant added to your collection'**
  String get friendsGiftAccepted;

  /// No description provided for @friendsGiftEmpty.
  ///
  /// In en, this message translates to:
  /// **'No pending gifts'**
  String get friendsGiftEmpty;

  /// No description provided for @friendsCollectionTitle.
  ///
  /// In en, this message translates to:
  /// **'{name}'**
  String friendsCollectionTitle(String name);

  /// No description provided for @friendsCollectionEmpty.
  ///
  /// In en, this message translates to:
  /// **'No plants to show'**
  String get friendsCollectionEmpty;

  /// No description provided for @friendsCollectionPrivate.
  ///
  /// In en, this message translates to:
  /// **'This collection is private'**
  String get friendsCollectionPrivate;

  /// No description provided for @friendsWishListTitle.
  ///
  /// In en, this message translates to:
  /// **'WishLeafs — {name}'**
  String friendsWishListTitle(String name);

  /// No description provided for @friendsWishListEmpty.
  ///
  /// In en, this message translates to:
  /// **'Wish list is empty'**
  String get friendsWishListEmpty;

  /// No description provided for @friendsWishListPrivate.
  ///
  /// In en, this message translates to:
  /// **'This wish list is private'**
  String get friendsWishListPrivate;

  /// No description provided for @friendsWishListLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load the wish list'**
  String get friendsWishListLoadError;

  /// No description provided for @friendsReadOnly.
  ///
  /// In en, this message translates to:
  /// **'View only'**
  String get friendsReadOnly;

  /// No description provided for @plantGift.
  ///
  /// In en, this message translates to:
  /// **'Gift plant'**
  String get plantGift;

  /// No description provided for @plantGiftTitle.
  ///
  /// In en, this message translates to:
  /// **'Gift to a friend'**
  String get plantGiftTitle;

  /// No description provided for @plantGiftPickFriend.
  ///
  /// In en, this message translates to:
  /// **'Choose a friend'**
  String get plantGiftPickFriend;

  /// No description provided for @plantGiftNoFriends.
  ///
  /// In en, this message translates to:
  /// **'Add friends first'**
  String get plantGiftNoFriends;

  /// No description provided for @plantGiftConfirm.
  ///
  /// In en, this message translates to:
  /// **'Send gift'**
  String get plantGiftConfirm;

  /// No description provided for @plantGiftSent.
  ///
  /// In en, this message translates to:
  /// **'Gift sent — plant leaves your collection after they accept'**
  String get plantGiftSent;

  /// No description provided for @plantGiftMessageHint.
  ///
  /// In en, this message translates to:
  /// **'Message (optional)'**
  String get plantGiftMessageHint;

  /// No description provided for @plantArchiveReasonGifted.
  ///
  /// In en, this message translates to:
  /// **'Gifted'**
  String get plantArchiveReasonGifted;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsLanguageSystem.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get settingsLanguageSystem;

  /// No description provided for @settingsLanguageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get settingsLanguageEnglish;

  /// No description provided for @settingsLanguageRussian.
  ///
  /// In en, this message translates to:
  /// **'Russian'**
  String get settingsLanguageRussian;

  /// No description provided for @settingsLanguageGerman.
  ///
  /// In en, this message translates to:
  /// **'German'**
  String get settingsLanguageGerman;

  /// No description provided for @settingsLanguageFrench.
  ///
  /// In en, this message translates to:
  /// **'French'**
  String get settingsLanguageFrench;

  /// No description provided for @settingsCurrency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get settingsCurrency;

  /// No description provided for @settingsCurrencyUsd.
  ///
  /// In en, this message translates to:
  /// **'US dollar'**
  String get settingsCurrencyUsd;

  /// No description provided for @settingsCurrencyEur.
  ///
  /// In en, this message translates to:
  /// **'Euro'**
  String get settingsCurrencyEur;

  /// No description provided for @settingsCurrencyRub.
  ///
  /// In en, this message translates to:
  /// **'Russian ruble'**
  String get settingsCurrencyRub;

  /// No description provided for @settingsCurrencyByn.
  ///
  /// In en, this message translates to:
  /// **'Belarusian ruble'**
  String get settingsCurrencyByn;

  /// No description provided for @homeSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search plants…'**
  String get homeSearchHint;

  /// No description provided for @homeNoUserData.
  ///
  /// In en, this message translates to:
  /// **'No user data'**
  String get homeNoUserData;

  /// No description provided for @homeNoPlantsYet.
  ///
  /// In en, this message translates to:
  /// **'No plants added yet'**
  String get homeNoPlantsYet;

  /// No description provided for @homeNoPropagatingPlants.
  ///
  /// In en, this message translates to:
  /// **'No plants with active propagation'**
  String get homeNoPropagatingPlants;

  /// No description provided for @homeNoGroupPlants.
  ///
  /// In en, this message translates to:
  /// **'No plant groups yet'**
  String get homeNoGroupPlants;

  /// No description provided for @homeNoPlantsForFilter.
  ///
  /// In en, this message translates to:
  /// **'No plants match the selected filter'**
  String get homeNoPlantsForFilter;

  /// No description provided for @homeAllFamilies.
  ///
  /// In en, this message translates to:
  /// **'All families'**
  String get homeAllFamilies;

  /// No description provided for @homeAllGenera.
  ///
  /// In en, this message translates to:
  /// **'All genera'**
  String get homeAllGenera;

  /// No description provided for @homeAllStages.
  ///
  /// In en, this message translates to:
  /// **'All stages'**
  String get homeAllStages;

  /// No description provided for @homeNoFamily.
  ///
  /// In en, this message translates to:
  /// **'No family'**
  String get homeNoFamily;

  /// No description provided for @homePropagation.
  ///
  /// In en, this message translates to:
  /// **'Propagation'**
  String get homePropagation;

  /// No description provided for @homeGroups.
  ///
  /// In en, this message translates to:
  /// **'Groups'**
  String get homeGroups;

  /// No description provided for @homeArchive.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get homeArchive;

  /// No description provided for @homeMerge.
  ///
  /// In en, this message translates to:
  /// **'Merge'**
  String get homeMerge;

  /// No description provided for @homeMergeNeedCount.
  ///
  /// In en, this message translates to:
  /// **'Select 2 to 3 plants'**
  String get homeMergeNeedCount;

  /// No description provided for @homeMergeNeedSameGenus.
  ///
  /// In en, this message translates to:
  /// **'Plants must share the same genus to merge'**
  String get homeMergeNeedSameGenus;

  /// No description provided for @homeWishList.
  ///
  /// In en, this message translates to:
  /// **'WishLeafs'**
  String get homeWishList;

  /// No description provided for @homeFinances.
  ///
  /// In en, this message translates to:
  /// **'Finances'**
  String get homeFinances;

  /// No description provided for @homeSort.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get homeSort;

  /// No description provided for @homeSortSpecies.
  ///
  /// In en, this message translates to:
  /// **'Species'**
  String get homeSortSpecies;

  /// No description provided for @homeSortNickname.
  ///
  /// In en, this message translates to:
  /// **'Nickname'**
  String get homeSortNickname;

  /// No description provided for @homeSortWatering.
  ///
  /// In en, this message translates to:
  /// **'Watering'**
  String get homeSortWatering;

  /// No description provided for @homeSortFertilizing.
  ///
  /// In en, this message translates to:
  /// **'Fertilizing'**
  String get homeSortFertilizing;

  /// No description provided for @homeSortDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get homeSortDate;

  /// No description provided for @homeSortFamily.
  ///
  /// In en, this message translates to:
  /// **'Family'**
  String get homeSortFamily;

  /// No description provided for @homeSortLastWatered.
  ///
  /// In en, this message translates to:
  /// **'Last watered'**
  String get homeSortLastWatered;

  /// No description provided for @homeSortLastFertilized.
  ///
  /// In en, this message translates to:
  /// **'Last fertilized'**
  String get homeSortLastFertilized;

  /// No description provided for @homeSortDateAdded.
  ///
  /// In en, this message translates to:
  /// **'Date added'**
  String get homeSortDateAdded;

  /// No description provided for @homeSelectedCount.
  ///
  /// In en, this message translates to:
  /// **'Selected: {count}'**
  String homeSelectedCount(int count);

  /// No description provided for @homeSelectAll.
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get homeSelectAll;

  /// No description provided for @homeClearSelection.
  ///
  /// In en, this message translates to:
  /// **'Clear selection'**
  String get homeClearSelection;

  /// No description provided for @homeWatering.
  ///
  /// In en, this message translates to:
  /// **'Watering'**
  String get homeWatering;

  /// No description provided for @homeFertilizing.
  ///
  /// In en, this message translates to:
  /// **'Fertilizing'**
  String get homeFertilizing;

  /// No description provided for @homeRepotting.
  ///
  /// In en, this message translates to:
  /// **'Repotting'**
  String get homeRepotting;

  /// No description provided for @homeNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get homeNotes;

  /// No description provided for @homeUpdateFamily.
  ///
  /// In en, this message translates to:
  /// **'Update family'**
  String get homeUpdateFamily;

  /// No description provided for @homeUpdateFamilyTitle.
  ///
  /// In en, this message translates to:
  /// **'Update family'**
  String get homeUpdateFamilyTitle;

  /// No description provided for @homeFamilyLabel.
  ///
  /// In en, this message translates to:
  /// **'Family'**
  String get homeFamilyLabel;

  /// No description provided for @homeFertilizeSelectedTitle.
  ///
  /// In en, this message translates to:
  /// **'Fertilize selected plants'**
  String get homeFertilizeSelectedTitle;

  /// No description provided for @homeRepotSelectedTitle.
  ///
  /// In en, this message translates to:
  /// **'Repot selected plants'**
  String get homeRepotSelectedTitle;

  /// No description provided for @homeNotesSelectedTitle.
  ///
  /// In en, this message translates to:
  /// **'Add a note to selected plants'**
  String get homeNotesSelectedTitle;

  /// No description provided for @homeDeleteSelectedTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete selected plants?'**
  String get homeDeleteSelectedTitle;

  /// No description provided for @homeDeleteSelectedBody.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete {count} plant(s).'**
  String homeDeleteSelectedBody(int count);

  /// No description provided for @homeDeleteSelectedBodyPlural.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{This will permanently delete 1 plant.} other{This will permanently delete {count} plants.}}'**
  String homeDeleteSelectedBodyPlural(int count);

  /// No description provided for @searchNoPlantsInJournal.
  ///
  /// In en, this message translates to:
  /// **'No plants in the journal'**
  String get searchNoPlantsInJournal;

  /// No description provided for @searchNothingFound.
  ///
  /// In en, this message translates to:
  /// **'Nothing found'**
  String get searchNothingFound;

  /// No description provided for @plantAdd.
  ///
  /// In en, this message translates to:
  /// **'Add plant'**
  String get plantAdd;

  /// No description provided for @plantEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit plant'**
  String get plantEdit;

  /// No description provided for @plantSaveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get plantSaveChanges;

  /// No description provided for @plantGenus.
  ///
  /// In en, this message translates to:
  /// **'Genus'**
  String get plantGenus;

  /// No description provided for @plantSpecies.
  ///
  /// In en, this message translates to:
  /// **'Species'**
  String get plantSpecies;

  /// No description provided for @plantCultivar.
  ///
  /// In en, this message translates to:
  /// **'Cultivar'**
  String get plantCultivar;

  /// No description provided for @plantTradingName.
  ///
  /// In en, this message translates to:
  /// **'Trading name'**
  String get plantTradingName;

  /// No description provided for @plantFamily.
  ///
  /// In en, this message translates to:
  /// **'Family'**
  String get plantFamily;

  /// No description provided for @plantNickname.
  ///
  /// In en, this message translates to:
  /// **'Nickname'**
  String get plantNickname;

  /// No description provided for @plantWateringFrequency.
  ///
  /// In en, this message translates to:
  /// **'Watering frequency'**
  String get plantWateringFrequency;

  /// No description provided for @plantGrowthStage.
  ///
  /// In en, this message translates to:
  /// **'Growth stage'**
  String get plantGrowthStage;

  /// No description provided for @plantGenusRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter the plant genus'**
  String get plantGenusRequired;

  /// No description provided for @plantSpeciesRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter the plant species'**
  String get plantSpeciesRequired;

  /// No description provided for @plantInvalidWateringFrequency.
  ///
  /// In en, this message translates to:
  /// **'Invalid watering frequency'**
  String get plantInvalidWateringFrequency;

  /// No description provided for @plantFertilizingFrequency.
  ///
  /// In en, this message translates to:
  /// **'Fertilizing frequency'**
  String get plantFertilizingFrequency;

  /// No description provided for @plantFertilizingFrequencyDays.
  ///
  /// In en, this message translates to:
  /// **'Interval (days)'**
  String get plantFertilizingFrequencyDays;

  /// No description provided for @plantFertilizingStop.
  ///
  /// In en, this message translates to:
  /// **'Do not fertilize (STOP)'**
  String get plantFertilizingStop;

  /// No description provided for @plantFertilizingResetAuto.
  ///
  /// In en, this message translates to:
  /// **'Reset to automatic'**
  String get plantFertilizingResetAuto;

  /// No description provided for @plantFertilizingFrequencyHint.
  ///
  /// In en, this message translates to:
  /// **'These are average intervals by stage and season. You can adjust them for a specific plant. Enter 0 to skip fertilizing.'**
  String get plantFertilizingFrequencyHint;

  /// No description provided for @plantInvalidFertilizingFrequency.
  ///
  /// In en, this message translates to:
  /// **'Enter 1–180 days or select STOP'**
  String get plantInvalidFertilizingFrequency;

  /// No description provided for @fertilizingStageGenitiveStart.
  ///
  /// In en, this message translates to:
  /// **'start'**
  String get fertilizingStageGenitiveStart;

  /// No description provided for @fertilizingStageGenitiveBaby.
  ///
  /// In en, this message translates to:
  /// **'baby plant'**
  String get fertilizingStageGenitiveBaby;

  /// No description provided for @fertilizingStageGenitiveJuvenile.
  ///
  /// In en, this message translates to:
  /// **'juvenile'**
  String get fertilizingStageGenitiveJuvenile;

  /// No description provided for @fertilizingStageGenitiveAdult.
  ///
  /// In en, this message translates to:
  /// **'adult'**
  String get fertilizingStageGenitiveAdult;

  /// No description provided for @fertilizingReminderEveTitle.
  ///
  /// In en, this message translates to:
  /// **'Fertilizing reminder'**
  String get fertilizingReminderEveTitle;

  /// No description provided for @fertilizingReminderEveBody.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow: fertilize {stage}'**
  String fertilizingReminderEveBody(String stage);

  /// No description provided for @fertilizingReminderDayTitle.
  ///
  /// In en, this message translates to:
  /// **'Fertilize {name}'**
  String fertilizingReminderDayTitle(String name);

  /// No description provided for @fertilizingReminderDayTitleStage.
  ///
  /// In en, this message translates to:
  /// **'Fertilize {stage}'**
  String fertilizingReminderDayTitleStage(String stage);

  /// No description provided for @fertilizingReminderDayBody.
  ///
  /// In en, this message translates to:
  /// **'Time to fertilize. Tap Accept when done.'**
  String get fertilizingReminderDayBody;

  /// No description provided for @fertilizingReminderAccept.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get fertilizingReminderAccept;

  /// No description provided for @settingsFertilizingSeason.
  ///
  /// In en, this message translates to:
  /// **'Fertilizing season'**
  String get settingsFertilizingSeason;

  /// No description provided for @settingsSeasonNorthern.
  ///
  /// In en, this message translates to:
  /// **'Northern hemisphere (Apr–Sep active)'**
  String get settingsSeasonNorthern;

  /// No description provided for @settingsSeasonSouthern.
  ///
  /// In en, this message translates to:
  /// **'Southern hemisphere (Oct–Mar active)'**
  String get settingsSeasonSouthern;

  /// No description provided for @settingsSeasonCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom months'**
  String get settingsSeasonCustom;

  /// No description provided for @settingsSeasonSpringStart.
  ///
  /// In en, this message translates to:
  /// **'Active season starts (month)'**
  String get settingsSeasonSpringStart;

  /// No description provided for @settingsSeasonSpringEnd.
  ///
  /// In en, this message translates to:
  /// **'Active season ends (month)'**
  String get settingsSeasonSpringEnd;

  /// No description provided for @settingsNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get settingsNotifications;

  /// No description provided for @settingsNotificationsEnable.
  ///
  /// In en, this message translates to:
  /// **'Allow fertilizing reminders'**
  String get settingsNotificationsEnable;

  /// No description provided for @plantUntitled.
  ///
  /// In en, this message translates to:
  /// **'Untitled'**
  String get plantUntitled;

  /// No description provided for @plantDefaultTitle.
  ///
  /// In en, this message translates to:
  /// **'Plant'**
  String get plantDefaultTitle;

  /// No description provided for @plantGenusFallback.
  ///
  /// In en, this message translates to:
  /// **'Genus'**
  String get plantGenusFallback;

  /// No description provided for @plantSpeciesLabel.
  ///
  /// In en, this message translates to:
  /// **'Species: {species}'**
  String plantSpeciesLabel(String species);

  /// No description provided for @plantCultivarLabel.
  ///
  /// In en, this message translates to:
  /// **'Cultivar: {cultivar}'**
  String plantCultivarLabel(String cultivar);

  /// No description provided for @plantStageLabel.
  ///
  /// In en, this message translates to:
  /// **'Stage: {stage}'**
  String plantStageLabel(String stage);

  /// No description provided for @plantFamilyLabel.
  ///
  /// In en, this message translates to:
  /// **'Family'**
  String get plantFamilyLabel;

  /// No description provided for @plantTradingNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Trading name'**
  String get plantTradingNameLabel;

  /// No description provided for @plantGenusPrefix.
  ///
  /// In en, this message translates to:
  /// **'Genus: '**
  String get plantGenusPrefix;

  /// No description provided for @plantVariegationLabel.
  ///
  /// In en, this message translates to:
  /// **'Variegation: {value}'**
  String plantVariegationLabel(String value);

  /// No description provided for @plantBotanicalData.
  ///
  /// In en, this message translates to:
  /// **'Botanical data'**
  String get plantBotanicalData;

  /// No description provided for @plantDateAddedLabel.
  ///
  /// In en, this message translates to:
  /// **'Date added'**
  String get plantDateAddedLabel;

  /// No description provided for @plantJournal.
  ///
  /// In en, this message translates to:
  /// **'Journal'**
  String get plantJournal;

  /// No description provided for @plantGallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get plantGallery;

  /// No description provided for @plantCamera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get plantCamera;

  /// No description provided for @plantUploadError.
  ///
  /// In en, this message translates to:
  /// **'Upload error: {error}'**
  String plantUploadError(String error);

  /// No description provided for @plantPhotoDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete photo'**
  String get plantPhotoDeleteTitle;

  /// No description provided for @plantPhotoDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this plant photo?'**
  String get plantPhotoDeleteConfirm;

  /// No description provided for @plantCropTitle.
  ///
  /// In en, this message translates to:
  /// **'Crop photo'**
  String get plantCropTitle;

  /// No description provided for @plantCropConfirm.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get plantCropConfirm;

  /// No description provided for @plantCropError.
  ///
  /// In en, this message translates to:
  /// **'Crop error: {error}'**
  String plantCropError(String error);

  /// No description provided for @plantEmptyStage.
  ///
  /// In en, this message translates to:
  /// **'No plants of this stage in the collection yet'**
  String get plantEmptyStage;

  /// No description provided for @plantEmptyGenus.
  ///
  /// In en, this message translates to:
  /// **'No plants of this genus in the collection yet'**
  String get plantEmptyGenus;

  /// No description provided for @plantNote.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get plantNote;

  /// No description provided for @plantPropagation.
  ///
  /// In en, this message translates to:
  /// **'Propagation'**
  String get plantPropagation;

  /// No description provided for @plantInitialLeafCount.
  ///
  /// In en, this message translates to:
  /// **'Initial leaf count'**
  String get plantInitialLeafCount;

  /// No description provided for @plantInvalidInitialLeafCount.
  ///
  /// In en, this message translates to:
  /// **'Invalid initial leaf count'**
  String get plantInvalidInitialLeafCount;

  /// No description provided for @plantLeafAdd.
  ///
  /// In en, this message translates to:
  /// **'Add leaf'**
  String get plantLeafAdd;

  /// No description provided for @plantLeafRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove leaf'**
  String get plantLeafRemove;

  /// No description provided for @plantLeafRemoveTitle.
  ///
  /// In en, this message translates to:
  /// **'What happened to the leaf?'**
  String get plantLeafRemoveTitle;

  /// No description provided for @plantLeafRemoveCut.
  ///
  /// In en, this message translates to:
  /// **'Cut (for rooting)'**
  String get plantLeafRemoveCut;

  /// No description provided for @plantLeafRemoveEaten.
  ///
  /// In en, this message translates to:
  /// **'Eaten'**
  String get plantLeafRemoveEaten;

  /// No description provided for @plantLeafRemoveDried.
  ///
  /// In en, this message translates to:
  /// **'Dried out'**
  String get plantLeafRemoveDried;

  /// No description provided for @plantLeafStatsAnchor.
  ///
  /// In en, this message translates to:
  /// **'Leaf statistics'**
  String get plantLeafStatsAnchor;

  /// No description provided for @plantLeafStatsTitle.
  ///
  /// In en, this message translates to:
  /// **'Leaf growth'**
  String get plantLeafStatsTitle;

  /// No description provided for @plantLeafStatsGained.
  ///
  /// In en, this message translates to:
  /// **'Gained'**
  String get plantLeafStatsGained;

  /// No description provided for @plantLeafStatsLost.
  ///
  /// In en, this message translates to:
  /// **'Lost'**
  String get plantLeafStatsLost;

  /// No description provided for @plantLeafStatsMonthLine.
  ///
  /// In en, this message translates to:
  /// **'{month}: gained {gained}, lost {lost}'**
  String plantLeafStatsMonthLine(String month, int gained, int lost);

  /// No description provided for @stageUnknown.
  ///
  /// In en, this message translates to:
  /// **'🌱 Unknown'**
  String get stageUnknown;

  /// No description provided for @stageStart.
  ///
  /// In en, this message translates to:
  /// **'🌱 Start'**
  String get stageStart;

  /// No description provided for @stageBaby.
  ///
  /// In en, this message translates to:
  /// **'🌿 Baby'**
  String get stageBaby;

  /// No description provided for @stageJuvenile.
  ///
  /// In en, this message translates to:
  /// **'🌳 Juvenile'**
  String get stageJuvenile;

  /// No description provided for @stageAdult.
  ///
  /// In en, this message translates to:
  /// **'🌴 Adult'**
  String get stageAdult;

  /// No description provided for @stageDescriptionTitle.
  ///
  /// In en, this message translates to:
  /// **'Stage description'**
  String get stageDescriptionTitle;

  /// No description provided for @stageStartCheck1.
  ///
  /// In en, this message translates to:
  /// **'Tuber without roots'**
  String get stageStartCheck1;

  /// No description provided for @stageStartCheck2.
  ///
  /// In en, this message translates to:
  /// **'Leaf with a small rhizome'**
  String get stageStartCheck2;

  /// No description provided for @stageStartCheck3.
  ///
  /// In en, this message translates to:
  /// **'Rootable cutting'**
  String get stageStartCheck3;

  /// No description provided for @stageStartCheck4.
  ///
  /// In en, this message translates to:
  /// **'Plant is just starting to grow'**
  String get stageStartCheck4;

  /// No description provided for @stageBabyCheck1.
  ///
  /// In en, this message translates to:
  /// **'1–2 true leaves'**
  String get stageBabyCheck1;

  /// No description provided for @stageBabyCheck2.
  ///
  /// In en, this message translates to:
  /// **'Root system still forming'**
  String get stageBabyCheck2;

  /// No description provided for @stageBabyCheck3.
  ///
  /// In en, this message translates to:
  /// **'Independent growth'**
  String get stageBabyCheck3;

  /// No description provided for @stageJuvenileCheck1.
  ///
  /// In en, this message translates to:
  /// **'3–5 leaves'**
  String get stageJuvenileCheck1;

  /// No description provided for @stageJuvenileCheck2.
  ///
  /// In en, this message translates to:
  /// **'Good root system'**
  String get stageJuvenileCheck2;

  /// No description provided for @stageJuvenileCheck3.
  ///
  /// In en, this message translates to:
  /// **'Active growth'**
  String get stageJuvenileCheck3;

  /// No description provided for @stageAdultCheck1.
  ///
  /// In en, this message translates to:
  /// **'Fully formed plant'**
  String get stageAdultCheck1;

  /// No description provided for @stageAdultCheck2.
  ///
  /// In en, this message translates to:
  /// **'Regularly produces new leaves'**
  String get stageAdultCheck2;

  /// No description provided for @stageAdultCheck3.
  ///
  /// In en, this message translates to:
  /// **'Can be divided or cuttings taken'**
  String get stageAdultCheck3;

  /// No description provided for @variegationLabel.
  ///
  /// In en, this message translates to:
  /// **'Variegation'**
  String get variegationLabel;

  /// No description provided for @variegationNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get variegationNone;

  /// No description provided for @variegationAurea.
  ///
  /// In en, this message translates to:
  /// **'Aurea'**
  String get variegationAurea;

  /// No description provided for @variegationAlba.
  ///
  /// In en, this message translates to:
  /// **'Alba'**
  String get variegationAlba;

  /// No description provided for @variegationPink.
  ///
  /// In en, this message translates to:
  /// **'Pink'**
  String get variegationPink;

  /// No description provided for @variegationSplash.
  ///
  /// In en, this message translates to:
  /// **'Splash'**
  String get variegationSplash;

  /// No description provided for @variegationMint.
  ///
  /// In en, this message translates to:
  /// **'Mint'**
  String get variegationMint;

  /// No description provided for @variegationMulticolor.
  ///
  /// In en, this message translates to:
  /// **'Multicolor'**
  String get variegationMulticolor;

  /// No description provided for @variegationTricolor.
  ///
  /// In en, this message translates to:
  /// **'Tricolor'**
  String get variegationTricolor;

  /// No description provided for @variegationUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get variegationUnknown;

  /// No description provided for @watering.
  ///
  /// In en, this message translates to:
  /// **'Watering'**
  String get watering;

  /// No description provided for @wateringHistory.
  ///
  /// In en, this message translates to:
  /// **'Watering history'**
  String get wateringHistory;

  /// No description provided for @wateringAdd.
  ///
  /// In en, this message translates to:
  /// **'Add watering'**
  String get wateringAdd;

  /// No description provided for @wateringEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit watering'**
  String get wateringEdit;

  /// No description provided for @wateringDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete watering'**
  String get wateringDeleteTitle;

  /// No description provided for @wateringDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this entry?'**
  String get wateringDeleteConfirm;

  /// No description provided for @wateringEmpty.
  ///
  /// In en, this message translates to:
  /// **'No watering entries yet'**
  String get wateringEmpty;

  /// No description provided for @fertilizing.
  ///
  /// In en, this message translates to:
  /// **'Fertilizing'**
  String get fertilizing;

  /// No description provided for @fertilizingHistory.
  ///
  /// In en, this message translates to:
  /// **'Fertilizing history'**
  String get fertilizingHistory;

  /// No description provided for @fertilizingAdd.
  ///
  /// In en, this message translates to:
  /// **'Add fertilizing'**
  String get fertilizingAdd;

  /// No description provided for @fertilizingEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit fertilizing'**
  String get fertilizingEdit;

  /// No description provided for @fertilizingDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete fertilizing'**
  String get fertilizingDeleteTitle;

  /// No description provided for @fertilizingDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this entry?'**
  String get fertilizingDeleteConfirm;

  /// No description provided for @fertilizingEmpty.
  ///
  /// In en, this message translates to:
  /// **'No fertilizing entries yet'**
  String get fertilizingEmpty;

  /// No description provided for @fertilizingSelectedTitle.
  ///
  /// In en, this message translates to:
  /// **'Fertilize selected plants'**
  String get fertilizingSelectedTitle;

  /// No description provided for @fertilizingApplicationMethod.
  ///
  /// In en, this message translates to:
  /// **'Application method'**
  String get fertilizingApplicationMethod;

  /// No description provided for @fertilizingRoot.
  ///
  /// In en, this message translates to:
  /// **'Root'**
  String get fertilizingRoot;

  /// No description provided for @fertilizingFoliar.
  ///
  /// In en, this message translates to:
  /// **'Foliar'**
  String get fertilizingFoliar;

  /// No description provided for @fertilizingSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get fertilizingSaved;

  /// No description provided for @fertilizingNewMix.
  ///
  /// In en, this message translates to:
  /// **'New mix'**
  String get fertilizingNewMix;

  /// No description provided for @fertilizingCatalog.
  ///
  /// In en, this message translates to:
  /// **'Catalog'**
  String get fertilizingCatalog;

  /// No description provided for @fertilizingEmptyCatalog.
  ///
  /// In en, this message translates to:
  /// **'No fertilizers yet. Add a ready-made one or save a mix.'**
  String get fertilizingEmptyCatalog;

  /// No description provided for @fertilizingGoToNewMix.
  ///
  /// In en, this message translates to:
  /// **'Go to “New mix”'**
  String get fertilizingGoToNewMix;

  /// No description provided for @fertilizingSelectFertilizer.
  ///
  /// In en, this message translates to:
  /// **'Select a fertilizer'**
  String get fertilizingSelectFertilizer;

  /// No description provided for @fertilizingViewComposition.
  ///
  /// In en, this message translates to:
  /// **'View composition'**
  String get fertilizingViewComposition;

  /// No description provided for @fertilizingMixWaterVolume.
  ///
  /// In en, this message translates to:
  /// **'Mix water volume: {value} ml'**
  String fertilizingMixWaterVolume(int value);

  /// No description provided for @fertilizingIngredients.
  ///
  /// In en, this message translates to:
  /// **'Ingredients'**
  String get fertilizingIngredients;

  /// No description provided for @fertilizingTapIngredientHint.
  ///
  /// In en, this message translates to:
  /// **'Tap an ingredient to set the amount (g or ml)'**
  String get fertilizingTapIngredientHint;

  /// No description provided for @fertilizingSaveThisMix.
  ///
  /// In en, this message translates to:
  /// **'Save this mix'**
  String get fertilizingSaveThisMix;

  /// No description provided for @fertilizingMixName.
  ///
  /// In en, this message translates to:
  /// **'Mix name'**
  String get fertilizingMixName;

  /// No description provided for @fertilizingMixNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Growth formula'**
  String get fertilizingMixNameHint;

  /// No description provided for @fertilizingWaterVolume.
  ///
  /// In en, this message translates to:
  /// **'Water volume'**
  String get fertilizingWaterVolume;

  /// No description provided for @fertilizingAddIngredient.
  ///
  /// In en, this message translates to:
  /// **'Add ingredient'**
  String get fertilizingAddIngredient;

  /// No description provided for @fertilizingIngredientNameHint.
  ///
  /// In en, this message translates to:
  /// **'Ingredient name'**
  String get fertilizingIngredientNameHint;

  /// No description provided for @fertilizerFallbackName.
  ///
  /// In en, this message translates to:
  /// **'Fertilizer'**
  String get fertilizerFallbackName;

  /// No description provided for @fertilizerKindMix.
  ///
  /// In en, this message translates to:
  /// **'Mix'**
  String get fertilizerKindMix;

  /// No description provided for @fertilizerKindPurchased.
  ///
  /// In en, this message translates to:
  /// **'Ready-made'**
  String get fertilizerKindPurchased;

  /// No description provided for @fertilizerCustomMix.
  ///
  /// In en, this message translates to:
  /// **'Custom mix'**
  String get fertilizerCustomMix;

  /// No description provided for @fertilizerUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get fertilizerUnknown;

  /// No description provided for @fertilizerInvalidDose.
  ///
  /// In en, this message translates to:
  /// **'Invalid dose'**
  String get fertilizerInvalidDose;

  /// No description provided for @fertilizerNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get fertilizerNameLabel;

  /// No description provided for @fertilizerNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Pokon Universal'**
  String get fertilizerNameHint;

  /// No description provided for @fertilizerDoseLabelPurchased.
  ///
  /// In en, this message translates to:
  /// **'Dose'**
  String get fertilizerDoseLabelPurchased;

  /// No description provided for @fertilizerDoseLabelMix.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get fertilizerDoseLabelMix;

  /// No description provided for @fertilizerDoseHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 2'**
  String get fertilizerDoseHint;

  /// No description provided for @fertilizerMixComposition.
  ///
  /// In en, this message translates to:
  /// **'Mix composition: {components}'**
  String fertilizerMixComposition(String components);

  /// No description provided for @fertilizerWithMeta.
  ///
  /// In en, this message translates to:
  /// **'{name} · {kind} · {waterMl} ml'**
  String fertilizerWithMeta(String name, String kind, int waterMl);

  /// No description provided for @fertilizerWaterLine.
  ///
  /// In en, this message translates to:
  /// **'Water: {value} ml'**
  String fertilizerWaterLine(int value);

  /// No description provided for @manageFertilizersTitle.
  ///
  /// In en, this message translates to:
  /// **'Manage fertilizers'**
  String get manageFertilizersTitle;

  /// No description provided for @manageFertilizerIngredientsTitle.
  ///
  /// In en, this message translates to:
  /// **'Manage ingredients'**
  String get manageFertilizerIngredientsTitle;

  /// No description provided for @manageComponentsTitle.
  ///
  /// In en, this message translates to:
  /// **'Manage components'**
  String get manageComponentsTitle;

  /// No description provided for @componentNameHint.
  ///
  /// In en, this message translates to:
  /// **'Component name'**
  String get componentNameHint;

  /// No description provided for @emptyFertilizers.
  ///
  /// In en, this message translates to:
  /// **'No fertilizers yet'**
  String get emptyFertilizers;

  /// No description provided for @emptyIngredients.
  ///
  /// In en, this message translates to:
  /// **'No ingredients yet'**
  String get emptyIngredients;

  /// No description provided for @emptyComponents.
  ///
  /// In en, this message translates to:
  /// **'No components yet'**
  String get emptyComponents;

  /// No description provided for @emptyComposition.
  ///
  /// In en, this message translates to:
  /// **'Composition is empty'**
  String get emptyComposition;

  /// No description provided for @repotting.
  ///
  /// In en, this message translates to:
  /// **'Repotting'**
  String get repotting;

  /// No description provided for @repottingHistory.
  ///
  /// In en, this message translates to:
  /// **'Repotting history'**
  String get repottingHistory;

  /// No description provided for @repottingAdd.
  ///
  /// In en, this message translates to:
  /// **'Add repotting'**
  String get repottingAdd;

  /// No description provided for @repottingEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit repotting'**
  String get repottingEdit;

  /// No description provided for @repottingDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete repotting'**
  String get repottingDeleteTitle;

  /// No description provided for @repottingDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this entry?'**
  String get repottingDeleteConfirm;

  /// No description provided for @repottingEmpty.
  ///
  /// In en, this message translates to:
  /// **'No repotting entries yet'**
  String get repottingEmpty;

  /// No description provided for @repottingSlowRelease.
  ///
  /// In en, this message translates to:
  /// **'Slow-release fertilizer'**
  String get repottingSlowRelease;

  /// No description provided for @repottingSelectSoil.
  ///
  /// In en, this message translates to:
  /// **'Select soil'**
  String get repottingSelectSoil;

  /// No description provided for @repottingSoilFallback.
  ///
  /// In en, this message translates to:
  /// **'Soil'**
  String get repottingSoilFallback;

  /// No description provided for @repottingSoilComposition.
  ///
  /// In en, this message translates to:
  /// **'Soil composition'**
  String get repottingSoilComposition;

  /// No description provided for @soilCustomMix.
  ///
  /// In en, this message translates to:
  /// **'Custom mix'**
  String get soilCustomMix;

  /// No description provided for @soilParts.
  ///
  /// In en, this message translates to:
  /// **'{parts} parts'**
  String soilParts(String parts);

  /// No description provided for @manipulations.
  ///
  /// In en, this message translates to:
  /// **'Manipulations'**
  String get manipulations;

  /// No description provided for @manipulationsHistory.
  ///
  /// In en, this message translates to:
  /// **'Manipulation history'**
  String get manipulationsHistory;

  /// No description provided for @manipulationAdd.
  ///
  /// In en, this message translates to:
  /// **'Add manipulation'**
  String get manipulationAdd;

  /// No description provided for @manipulationEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit manipulation'**
  String get manipulationEdit;

  /// No description provided for @manipulationDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete manipulation'**
  String get manipulationDeleteTitle;

  /// No description provided for @manipulationDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this entry?'**
  String get manipulationDeleteConfirm;

  /// No description provided for @manipulationEmpty.
  ///
  /// In en, this message translates to:
  /// **'No manipulations yet'**
  String get manipulationEmpty;

  /// No description provided for @manipulationTypeField.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get manipulationTypeField;

  /// No description provided for @manipulationTypePinching.
  ///
  /// In en, this message translates to:
  /// **'Pinching'**
  String get manipulationTypePinching;

  /// No description provided for @manipulationTypeRerooting.
  ///
  /// In en, this message translates to:
  /// **'Reanimation'**
  String get manipulationTypeRerooting;

  /// No description provided for @manipulationTypeStimulator.
  ///
  /// In en, this message translates to:
  /// **'Stimulator'**
  String get manipulationTypeStimulator;

  /// No description provided for @manipulationNote.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get manipulationNote;

  /// No description provided for @manipulationNoteHint.
  ///
  /// In en, this message translates to:
  /// **'What you did and why'**
  String get manipulationNoteHint;

  /// No description provided for @manipulationRerootingStageOptional.
  ///
  /// In en, this message translates to:
  /// **'New stage (optional)'**
  String get manipulationRerootingStageOptional;

  /// No description provided for @manipulationRerootingStageBefore.
  ///
  /// In en, this message translates to:
  /// **'Was: {stage}'**
  String manipulationRerootingStageBefore(String stage);

  /// No description provided for @manipulationRerootingStageChange.
  ///
  /// In en, this message translates to:
  /// **'{before} → {after}'**
  String manipulationRerootingStageChange(String before, String after);

  /// No description provided for @manipulationStimulatorModeSaved.
  ///
  /// In en, this message translates to:
  /// **'From catalog'**
  String get manipulationStimulatorModeSaved;

  /// No description provided for @manipulationStimulatorModeCustom.
  ///
  /// In en, this message translates to:
  /// **'Manual'**
  String get manipulationStimulatorModeCustom;

  /// No description provided for @manipulationStimulatorSelect.
  ///
  /// In en, this message translates to:
  /// **'Select stimulator'**
  String get manipulationStimulatorSelect;

  /// No description provided for @manipulationStimulatorName.
  ///
  /// In en, this message translates to:
  /// **'Product name'**
  String get manipulationStimulatorName;

  /// No description provided for @manipulationStimulatorNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Rooting hormone'**
  String get manipulationStimulatorNameHint;

  /// No description provided for @manipulationStimulatorDosage.
  ///
  /// In en, this message translates to:
  /// **'Dosage'**
  String get manipulationStimulatorDosage;

  /// No description provided for @manipulationStimulatorDosageHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 1 ml / L'**
  String get manipulationStimulatorDosageHint;

  /// No description provided for @manipulationStimulatorNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter product name'**
  String get manipulationStimulatorNameRequired;

  /// No description provided for @manageStimulatorsTitle.
  ///
  /// In en, this message translates to:
  /// **'Stimulators'**
  String get manageStimulatorsTitle;

  /// No description provided for @stimulatorAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add stimulator'**
  String get stimulatorAddTitle;

  /// No description provided for @stimulatorEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit stimulator'**
  String get stimulatorEditTitle;

  /// No description provided for @stimulatorDefaultDosage.
  ///
  /// In en, this message translates to:
  /// **'Default dosage'**
  String get stimulatorDefaultDosage;

  /// No description provided for @emptyStimulators.
  ///
  /// In en, this message translates to:
  /// **'No stimulators yet'**
  String get emptyStimulators;

  /// No description provided for @notesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No notes yet'**
  String get notesEmpty;

  /// No description provided for @notesAdd.
  ///
  /// In en, this message translates to:
  /// **'Add note'**
  String get notesAdd;

  /// No description provided for @notesAddHint.
  ///
  /// In en, this message translates to:
  /// **'Add a new journal entry for this plant.'**
  String get notesAddHint;

  /// No description provided for @notesAddHintBulk.
  ///
  /// In en, this message translates to:
  /// **'The same journal entry will be added to every selected plant.'**
  String get notesAddHintBulk;

  /// No description provided for @notesEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit note'**
  String get notesEdit;

  /// No description provided for @notesLabel.
  ///
  /// In en, this message translates to:
  /// **'Journal entry'**
  String get notesLabel;

  /// No description provided for @notesEditLabel.
  ///
  /// In en, this message translates to:
  /// **'Edit note'**
  String get notesEditLabel;

  /// No description provided for @notesCannotBeEmpty.
  ///
  /// In en, this message translates to:
  /// **'Note cannot be empty'**
  String get notesCannotBeEmpty;

  /// No description provided for @notesDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete note'**
  String get notesDeleteTitle;

  /// No description provided for @notesDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this note?'**
  String get notesDeleteConfirm;

  /// No description provided for @notesOptional.
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get notesOptional;

  /// No description provided for @fieldRequired.
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get fieldRequired;

  /// No description provided for @propagationTitle.
  ///
  /// In en, this message translates to:
  /// **'Propagation'**
  String get propagationTitle;

  /// No description provided for @propagationActiveTab.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get propagationActiveTab;

  /// No description provided for @propagationArchiveTab.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get propagationArchiveTab;

  /// No description provided for @propagationEmptyActive.
  ///
  /// In en, this message translates to:
  /// **'No active propagations'**
  String get propagationEmptyActive;

  /// No description provided for @propagationEmptyArchive.
  ///
  /// In en, this message translates to:
  /// **'Archive is empty'**
  String get propagationEmptyArchive;

  /// No description provided for @propagationEmptyActiveHint.
  ///
  /// In en, this message translates to:
  /// **'Add a batch from a plant page'**
  String get propagationEmptyActiveHint;

  /// No description provided for @propagationEmptyArchiveHint.
  ///
  /// In en, this message translates to:
  /// **'Completed batches are kept for 1 year'**
  String get propagationEmptyArchiveHint;

  /// No description provided for @propagationAdd.
  ///
  /// In en, this message translates to:
  /// **'Add propagation'**
  String get propagationAdd;

  /// No description provided for @propagationChangeStage.
  ///
  /// In en, this message translates to:
  /// **'Change stage'**
  String get propagationChangeStage;

  /// No description provided for @propagationSell.
  ///
  /// In en, this message translates to:
  /// **'Sold'**
  String get propagationSell;

  /// No description provided for @propagationGift.
  ///
  /// In en, this message translates to:
  /// **'Gifted'**
  String get propagationGift;

  /// No description provided for @propagationTrade.
  ///
  /// In en, this message translates to:
  /// **'Traded'**
  String get propagationTrade;

  /// No description provided for @propagationLose.
  ///
  /// In en, this message translates to:
  /// **'Lost'**
  String get propagationLose;

  /// No description provided for @propagationInitialStage.
  ///
  /// In en, this message translates to:
  /// **'Initial stage'**
  String get propagationInitialStage;

  /// No description provided for @propagationParentLabel.
  ///
  /// In en, this message translates to:
  /// **'Parent: {name}'**
  String propagationParentLabel(String name);

  /// No description provided for @propagationDetails.
  ///
  /// In en, this message translates to:
  /// **'Propagation details'**
  String get propagationDetails;

  /// No description provided for @propagationQuantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get propagationQuantity;

  /// No description provided for @propagationQuantityMin.
  ///
  /// In en, this message translates to:
  /// **'Enter a quantity (minimum 1)'**
  String get propagationQuantityMin;

  /// No description provided for @propagationAliveNow.
  ///
  /// In en, this message translates to:
  /// **'Alive now'**
  String get propagationAliveNow;

  /// No description provided for @propagationAliveRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter the number alive'**
  String get propagationAliveRequired;

  /// No description provided for @propagationSellQuantityRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a quantity to sell'**
  String get propagationSellQuantityRequired;

  /// No description provided for @propagationGiftQuantityRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a quantity'**
  String get propagationGiftQuantityRequired;

  /// No description provided for @propagationTradeQuantityRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a quantity'**
  String get propagationTradeQuantityRequired;

  /// No description provided for @propagationLoseQuantityRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a quantity'**
  String get propagationLoseQuantityRequired;

  /// No description provided for @propagationQuantityExceedsAlive.
  ///
  /// In en, this message translates to:
  /// **'Cannot exceed alive count ({count})'**
  String propagationQuantityExceedsAlive(int count);

  /// No description provided for @propagationDate.
  ///
  /// In en, this message translates to:
  /// **'Date: {date}'**
  String propagationDate(String date);

  /// No description provided for @propagationSinceDate.
  ///
  /// In en, this message translates to:
  /// **'since {date}'**
  String propagationSinceDate(String date);

  /// No description provided for @propagationSoldCount.
  ///
  /// In en, this message translates to:
  /// **'sold {count}'**
  String propagationSoldCount(int count);

  /// No description provided for @propagationGiftedCount.
  ///
  /// In en, this message translates to:
  /// **'gifted {count}'**
  String propagationGiftedCount(int count);

  /// No description provided for @propagationTradedCount.
  ///
  /// In en, this message translates to:
  /// **'traded {count}'**
  String propagationTradedCount(int count);

  /// No description provided for @propagationLostCount.
  ///
  /// In en, this message translates to:
  /// **'lost {count}'**
  String propagationLostCount(int count);

  /// No description provided for @propagationSoldLabel.
  ///
  /// In en, this message translates to:
  /// **'Sold: {count} {unit}'**
  String propagationSoldLabel(int count, String unit);

  /// No description provided for @propagationGiftedLabel.
  ///
  /// In en, this message translates to:
  /// **'Gifted: {count} {unit}'**
  String propagationGiftedLabel(int count, String unit);

  /// No description provided for @propagationTradedLabel.
  ///
  /// In en, this message translates to:
  /// **'Traded: {count} {unit}'**
  String propagationTradedLabel(int count, String unit);

  /// No description provided for @propagationLostLabel.
  ///
  /// In en, this message translates to:
  /// **'Lost: {count} {unit}'**
  String propagationLostLabel(int count, String unit);

  /// No description provided for @propagationStartedLabel.
  ///
  /// In en, this message translates to:
  /// **'Started: {batches} batches · {quantity} pcs'**
  String propagationStartedLabel(int batches, int quantity);

  /// No description provided for @propagationStatsTitle.
  ///
  /// In en, this message translates to:
  /// **'Stats {year}'**
  String propagationStatsTitle(int year);

  /// No description provided for @propagationByMethods.
  ///
  /// In en, this message translates to:
  /// **'By methods: {methods}'**
  String propagationByMethods(String methods);

  /// No description provided for @propagationByFamilies.
  ///
  /// In en, this message translates to:
  /// **'By families: {families}'**
  String propagationByFamilies(String families);

  /// No description provided for @propagationQuantityPieces.
  ///
  /// In en, this message translates to:
  /// **'{count} pcs'**
  String propagationQuantityPieces(int count);

  /// No description provided for @propagationDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete propagation'**
  String get propagationDeleteTitle;

  /// No description provided for @propagationDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'The propagation batch and all stage history will be permanently deleted. Continue?'**
  String get propagationDeleteConfirm;

  /// No description provided for @propagationDeleteHistoryEntry.
  ///
  /// In en, this message translates to:
  /// **'Delete history entry?'**
  String get propagationDeleteHistoryEntry;

  /// No description provided for @propagationTimelineEmpty.
  ///
  /// In en, this message translates to:
  /// **'No stage history yet'**
  String get propagationTimelineEmpty;

  /// No description provided for @daysCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{today} =1{1 day} other{{count} days}}'**
  String daysCount(int count);

  /// No description provided for @propagationAliveWithMethod.
  ///
  /// In en, this message translates to:
  /// **'{count} {method}'**
  String propagationAliveWithMethod(int count, String method);

  /// No description provided for @propagationMethodLeaf.
  ///
  /// In en, this message translates to:
  /// **'Leaf'**
  String get propagationMethodLeaf;

  /// No description provided for @propagationMethodLeafPlural.
  ///
  /// In en, this message translates to:
  /// **'leaves'**
  String get propagationMethodLeafPlural;

  /// No description provided for @propagationMethodLeafFragment.
  ///
  /// In en, this message translates to:
  /// **'Leaf fragment'**
  String get propagationMethodLeafFragment;

  /// No description provided for @propagationMethodLeafFragmentPlural.
  ///
  /// In en, this message translates to:
  /// **'leaf fragments'**
  String get propagationMethodLeafFragmentPlural;

  /// No description provided for @propagationMethodRhizome.
  ///
  /// In en, this message translates to:
  /// **'Rhizome'**
  String get propagationMethodRhizome;

  /// No description provided for @propagationMethodRhizomePlural.
  ///
  /// In en, this message translates to:
  /// **'rhizomes'**
  String get propagationMethodRhizomePlural;

  /// No description provided for @propagationMethodTuber.
  ///
  /// In en, this message translates to:
  /// **'Tuber'**
  String get propagationMethodTuber;

  /// No description provided for @propagationMethodTuberPlural.
  ///
  /// In en, this message translates to:
  /// **'tubers'**
  String get propagationMethodTuberPlural;

  /// No description provided for @propagationMethodDivision.
  ///
  /// In en, this message translates to:
  /// **'Division'**
  String get propagationMethodDivision;

  /// No description provided for @propagationMethodDivisionPlural.
  ///
  /// In en, this message translates to:
  /// **'divisions'**
  String get propagationMethodDivisionPlural;

  /// No description provided for @propagationMethodOffset.
  ///
  /// In en, this message translates to:
  /// **'Offset'**
  String get propagationMethodOffset;

  /// No description provided for @propagationMethodOffsetPlural.
  ///
  /// In en, this message translates to:
  /// **'offsets'**
  String get propagationMethodOffsetPlural;

  /// No description provided for @propagationMethodCutting.
  ///
  /// In en, this message translates to:
  /// **'Cutting'**
  String get propagationMethodCutting;

  /// No description provided for @propagationMethodCuttingPlural.
  ///
  /// In en, this message translates to:
  /// **'cuttings'**
  String get propagationMethodCuttingPlural;

  /// No description provided for @propagationMethodMicrocloning.
  ///
  /// In en, this message translates to:
  /// **'Microcloning'**
  String get propagationMethodMicrocloning;

  /// No description provided for @propagationMethodMicrocloningPlural.
  ///
  /// In en, this message translates to:
  /// **'microclones'**
  String get propagationMethodMicrocloningPlural;

  /// No description provided for @propagationStatusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get propagationStatusActive;

  /// No description provided for @propagationStatusSold.
  ///
  /// In en, this message translates to:
  /// **'Sold'**
  String get propagationStatusSold;

  /// No description provided for @propagationStatusGifted.
  ///
  /// In en, this message translates to:
  /// **'Gifted'**
  String get propagationStatusGifted;

  /// No description provided for @propagationStatusTraded.
  ///
  /// In en, this message translates to:
  /// **'Traded'**
  String get propagationStatusTraded;

  /// No description provided for @propagationStatusLost.
  ///
  /// In en, this message translates to:
  /// **'Lost'**
  String get propagationStatusLost;

  /// No description provided for @propagationStartRooting.
  ///
  /// In en, this message translates to:
  /// **'Start rooting'**
  String get propagationStartRooting;

  /// No description provided for @propagationMethodField.
  ///
  /// In en, this message translates to:
  /// **'Method'**
  String get propagationMethodField;

  /// No description provided for @propagationQuantityExceedsOriginal.
  ///
  /// In en, this message translates to:
  /// **'Cannot exceed original quantity ({count})'**
  String propagationQuantityExceedsOriginal(int count);

  /// No description provided for @propagationAliveWithPlant.
  ///
  /// In en, this message translates to:
  /// **'{count} alive · {plantName}'**
  String propagationAliveWithPlant(int count, String plantName);

  /// No description provided for @propagationSellQuantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity to sell'**
  String get propagationSellQuantity;

  /// No description provided for @propagationGiftQuantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity to gift'**
  String get propagationGiftQuantity;

  /// No description provided for @propagationTradeQuantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity to trade'**
  String get propagationTradeQuantity;

  /// No description provided for @propagationLoseQuantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity lost'**
  String get propagationLoseQuantity;

  /// No description provided for @propagationWriteOff.
  ///
  /// In en, this message translates to:
  /// **'Write off'**
  String get propagationWriteOff;

  /// No description provided for @propagationConfirmGift.
  ///
  /// In en, this message translates to:
  /// **'Gift'**
  String get propagationConfirmGift;

  /// No description provided for @propagationConfirmTrade.
  ///
  /// In en, this message translates to:
  /// **'Trade'**
  String get propagationConfirmTrade;

  /// No description provided for @propagationTimeline.
  ///
  /// In en, this message translates to:
  /// **'Timeline'**
  String get propagationTimeline;

  /// No description provided for @propagationSoldCountLabel.
  ///
  /// In en, this message translates to:
  /// **'Sold: {count}'**
  String propagationSoldCountLabel(int count);

  /// No description provided for @propagationGiftedCountLabel.
  ///
  /// In en, this message translates to:
  /// **'Gifted: {count}'**
  String propagationGiftedCountLabel(int count);

  /// No description provided for @propagationTradedCountLabel.
  ///
  /// In en, this message translates to:
  /// **'Traded: {count}'**
  String propagationTradedCountLabel(int count);

  /// No description provided for @propagationLostCountLabel.
  ///
  /// In en, this message translates to:
  /// **'Lost: {count}'**
  String propagationLostCountLabel(int count);

  /// No description provided for @propagationOfTotal.
  ///
  /// In en, this message translates to:
  /// **'of {count}'**
  String propagationOfTotal(int count);

  /// No description provided for @propagationDeleteStartStageBody.
  ///
  /// In en, this message translates to:
  /// **'Deleting the \"{stageName}\" stage will permanently delete the entire propagation batch and all other stages. Continue?'**
  String propagationDeleteStartStageBody(String stageName);

  /// No description provided for @propagationDeleteStageEntryBody.
  ///
  /// In en, this message translates to:
  /// **'Only this stage entry will be deleted. Others will remain.'**
  String get propagationDeleteStageEntryBody;

  /// No description provided for @propagationDeleteLastEntryBody.
  ///
  /// In en, this message translates to:
  /// **'This is the last history entry. The propagation batch will be permanently deleted. Continue?'**
  String get propagationDeleteLastEntryBody;

  /// No description provided for @deleteEntryConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this entry?'**
  String get deleteEntryConfirm;

  /// No description provided for @promptEmptyNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'Value cannot be empty'**
  String get promptEmptyNotAllowed;

  /// No description provided for @repottingEmptySoils.
  ///
  /// In en, this message translates to:
  /// **'No saved soils yet. Create a new mix.'**
  String get repottingEmptySoils;

  /// No description provided for @repottingSoilTapHint.
  ///
  /// In en, this message translates to:
  /// **'Tap: +1 part · Long press: ½ part (again to remove)'**
  String get repottingSoilTapHint;

  /// No description provided for @repottingSlowReleaseSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Added during repotting'**
  String get repottingSlowReleaseSubtitle;

  /// No description provided for @repottingMixNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Aroid mix'**
  String get repottingMixNameHint;

  /// No description provided for @fertilizerPurchasedAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Ready-made fertilizer'**
  String get fertilizerPurchasedAddTitle;

  /// No description provided for @fertilizerEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit fertilizer'**
  String get fertilizerEditTitle;

  /// No description provided for @fertilizerDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete fertilizer'**
  String get fertilizerDeleteTitle;

  /// No description provided for @ingredientEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit ingredient'**
  String get ingredientEditTitle;

  /// No description provided for @ingredientDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete ingredient'**
  String get ingredientDeleteTitle;

  /// No description provided for @componentEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit component'**
  String get componentEditTitle;

  /// No description provided for @componentDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete component'**
  String get componentDeleteTitle;

  /// No description provided for @componentAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add component'**
  String get componentAddTitle;

  /// No description provided for @catalogItemDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove \"{name}\" from the catalog?'**
  String catalogItemDeleteConfirm(String name);

  /// No description provided for @catalogItemAlreadyExists.
  ///
  /// In en, this message translates to:
  /// **'\"{name}\" is already in the catalog'**
  String catalogItemAlreadyExists(String name);

  /// No description provided for @manageFertilizersHint.
  ///
  /// In en, this message translates to:
  /// **'Mixes are saved from \"New mix\". Type can be changed: ready-made ↔ mix.'**
  String get manageFertilizersHint;

  /// No description provided for @fertilizerWaterForDilution.
  ///
  /// In en, this message translates to:
  /// **'Water for dilution'**
  String get fertilizerWaterForDilution;

  /// No description provided for @fertilizerDoseOnWaterOptional.
  ///
  /// In en, this message translates to:
  /// **'Dose per {waterMl} ml (optional)'**
  String fertilizerDoseOnWaterOptional(int waterMl);

  /// No description provided for @fertilizerDoseOptional.
  ///
  /// In en, this message translates to:
  /// **'Dose (optional)'**
  String get fertilizerDoseOptional;

  /// No description provided for @fertilizerKindSection.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get fertilizerKindSection;

  /// No description provided for @soilComponentsTitle.
  ///
  /// In en, this message translates to:
  /// **'Soil components'**
  String get soilComponentsTitle;

  /// No description provided for @noComponents.
  ///
  /// In en, this message translates to:
  /// **'No components'**
  String get noComponents;

  /// No description provided for @doseAmountRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter an amount'**
  String get doseAmountRequired;

  /// No description provided for @doseInvalidNumber.
  ///
  /// In en, this message translates to:
  /// **'Invalid number'**
  String get doseInvalidNumber;

  /// No description provided for @doseRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get doseRemove;

  /// No description provided for @wishListTitle.
  ///
  /// In en, this message translates to:
  /// **'WishLeafs'**
  String get wishListTitle;

  /// No description provided for @wishListAdd.
  ///
  /// In en, this message translates to:
  /// **'Add to wish list'**
  String get wishListAdd;

  /// No description provided for @wishListEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit plant'**
  String get wishListEdit;

  /// No description provided for @wishListEmpty.
  ///
  /// In en, this message translates to:
  /// **'Wish list is empty'**
  String get wishListEmpty;

  /// No description provided for @wishListEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Add plants you want to buy'**
  String get wishListEmptyHint;

  /// No description provided for @wishListNameEn.
  ///
  /// In en, this message translates to:
  /// **'Name (English)'**
  String get wishListNameEn;

  /// No description provided for @wishListNameAlt.
  ///
  /// In en, this message translates to:
  /// **'Alternative name'**
  String get wishListNameAlt;

  /// No description provided for @wishListNameEnRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter the English name'**
  String get wishListNameEnRequired;

  /// No description provided for @wishListNameAltRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter an alternative name'**
  String get wishListNameAltRequired;

  /// No description provided for @wishListBought.
  ///
  /// In en, this message translates to:
  /// **'Bought'**
  String get wishListBought;

  /// No description provided for @wishListExchanged.
  ///
  /// In en, this message translates to:
  /// **'Exchanged'**
  String get wishListExchanged;

  /// No description provided for @wishListAcquireTitle.
  ///
  /// In en, this message translates to:
  /// **'How did you get it?'**
  String get wishListAcquireTitle;

  /// No description provided for @wishListExchangeNoFinanceHint.
  ///
  /// In en, this message translates to:
  /// **'Exchange is not recorded in finances. Next you can add the plant to your collection.'**
  String get wishListExchangeNoFinanceHint;

  /// No description provided for @wishListSelectForTrade.
  ///
  /// In en, this message translates to:
  /// **'Plant from wish list'**
  String get wishListSelectForTrade;

  /// No description provided for @wishListSelectForTradeHint.
  ///
  /// In en, this message translates to:
  /// **'Choose the plant you received in exchange. No finance entry will be created.'**
  String get wishListSelectForTradeHint;

  /// No description provided for @wishListAcquireContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get wishListAcquireContinue;

  /// No description provided for @wishListExport.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get wishListExport;

  /// No description provided for @wishListExportEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing to export'**
  String get wishListExportEmpty;

  /// No description provided for @wishListDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove “{name}” from the wish list?'**
  String wishListDeleteConfirm(String name);

  /// No description provided for @financesTitle.
  ///
  /// In en, this message translates to:
  /// **'Finances'**
  String get financesTitle;

  /// No description provided for @financesAdd.
  ///
  /// In en, this message translates to:
  /// **'Add entry'**
  String get financesAdd;

  /// No description provided for @financesEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit entry'**
  String get financesEdit;

  /// No description provided for @financesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No finance entries yet'**
  String get financesEmpty;

  /// No description provided for @financesEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Track income from sales and plant expenses'**
  String get financesEmptyHint;

  /// No description provided for @financesIncome.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get financesIncome;

  /// No description provided for @financesExpense.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get financesExpense;

  /// No description provided for @financesBalance.
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get financesBalance;

  /// No description provided for @financesAnalyticsTitle.
  ///
  /// In en, this message translates to:
  /// **'Last 3 months'**
  String get financesAnalyticsTitle;

  /// No description provided for @financesNoIncome.
  ///
  /// In en, this message translates to:
  /// **'No income yet'**
  String get financesNoIncome;

  /// No description provided for @financesNoExpense.
  ///
  /// In en, this message translates to:
  /// **'No expenses yet'**
  String get financesNoExpense;

  /// No description provided for @financesTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get financesTitleLabel;

  /// No description provided for @financesTitleRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a title'**
  String get financesTitleRequired;

  /// No description provided for @financesAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount ({symbol})'**
  String financesAmountLabel(String symbol);

  /// No description provided for @financesAmountRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid amount'**
  String get financesAmountRequired;

  /// No description provided for @financesDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete “{title}”?'**
  String financesDeleteConfirm(String title);

  /// No description provided for @financesAlsoAddToCatalog.
  ///
  /// In en, this message translates to:
  /// **'Also add to catalog'**
  String get financesAlsoAddToCatalog;

  /// No description provided for @financesAsSoilComponent.
  ///
  /// In en, this message translates to:
  /// **'Soil component'**
  String get financesAsSoilComponent;

  /// No description provided for @financesAsFertilizer.
  ///
  /// In en, this message translates to:
  /// **'Fertilizer'**
  String get financesAsFertilizer;

  /// No description provided for @financesAsPurchasedFertilizer.
  ///
  /// In en, this message translates to:
  /// **'Ready-made fertilizer'**
  String get financesAsPurchasedFertilizer;

  /// No description provided for @financesAsReadyMadeSoil.
  ///
  /// In en, this message translates to:
  /// **'Ready-made soil mix'**
  String get financesAsReadyMadeSoil;

  /// No description provided for @financesReceiptsLabel.
  ///
  /// In en, this message translates to:
  /// **'Receipts'**
  String get financesReceiptsLabel;

  /// No description provided for @financesAddReceipt.
  ///
  /// In en, this message translates to:
  /// **'Add receipt'**
  String get financesAddReceipt;

  /// No description provided for @financesReceiptChip.
  ///
  /// In en, this message translates to:
  /// **'Receipt'**
  String get financesReceiptChip;

  /// No description provided for @financesReceiptPendingChip.
  ///
  /// In en, this message translates to:
  /// **'New receipt {index}'**
  String financesReceiptPendingChip(int index);

  /// No description provided for @financesViewReceipts.
  ///
  /// In en, this message translates to:
  /// **'View receipt'**
  String get financesViewReceipts;

  /// No description provided for @financesReceiptViewerTitle.
  ///
  /// In en, this message translates to:
  /// **'Receipt'**
  String get financesReceiptViewerTitle;

  /// No description provided for @financesReceiptViewerTitlePaged.
  ///
  /// In en, this message translates to:
  /// **'Receipt {current} of {total}'**
  String financesReceiptViewerTitlePaged(int current, int total);

  /// No description provided for @financesReceiptImageLabel.
  ///
  /// In en, this message translates to:
  /// **'Receipt {index}'**
  String financesReceiptImageLabel(int index);

  /// No description provided for @financesPropagationSaleTitle.
  ///
  /// In en, this message translates to:
  /// **'Sale: {plantName} ×{quantity}'**
  String financesPropagationSaleTitle(String plantName, int quantity);

  /// No description provided for @financesPlantSaleTitle.
  ///
  /// In en, this message translates to:
  /// **'Plant sale: {plantName}'**
  String financesPlantSaleTitle(String plantName);

  /// No description provided for @propagationTradeForWishList.
  ///
  /// In en, this message translates to:
  /// **'For a wish-list plant'**
  String get propagationTradeForWishList;

  /// No description provided for @commonContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get commonContinue;

  /// No description provided for @commonSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get commonSkip;

  /// No description provided for @plantMergeTitle.
  ///
  /// In en, this message translates to:
  /// **'Merge into a group'**
  String get plantMergeTitle;

  /// No description provided for @plantMergeMemberLabel.
  ///
  /// In en, this message translates to:
  /// **'Cultivar {index}'**
  String plantMergeMemberLabel(int index);

  /// No description provided for @plantMergeMembersRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter at least two cultivars'**
  String get plantMergeMembersRequired;

  /// No description provided for @plantGroupMembers.
  ///
  /// In en, this message translates to:
  /// **'Group cultivars'**
  String get plantGroupMembers;

  /// No description provided for @plantCultivarsLabel.
  ///
  /// In en, this message translates to:
  /// **'Cultivars: {cultivars}'**
  String plantCultivarsLabel(String cultivars);

  /// No description provided for @plantArchiveTitle.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get plantArchiveTitle;

  /// No description provided for @plantArchivePlantsTab.
  ///
  /// In en, this message translates to:
  /// **'Plants'**
  String get plantArchivePlantsTab;

  /// No description provided for @plantArchivePropagationsTab.
  ///
  /// In en, this message translates to:
  /// **'Propagations'**
  String get plantArchivePropagationsTab;

  /// No description provided for @plantArchiveEmpty.
  ///
  /// In en, this message translates to:
  /// **'Archive is empty'**
  String get plantArchiveEmpty;

  /// No description provided for @plantArchiveEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Plants are kept in the archive for 2 years'**
  String get plantArchiveEmptyHint;

  /// No description provided for @plantArchiveReasonMerged.
  ///
  /// In en, this message translates to:
  /// **'Merged'**
  String get plantArchiveReasonMerged;

  /// No description provided for @plantArchiveReasonDied.
  ///
  /// In en, this message translates to:
  /// **'Died'**
  String get plantArchiveReasonDied;

  /// No description provided for @plantArchiveReasonSold.
  ///
  /// In en, this message translates to:
  /// **'Sold'**
  String get plantArchiveReasonSold;

  /// No description provided for @plantArchiveDate.
  ///
  /// In en, this message translates to:
  /// **'Archived on {date}'**
  String plantArchiveDate(String date);

  /// No description provided for @plantArchiveNoteLabel.
  ///
  /// In en, this message translates to:
  /// **'Reason: {note}'**
  String plantArchiveNoteLabel(String note);

  /// No description provided for @plantDispose.
  ///
  /// In en, this message translates to:
  /// **'Remove from collection'**
  String get plantDispose;

  /// No description provided for @plantDisposeTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove plant'**
  String get plantDisposeTitle;

  /// No description provided for @plantDisposeReasonDied.
  ///
  /// In en, this message translates to:
  /// **'Died'**
  String get plantDisposeReasonDied;

  /// No description provided for @plantDisposeReasonSold.
  ///
  /// In en, this message translates to:
  /// **'Sold'**
  String get plantDisposeReasonSold;

  /// No description provided for @plantDisposeDeathNote.
  ///
  /// In en, this message translates to:
  /// **'Cause description'**
  String get plantDisposeDeathNote;

  /// No description provided for @plantDisposeDeathNoteRequired.
  ///
  /// In en, this message translates to:
  /// **'Describe why the plant died'**
  String get plantDisposeDeathNoteRequired;

  /// No description provided for @plantDisposeSaleAmount.
  ///
  /// In en, this message translates to:
  /// **'Sale amount'**
  String get plantDisposeSaleAmount;

  /// No description provided for @plantDisposeConfirm.
  ///
  /// In en, this message translates to:
  /// **'Move to archive'**
  String get plantDisposeConfirm;

  /// No description provided for @plantDisposeArchived.
  ///
  /// In en, this message translates to:
  /// **'Plant moved to archive'**
  String get plantDisposeArchived;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en', 'fr', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
