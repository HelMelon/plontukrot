// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'SKÖRD';

  @override
  String get brandTagline =>
      'A journal of the fight for light and moisture. Sprouts are no guarantee. Only observation.';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonSave => 'Save';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonEdit => 'Edit';

  @override
  String get commonAdd => 'Add';

  @override
  String get commonClose => 'Close';

  @override
  String get commonMore => 'More';

  @override
  String get commonToday => 'Today';

  @override
  String commonError(String error) {
    return 'Error: $error';
  }

  @override
  String get commonShowMore => 'Show more';

  @override
  String get commonLoadMore => 'Load more';

  @override
  String get commonCollapse => 'Collapse';

  @override
  String get commonManage => 'Manage';

  @override
  String get commonOk => 'OK';

  @override
  String get commonNoDate => 'No date';

  @override
  String get commonNoData => 'No data';

  @override
  String get commonUntitled => 'Untitled';

  @override
  String get commonComposition => 'Composition';

  @override
  String get unitMl => 'ml';

  @override
  String get unitGrams => 'g';

  @override
  String get unitPiecesShort => 'pcs';

  @override
  String unitMlWithValue(int value) {
    return '$value ml';
  }

  @override
  String get milliliters => 'Milliliters';

  @override
  String get grams => 'Grams';

  @override
  String get loading => 'Loading…';

  @override
  String get preparing => 'Preparing…';

  @override
  String get authSignInGoogle => 'Sign in with Google';

  @override
  String get authSigningIn => 'Signing in…';

  @override
  String authSignInError(String error) {
    return 'Sign-in error: $error';
  }

  @override
  String get authGoogleIdTokenMissing => 'Google did not return an ID token.';

  @override
  String get authSignOut => 'Sign out';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageSystem => 'System default';

  @override
  String get settingsLanguageEnglish => 'English';

  @override
  String get settingsLanguageRussian => 'Russian';

  @override
  String get settingsLanguageGerman => 'German';

  @override
  String get settingsLanguageFrench => 'French';

  @override
  String get settingsCurrency => 'Currency';

  @override
  String get settingsCurrencyUsd => 'US dollar';

  @override
  String get settingsCurrencyEur => 'Euro';

  @override
  String get settingsCurrencyRub => 'Russian ruble';

  @override
  String get settingsCurrencyByn => 'Belarusian ruble';

  @override
  String get homeSearchHint => 'Search plants…';

  @override
  String get homeNoUserData => 'No user data';

  @override
  String get homeNoPlantsYet => 'No plants added yet';

  @override
  String get homeNoPropagatingPlants => 'No plants with active propagation';

  @override
  String get homeNoGroupPlants => 'No plant groups yet';

  @override
  String get homeNoPlantsForFilter => 'No plants match the selected filter';

  @override
  String get homeAllFamilies => 'All families';

  @override
  String get homeAllGenera => 'All genera';

  @override
  String get homeAllStages => 'All stages';

  @override
  String get homeNoFamily => 'No family';

  @override
  String get homePropagation => 'Propagation';

  @override
  String get homeGroups => 'Groups';

  @override
  String get homeArchive => 'Archive';

  @override
  String get homeMerge => 'Merge';

  @override
  String get homeMergeNeedCount => 'Select 2 to 3 plants';

  @override
  String get homeMergeNeedSameGenus =>
      'Plants must share the same genus to merge';

  @override
  String get homeWishList => 'WishLeafs';

  @override
  String get homeFinances => 'Finances';

  @override
  String get homeSort => 'Sort';

  @override
  String get homeSortSpecies => 'Species';

  @override
  String get homeSortNickname => 'Nickname';

  @override
  String get homeSortWatering => 'Watering';

  @override
  String get homeSortFertilizing => 'Fertilizing';

  @override
  String get homeSortDate => 'Date';

  @override
  String get homeSortFamily => 'Family';

  @override
  String get homeSortLastWatered => 'Last watered';

  @override
  String get homeSortLastFertilized => 'Last fertilized';

  @override
  String get homeSortDateAdded => 'Date added';

  @override
  String homeSelectedCount(int count) {
    return 'Selected: $count';
  }

  @override
  String get homeSelectAll => 'Select all';

  @override
  String get homeClearSelection => 'Clear selection';

  @override
  String get homeWatering => 'Watering';

  @override
  String get homeFertilizing => 'Fertilizing';

  @override
  String get homeRepotting => 'Repotting';

  @override
  String get homeUpdateFamily => 'Update family';

  @override
  String get homeUpdateFamilyTitle => 'Update family';

  @override
  String get homeFamilyLabel => 'Family';

  @override
  String get homeFertilizeSelectedTitle => 'Fertilize selected plants';

  @override
  String get homeRepotSelectedTitle => 'Repot selected plants';

  @override
  String get homeDeleteSelectedTitle => 'Delete selected plants?';

  @override
  String homeDeleteSelectedBody(int count) {
    return 'This will permanently delete $count plant(s).';
  }

  @override
  String homeDeleteSelectedBodyPlural(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'This will permanently delete $count plants.',
      one: 'This will permanently delete 1 plant.',
    );
    return '$_temp0';
  }

  @override
  String get searchNoPlantsInJournal => 'No plants in the journal';

  @override
  String get searchNothingFound => 'Nothing found';

  @override
  String get plantAdd => 'Add plant';

  @override
  String get plantEdit => 'Edit plant';

  @override
  String get plantSaveChanges => 'Save changes';

  @override
  String get plantGenus => 'Genus';

  @override
  String get plantSpecies => 'Species';

  @override
  String get plantCultivar => 'Cultivar';

  @override
  String get plantTradingName => 'Trading name';

  @override
  String get plantFamily => 'Family';

  @override
  String get plantNickname => 'Nickname';

  @override
  String get plantWateringFrequency => 'Watering frequency';

  @override
  String get plantGrowthStage => 'Growth stage';

  @override
  String get plantGenusRequired => 'Enter the plant genus';

  @override
  String get plantSpeciesRequired => 'Enter the plant species';

  @override
  String get plantInvalidWateringFrequency => 'Invalid watering frequency';

  @override
  String get plantUntitled => 'Untitled';

  @override
  String get plantDefaultTitle => 'Plant';

  @override
  String get plantGenusFallback => 'Genus';

  @override
  String plantSpeciesLabel(String species) {
    return 'Species: $species';
  }

  @override
  String plantCultivarLabel(String cultivar) {
    return 'Cultivar: $cultivar';
  }

  @override
  String plantStageLabel(String stage) {
    return 'Stage: $stage';
  }

  @override
  String get plantFamilyLabel => 'Family';

  @override
  String get plantTradingNameLabel => 'Trading name';

  @override
  String get plantGenusPrefix => 'Genus: ';

  @override
  String plantVariegationLabel(String value) {
    return 'Variegation: $value';
  }

  @override
  String get plantBotanicalData => 'Botanical data';

  @override
  String get plantDateAddedLabel => 'Date added';

  @override
  String get plantJournal => 'Journal';

  @override
  String get plantGallery => 'Gallery';

  @override
  String get plantCamera => 'Camera';

  @override
  String plantUploadError(String error) {
    return 'Upload error: $error';
  }

  @override
  String get plantPhotoDeleteTitle => 'Delete photo';

  @override
  String get plantPhotoDeleteConfirm => 'Delete this plant photo?';

  @override
  String get plantCropTitle => 'Crop photo';

  @override
  String get plantCropConfirm => 'Done';

  @override
  String plantCropError(String error) {
    return 'Crop error: $error';
  }

  @override
  String get plantEmptyStage => 'No plants of this stage in the collection yet';

  @override
  String get plantEmptyGenus => 'No plants of this genus in the collection yet';

  @override
  String get plantNote => 'Note';

  @override
  String get plantPropagation => 'Propagation';

  @override
  String get plantInitialLeafCount => 'Initial leaf count';

  @override
  String get plantInvalidInitialLeafCount => 'Invalid initial leaf count';

  @override
  String get plantLeafAdd => 'Add leaf';

  @override
  String get plantLeafRemove => 'Remove leaf';

  @override
  String get plantLeafRemoveTitle => 'What happened to the leaf?';

  @override
  String get plantLeafRemoveCut => 'Cut (for rooting)';

  @override
  String get plantLeafRemoveEaten => 'Eaten';

  @override
  String get plantLeafRemoveDried => 'Dried out';

  @override
  String get plantLeafStatsAnchor => 'Leaf statistics';

  @override
  String get plantLeafStatsTitle => 'Leaf growth';

  @override
  String plantLeafStatsMonthLine(String month, int gained, int lost) {
    return '$month: gained $gained, lost $lost';
  }

  @override
  String get stageUnknown => '🌱 Unknown';

  @override
  String get stageStart => '🌱 Start';

  @override
  String get stageBaby => '🌿 Baby';

  @override
  String get stageJuvenile => '🌳 Juvenile';

  @override
  String get stageAdult => '🌴 Adult';

  @override
  String get stageDescriptionTitle => 'Stage description';

  @override
  String get stageStartCheck1 => 'Tuber without roots';

  @override
  String get stageStartCheck2 => 'Leaf with a small rhizome';

  @override
  String get stageStartCheck3 => 'Rootable cutting';

  @override
  String get stageStartCheck4 => 'Plant is just starting to grow';

  @override
  String get stageBabyCheck1 => '1–2 true leaves';

  @override
  String get stageBabyCheck2 => 'Root system still forming';

  @override
  String get stageBabyCheck3 => 'Independent growth';

  @override
  String get stageJuvenileCheck1 => '3–5 leaves';

  @override
  String get stageJuvenileCheck2 => 'Good root system';

  @override
  String get stageJuvenileCheck3 => 'Active growth';

  @override
  String get stageAdultCheck1 => 'Fully formed plant';

  @override
  String get stageAdultCheck2 => 'Regularly produces new leaves';

  @override
  String get stageAdultCheck3 => 'Can be divided or cuttings taken';

  @override
  String get variegationLabel => 'Variegation';

  @override
  String get variegationNone => 'None';

  @override
  String get variegationAurea => 'Aurea';

  @override
  String get variegationAlba => 'Alba';

  @override
  String get variegationPink => 'Pink';

  @override
  String get variegationSplash => 'Splash';

  @override
  String get variegationMint => 'Mint';

  @override
  String get variegationMulticolor => 'Multicolor';

  @override
  String get variegationTricolor => 'Tricolor';

  @override
  String get variegationUnknown => 'Unknown';

  @override
  String get watering => 'Watering';

  @override
  String get wateringHistory => 'Watering history';

  @override
  String get wateringAdd => 'Add watering';

  @override
  String get wateringEdit => 'Edit watering';

  @override
  String get wateringDeleteTitle => 'Delete watering';

  @override
  String get wateringDeleteConfirm => 'Delete this entry?';

  @override
  String get wateringEmpty => 'No watering entries yet';

  @override
  String get fertilizing => 'Fertilizing';

  @override
  String get fertilizingHistory => 'Fertilizing history';

  @override
  String get fertilizingAdd => 'Add fertilizing';

  @override
  String get fertilizingEdit => 'Edit fertilizing';

  @override
  String get fertilizingDeleteTitle => 'Delete fertilizing';

  @override
  String get fertilizingDeleteConfirm => 'Delete this entry?';

  @override
  String get fertilizingEmpty => 'No fertilizing entries yet';

  @override
  String get fertilizingSelectedTitle => 'Fertilize selected plants';

  @override
  String get fertilizingApplicationMethod => 'Application method';

  @override
  String get fertilizingRoot => 'Root';

  @override
  String get fertilizingFoliar => 'Foliar';

  @override
  String get fertilizingSaved => 'Saved';

  @override
  String get fertilizingNewMix => 'New mix';

  @override
  String get fertilizingCatalog => 'Catalog';

  @override
  String get fertilizingEmptyCatalog =>
      'No fertilizers yet. Add a ready-made one or save a mix.';

  @override
  String get fertilizingGoToNewMix => 'Go to “New mix”';

  @override
  String get fertilizingSelectFertilizer => 'Select a fertilizer';

  @override
  String get fertilizingViewComposition => 'View composition';

  @override
  String fertilizingMixWaterVolume(int value) {
    return 'Mix water volume: $value ml';
  }

  @override
  String get fertilizingIngredients => 'Ingredients';

  @override
  String get fertilizingTapIngredientHint =>
      'Tap an ingredient to set the amount (g or ml)';

  @override
  String get fertilizingSaveThisMix => 'Save this mix';

  @override
  String get fertilizingMixName => 'Mix name';

  @override
  String get fertilizingMixNameHint => 'e.g. Growth formula';

  @override
  String get fertilizingWaterVolume => 'Water volume';

  @override
  String get fertilizingAddIngredient => 'Add ingredient';

  @override
  String get fertilizingIngredientNameHint => 'Ingredient name';

  @override
  String get fertilizerFallbackName => 'Fertilizer';

  @override
  String get fertilizerKindMix => 'Mix';

  @override
  String get fertilizerKindPurchased => 'Ready-made';

  @override
  String get fertilizerCustomMix => 'Custom mix';

  @override
  String get fertilizerUnknown => 'Unknown';

  @override
  String get fertilizerInvalidDose => 'Invalid dose';

  @override
  String get fertilizerNameLabel => 'Name';

  @override
  String get fertilizerNameHint => 'e.g. Pokon Universal';

  @override
  String get fertilizerDoseLabelPurchased => 'Dose';

  @override
  String get fertilizerDoseLabelMix => 'Amount';

  @override
  String get fertilizerDoseHint => 'e.g. 2';

  @override
  String fertilizerMixComposition(String components) {
    return 'Mix composition: $components';
  }

  @override
  String fertilizerWithMeta(String name, String kind, int waterMl) {
    return '$name · $kind · $waterMl ml';
  }

  @override
  String fertilizerWaterLine(int value) {
    return 'Water: $value ml';
  }

  @override
  String get manageFertilizersTitle => 'Manage fertilizers';

  @override
  String get manageFertilizerIngredientsTitle => 'Manage ingredients';

  @override
  String get manageComponentsTitle => 'Manage components';

  @override
  String get componentNameHint => 'Component name';

  @override
  String get emptyFertilizers => 'No fertilizers yet';

  @override
  String get emptyIngredients => 'No ingredients yet';

  @override
  String get emptyComponents => 'No components yet';

  @override
  String get emptyComposition => 'Composition is empty';

  @override
  String get repotting => 'Repotting';

  @override
  String get repottingHistory => 'Repotting history';

  @override
  String get repottingAdd => 'Add repotting';

  @override
  String get repottingEdit => 'Edit repotting';

  @override
  String get repottingDeleteTitle => 'Delete repotting';

  @override
  String get repottingDeleteConfirm => 'Delete this entry?';

  @override
  String get repottingEmpty => 'No repotting entries yet';

  @override
  String get repottingSlowRelease => 'Slow-release fertilizer';

  @override
  String get repottingSelectSoil => 'Select soil';

  @override
  String get repottingSoilFallback => 'Soil';

  @override
  String get repottingSoilComposition => 'Soil composition';

  @override
  String get soilCustomMix => 'Custom mix';

  @override
  String soilParts(String parts) {
    return '$parts parts';
  }

  @override
  String get notesEmpty => 'No notes yet';

  @override
  String get notesAdd => 'Add note';

  @override
  String get notesAddHint => 'Add a new journal entry for this plant.';

  @override
  String get notesEdit => 'Edit note';

  @override
  String get notesLabel => 'Journal entry';

  @override
  String get notesEditLabel => 'Edit note';

  @override
  String get notesCannotBeEmpty => 'Note cannot be empty';

  @override
  String get notesDeleteTitle => 'Delete note';

  @override
  String get notesDeleteConfirm => 'Delete this note?';

  @override
  String get notesOptional => 'Note (optional)';

  @override
  String get fieldRequired => 'This field is required';

  @override
  String get propagationTitle => 'Propagation';

  @override
  String get propagationActiveTab => 'Active';

  @override
  String get propagationArchiveTab => 'Archive';

  @override
  String get propagationEmptyActive => 'No active propagations';

  @override
  String get propagationEmptyArchive => 'Archive is empty';

  @override
  String get propagationEmptyActiveHint => 'Add a batch from a plant page';

  @override
  String get propagationEmptyArchiveHint =>
      'Completed batches are kept for 1 year';

  @override
  String get propagationAdd => 'Add propagation';

  @override
  String get propagationChangeStage => 'Change stage';

  @override
  String get propagationSell => 'Sold';

  @override
  String get propagationGift => 'Gifted';

  @override
  String get propagationTrade => 'Traded';

  @override
  String get propagationLose => 'Lost';

  @override
  String get propagationInitialStage => 'Initial stage';

  @override
  String propagationParentLabel(String name) {
    return 'Parent: $name';
  }

  @override
  String get propagationDetails => 'Propagation details';

  @override
  String get propagationQuantity => 'Quantity';

  @override
  String get propagationQuantityMin => 'Enter a quantity (minimum 1)';

  @override
  String get propagationAliveNow => 'Alive now';

  @override
  String get propagationAliveRequired => 'Enter the number alive';

  @override
  String get propagationSellQuantityRequired => 'Enter a quantity to sell';

  @override
  String get propagationGiftQuantityRequired => 'Enter a quantity';

  @override
  String get propagationTradeQuantityRequired => 'Enter a quantity';

  @override
  String get propagationLoseQuantityRequired => 'Enter a quantity';

  @override
  String propagationQuantityExceedsAlive(int count) {
    return 'Cannot exceed alive count ($count)';
  }

  @override
  String propagationDate(String date) {
    return 'Date: $date';
  }

  @override
  String propagationSinceDate(String date) {
    return 'since $date';
  }

  @override
  String propagationSoldCount(int count) {
    return 'sold $count';
  }

  @override
  String propagationGiftedCount(int count) {
    return 'gifted $count';
  }

  @override
  String propagationTradedCount(int count) {
    return 'traded $count';
  }

  @override
  String propagationLostCount(int count) {
    return 'lost $count';
  }

  @override
  String propagationSoldLabel(int count, String unit) {
    return 'Sold: $count $unit';
  }

  @override
  String propagationGiftedLabel(int count, String unit) {
    return 'Gifted: $count $unit';
  }

  @override
  String propagationTradedLabel(int count, String unit) {
    return 'Traded: $count $unit';
  }

  @override
  String propagationLostLabel(int count, String unit) {
    return 'Lost: $count $unit';
  }

  @override
  String propagationStartedLabel(int batches, int quantity) {
    return 'Started: $batches batches · $quantity pcs';
  }

  @override
  String propagationStatsTitle(int year) {
    return 'Stats $year';
  }

  @override
  String propagationByMethods(String methods) {
    return 'By methods: $methods';
  }

  @override
  String propagationByFamilies(String families) {
    return 'By families: $families';
  }

  @override
  String propagationQuantityPieces(int count) {
    return '$count pcs';
  }

  @override
  String get propagationDeleteTitle => 'Delete propagation';

  @override
  String get propagationDeleteConfirm =>
      'The propagation batch and all stage history will be permanently deleted. Continue?';

  @override
  String get propagationDeleteHistoryEntry => 'Delete history entry?';

  @override
  String get propagationTimelineEmpty => 'No stage history yet';

  @override
  String daysCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
      zero: 'today',
    );
    return '$_temp0';
  }

  @override
  String propagationAliveWithMethod(int count, String method) {
    return '$count $method';
  }

  @override
  String get propagationMethodLeaf => 'Leaf';

  @override
  String get propagationMethodLeafPlural => 'leaves';

  @override
  String get propagationMethodLeafFragment => 'Leaf fragment';

  @override
  String get propagationMethodLeafFragmentPlural => 'leaf fragments';

  @override
  String get propagationMethodRhizome => 'Rhizome';

  @override
  String get propagationMethodRhizomePlural => 'rhizomes';

  @override
  String get propagationMethodTuber => 'Tuber';

  @override
  String get propagationMethodTuberPlural => 'tubers';

  @override
  String get propagationMethodDivision => 'Division';

  @override
  String get propagationMethodDivisionPlural => 'divisions';

  @override
  String get propagationMethodOffset => 'Offset';

  @override
  String get propagationMethodOffsetPlural => 'offsets';

  @override
  String get propagationMethodCutting => 'Cutting';

  @override
  String get propagationMethodCuttingPlural => 'cuttings';

  @override
  String get propagationMethodMicrocloning => 'Microcloning';

  @override
  String get propagationMethodMicrocloningPlural => 'microclones';

  @override
  String get propagationStatusActive => 'Active';

  @override
  String get propagationStatusSold => 'Sold';

  @override
  String get propagationStatusGifted => 'Gifted';

  @override
  String get propagationStatusTraded => 'Traded';

  @override
  String get propagationStatusLost => 'Lost';

  @override
  String get propagationStartRooting => 'Start rooting';

  @override
  String get propagationMethodField => 'Method';

  @override
  String propagationQuantityExceedsOriginal(int count) {
    return 'Cannot exceed original quantity ($count)';
  }

  @override
  String propagationAliveWithPlant(int count, String plantName) {
    return '$count alive · $plantName';
  }

  @override
  String get propagationSellQuantity => 'Quantity to sell';

  @override
  String get propagationGiftQuantity => 'Quantity to gift';

  @override
  String get propagationTradeQuantity => 'Quantity to trade';

  @override
  String get propagationLoseQuantity => 'Quantity lost';

  @override
  String get propagationWriteOff => 'Write off';

  @override
  String get propagationConfirmGift => 'Gift';

  @override
  String get propagationConfirmTrade => 'Trade';

  @override
  String get propagationTimeline => 'Timeline';

  @override
  String propagationSoldCountLabel(int count) {
    return 'Sold: $count';
  }

  @override
  String propagationGiftedCountLabel(int count) {
    return 'Gifted: $count';
  }

  @override
  String propagationTradedCountLabel(int count) {
    return 'Traded: $count';
  }

  @override
  String propagationLostCountLabel(int count) {
    return 'Lost: $count';
  }

  @override
  String propagationOfTotal(int count) {
    return 'of $count';
  }

  @override
  String propagationDeleteStartStageBody(String stageName) {
    return 'Deleting the \"$stageName\" stage will permanently delete the entire propagation batch and all other stages. Continue?';
  }

  @override
  String get propagationDeleteStageEntryBody =>
      'Only this stage entry will be deleted. Others will remain.';

  @override
  String get propagationDeleteLastEntryBody =>
      'This is the last history entry. The propagation batch will be permanently deleted. Continue?';

  @override
  String get deleteEntryConfirm => 'Delete this entry?';

  @override
  String get promptEmptyNotAllowed => 'Value cannot be empty';

  @override
  String get repottingEmptySoils => 'No saved soils yet. Create a new mix.';

  @override
  String get repottingSoilTapHint =>
      'Tap: +1 part · Long press: ½ part (again to remove)';

  @override
  String get repottingSlowReleaseSubtitle => 'Added during repotting';

  @override
  String get repottingMixNameHint => 'e.g. Aroid mix';

  @override
  String get fertilizerPurchasedAddTitle => 'Ready-made fertilizer';

  @override
  String get fertilizerEditTitle => 'Edit fertilizer';

  @override
  String get fertilizerDeleteTitle => 'Delete fertilizer';

  @override
  String get ingredientEditTitle => 'Edit ingredient';

  @override
  String get ingredientDeleteTitle => 'Delete ingredient';

  @override
  String get componentEditTitle => 'Edit component';

  @override
  String get componentDeleteTitle => 'Delete component';

  @override
  String get componentAddTitle => 'Add component';

  @override
  String catalogItemDeleteConfirm(String name) {
    return 'Remove \"$name\" from the catalog?';
  }

  @override
  String catalogItemAlreadyExists(String name) {
    return '\"$name\" is already in the catalog';
  }

  @override
  String get manageFertilizersHint =>
      'Mixes are saved from \"New mix\". Type can be changed: ready-made ↔ mix.';

  @override
  String get fertilizerWaterForDilution => 'Water for dilution';

  @override
  String fertilizerDoseOnWaterOptional(int waterMl) {
    return 'Dose per $waterMl ml (optional)';
  }

  @override
  String get fertilizerDoseOptional => 'Dose (optional)';

  @override
  String get fertilizerKindSection => 'Type';

  @override
  String get soilComponentsTitle => 'Soil components';

  @override
  String get noComponents => 'No components';

  @override
  String get doseAmountRequired => 'Enter an amount';

  @override
  String get doseInvalidNumber => 'Invalid number';

  @override
  String get doseRemove => 'Remove';

  @override
  String get wishListTitle => 'WishLeafs';

  @override
  String get wishListAdd => 'Add to wish list';

  @override
  String get wishListEdit => 'Edit plant';

  @override
  String get wishListEmpty => 'Wish list is empty';

  @override
  String get wishListEmptyHint => 'Add plants you want to buy';

  @override
  String get wishListNameEn => 'Name (English)';

  @override
  String get wishListNameAlt => 'Alternative name';

  @override
  String get wishListNameEnRequired => 'Enter the English name';

  @override
  String get wishListNameAltRequired => 'Enter an alternative name';

  @override
  String get wishListBought => 'Bought';

  @override
  String get wishListExchanged => 'Exchanged';

  @override
  String get wishListAcquireTitle => 'How did you get it?';

  @override
  String get wishListExchangeNoFinanceHint =>
      'Exchange is not recorded in finances. Next you can add the plant to your collection.';

  @override
  String get wishListSelectForTrade => 'Plant from wish list';

  @override
  String get wishListSelectForTradeHint =>
      'Choose the plant you received in exchange. No finance entry will be created.';

  @override
  String get wishListAcquireContinue => 'Continue';

  @override
  String get wishListExport => 'Export';

  @override
  String get wishListExportEmpty => 'Nothing to export';

  @override
  String wishListDeleteConfirm(String name) {
    return 'Remove “$name” from the wish list?';
  }

  @override
  String get financesTitle => 'Finances';

  @override
  String get financesAdd => 'Add entry';

  @override
  String get financesEdit => 'Edit entry';

  @override
  String get financesEmpty => 'No finance entries yet';

  @override
  String get financesEmptyHint => 'Track income from sales and plant expenses';

  @override
  String get financesIncome => 'Income';

  @override
  String get financesExpense => 'Expenses';

  @override
  String get financesBalance => 'Balance';

  @override
  String get financesAnalyticsTitle => 'Last 3 months';

  @override
  String get financesNoIncome => 'No income yet';

  @override
  String get financesNoExpense => 'No expenses yet';

  @override
  String get financesTitleLabel => 'Title';

  @override
  String get financesTitleRequired => 'Enter a title';

  @override
  String financesAmountLabel(String symbol) {
    return 'Amount ($symbol)';
  }

  @override
  String get financesAmountRequired => 'Enter a valid amount';

  @override
  String financesDeleteConfirm(String title) {
    return 'Delete “$title”?';
  }

  @override
  String get financesAlsoAddToCatalog => 'Also add to catalog';

  @override
  String get financesAsSoilComponent => 'Soil component';

  @override
  String get financesAsFertilizer => 'Fertilizer';

  @override
  String get financesAsPurchasedFertilizer => 'Ready-made fertilizer';

  @override
  String get financesAsReadyMadeSoil => 'Ready-made soil mix';

  @override
  String financesPropagationSaleTitle(String plantName, int quantity) {
    return 'Sale: $plantName ×$quantity';
  }

  @override
  String financesPlantSaleTitle(String plantName) {
    return 'Plant sale: $plantName';
  }

  @override
  String get propagationTradeForWishList => 'For a wish-list plant';

  @override
  String get commonContinue => 'Continue';

  @override
  String get commonSkip => 'Skip';

  @override
  String get plantMergeTitle => 'Merge into a group';

  @override
  String plantMergeMemberLabel(int index) {
    return 'Cultivar $index';
  }

  @override
  String get plantMergeMembersRequired => 'Enter at least two cultivars';

  @override
  String get plantGroupMembers => 'Group cultivars';

  @override
  String plantCultivarsLabel(String cultivars) {
    return 'Cultivars: $cultivars';
  }

  @override
  String get plantArchiveTitle => 'Plant archive';

  @override
  String get plantArchiveEmpty => 'Archive is empty';

  @override
  String get plantArchiveEmptyHint =>
      'Plants are kept in the archive for 2 years';

  @override
  String get plantArchiveReasonMerged => 'Merged';

  @override
  String get plantArchiveReasonDied => 'Died';

  @override
  String get plantArchiveReasonSold => 'Sold';

  @override
  String plantArchiveDate(String date) {
    return 'Archived on $date';
  }

  @override
  String plantArchiveNoteLabel(String note) {
    return 'Reason: $note';
  }

  @override
  String get plantDispose => 'Remove from collection';

  @override
  String get plantDisposeTitle => 'Remove plant';

  @override
  String get plantDisposeReasonDied => 'Died';

  @override
  String get plantDisposeReasonSold => 'Sold';

  @override
  String get plantDisposeDeathNote => 'Cause description';

  @override
  String get plantDisposeDeathNoteRequired => 'Describe why the plant died';

  @override
  String get plantDisposeSaleAmount => 'Sale amount';

  @override
  String get plantDisposeConfirm => 'Move to archive';

  @override
  String get plantDisposeArchived => 'Plant moved to archive';
}
