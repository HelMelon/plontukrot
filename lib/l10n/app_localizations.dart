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

  /// No description provided for @commonMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get commonMore;

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
  /// **'Sold and lost batches are kept for 1 year'**
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
  /// **'Sell'**
  String get propagationSell;

  /// No description provided for @propagationLose.
  ///
  /// In en, this message translates to:
  /// **'Mark as lost'**
  String get propagationLose;

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
  /// **'Delete this propagation batch?'**
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
  /// **'Deleting the \"{stageName}\" stage will delete the entire propagation batch and all other stages.'**
  String propagationDeleteStartStageBody(String stageName);

  /// No description provided for @propagationDeleteStageEntryBody.
  ///
  /// In en, this message translates to:
  /// **'Only this stage entry will be deleted. Others will remain.'**
  String get propagationDeleteStageEntryBody;

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
