// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appName => 'SKÖRD';

  @override
  String get brandTagline =>
      'Ein Journal des Kampfes um Licht und Feuchtigkeit. Keimlinge sind keine Garantie. Nur Beobachtung.';

  @override
  String get commonCancel => 'Abbrechen';

  @override
  String get commonSave => 'Speichern';

  @override
  String get commonDelete => 'Löschen';

  @override
  String get commonEdit => 'Bearbeiten';

  @override
  String get commonAdd => 'Hinzufügen';

  @override
  String get commonClose => 'Schließen';

  @override
  String get commonMore => 'Mehr';

  @override
  String get commonToday => 'Heute';

  @override
  String commonError(String error) {
    return 'Fehler: $error';
  }

  @override
  String get commonShowMore => 'Mehr anzeigen';

  @override
  String get commonLoadMore => 'Mehr laden';

  @override
  String get commonCollapse => 'Einklappen';

  @override
  String get commonManage => 'Verwalten';

  @override
  String get commonOk => 'OK';

  @override
  String get commonNoDate => 'Kein Datum';

  @override
  String get commonNoData => 'Keine Daten';

  @override
  String get commonUntitled => 'Ohne Titel';

  @override
  String get commonComposition => 'Zusammensetzung';

  @override
  String get unitMl => 'ml';

  @override
  String get unitGrams => 'g';

  @override
  String get unitPiecesShort => 'Stk.';

  @override
  String unitMlWithValue(int value) {
    return '$value ml';
  }

  @override
  String get milliliters => 'Milliliter';

  @override
  String get grams => 'Gramm';

  @override
  String get loading => 'Laden…';

  @override
  String get preparing => 'Vorbereitung…';

  @override
  String get authSignInGoogle => 'Mit Google anmelden';

  @override
  String get authSigningIn => 'Anmeldung…';

  @override
  String authSignInError(String error) {
    return 'Anmeldefehler: $error';
  }

  @override
  String get authGoogleIdTokenMissing =>
      'Google hat kein ID-Token zurückgegeben.';

  @override
  String get authSignOut => 'Abmelden';

  @override
  String get settingsTitle => 'Einstellungen';

  @override
  String get settingsLanguage => 'Sprache';

  @override
  String get settingsLanguageSystem => 'Systemstandard';

  @override
  String get settingsLanguageEnglish => 'English';

  @override
  String get settingsLanguageRussian => 'Русский';

  @override
  String get settingsLanguageGerman => 'Deutsch';

  @override
  String get settingsLanguageFrench => 'Français';

  @override
  String get settingsCurrency => 'Währung';

  @override
  String get settingsCurrencyUsd => 'US-Dollar';

  @override
  String get settingsCurrencyEur => 'Euro';

  @override
  String get settingsCurrencyRub => 'Russischer Rubel';

  @override
  String get settingsCurrencyByn => 'Belarussischer Rubel';

  @override
  String get homeSearchHint => 'Pflanzen suchen…';

  @override
  String get homeNoUserData => 'Keine Nutzerdaten';

  @override
  String get homeNoPlantsYet => 'Noch keine Pflanzen hinzugefügt';

  @override
  String get homeNoPropagatingPlants => 'Keine Pflanzen mit aktiver Vermehrung';

  @override
  String get homeNoGroupPlants => 'Keine Pflanzengruppen';

  @override
  String get homeNoPlantsForFilter =>
      'Keine Pflanzen passen zum gewählten Filter';

  @override
  String get homeAllFamilies => 'Alle Familien';

  @override
  String get homeAllGenera => 'Alle Gattungen';

  @override
  String get homeAllStages => 'Alle Stadien';

  @override
  String get homeNoFamily => 'Ohne Familie';

  @override
  String get homePropagation => 'Vermehrung';

  @override
  String get homeGroups => 'Gruppen';

  @override
  String get homeArchive => 'Archiv';

  @override
  String get homeMerge => 'Zusammenführen';

  @override
  String get homeMergeNeedCount => 'Wählen Sie 2 bis 3 Pflanzen';

  @override
  String get homeMergeNeedSameGenus =>
      'Zum Zusammenführen muss die Gattung übereinstimmen';

  @override
  String get homeWishList => 'WishLeafs';

  @override
  String get homeFinances => 'Finanzen';

  @override
  String get homeSort => 'Sortieren';

  @override
  String get homeSortSpecies => 'Art';

  @override
  String get homeSortNickname => 'Spitzname';

  @override
  String get homeSortWatering => 'Gießen';

  @override
  String get homeSortFertilizing => 'Düngung';

  @override
  String get homeSortDate => 'Datum';

  @override
  String get homeSortFamily => 'Familie';

  @override
  String get homeSortLastWatered => 'Zuletzt gegossen';

  @override
  String get homeSortLastFertilized => 'Zuletzt gedüngt';

  @override
  String get homeSortDateAdded => 'Hinzugefügt am';

  @override
  String homeSelectedCount(int count) {
    return 'Ausgewählt: $count';
  }

  @override
  String get homeSelectAll => 'Alle auswählen';

  @override
  String get homeClearSelection => 'Auswahl aufheben';

  @override
  String get homeWatering => 'Gießen';

  @override
  String get homeFertilizing => 'Düngung';

  @override
  String get homeRepotting => 'Umtopfen';

  @override
  String get homeUpdateFamily => 'Familie ändern';

  @override
  String get homeUpdateFamilyTitle => 'Familie ändern';

  @override
  String get homeFamilyLabel => 'Familie';

  @override
  String get homeFertilizeSelectedTitle => 'Ausgewählte Pflanzen düngen';

  @override
  String get homeRepotSelectedTitle => 'Ausgewählte Pflanzen umtopfen';

  @override
  String get homeDeleteSelectedTitle => 'Ausgewählte Pflanzen löschen?';

  @override
  String homeDeleteSelectedBody(int count) {
    return 'Dadurch werden $count Pflanze(n) dauerhaft gelöscht.';
  }

  @override
  String homeDeleteSelectedBodyPlural(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Dadurch werden $count Pflanzen dauerhaft gelöscht.',
      one: 'Dadurch wird 1 Pflanze dauerhaft gelöscht.',
    );
    return '$_temp0';
  }

  @override
  String get searchNoPlantsInJournal => 'Keine Pflanzen im Journal';

  @override
  String get searchNothingFound => 'Nichts gefunden';

  @override
  String get plantAdd => 'Pflanze hinzufügen';

  @override
  String get plantEdit => 'Pflanze bearbeiten';

  @override
  String get plantSaveChanges => 'Änderungen speichern';

  @override
  String get plantGenus => 'Gattung';

  @override
  String get plantSpecies => 'Art';

  @override
  String get plantCultivar => 'Sorte';

  @override
  String get plantTradingName => 'Handelsname';

  @override
  String get plantFamily => 'Familie';

  @override
  String get plantNickname => 'Spitzname';

  @override
  String get plantWateringFrequency => 'Gießhäufigkeit';

  @override
  String get plantGrowthStage => 'Wachstumsstadium';

  @override
  String get plantGenusRequired => 'Gattung der Pflanze eingeben';

  @override
  String get plantSpeciesRequired => 'Art der Pflanze eingeben';

  @override
  String get plantInvalidWateringFrequency => 'Ungültige Gießhäufigkeit';

  @override
  String get plantUntitled => 'Ohne Titel';

  @override
  String get plantDefaultTitle => 'Pflanze';

  @override
  String get plantGenusFallback => 'Gattung';

  @override
  String plantSpeciesLabel(String species) {
    return 'Art: $species';
  }

  @override
  String plantCultivarLabel(String cultivar) {
    return 'Sorte: $cultivar';
  }

  @override
  String plantStageLabel(String stage) {
    return 'Stadium: $stage';
  }

  @override
  String get plantFamilyLabel => 'Familie';

  @override
  String get plantTradingNameLabel => 'Handelsname';

  @override
  String get plantGenusPrefix => 'Gattung: ';

  @override
  String plantVariegationLabel(String value) {
    return 'Panaschierung: $value';
  }

  @override
  String get plantBotanicalData => 'Botanische Daten';

  @override
  String get plantDateAddedLabel => 'Hinzufügungsdatum';

  @override
  String get plantJournal => 'Journal';

  @override
  String get plantGallery => 'Galerie';

  @override
  String get plantCamera => 'Kamera';

  @override
  String plantUploadError(String error) {
    return 'Upload-Fehler: $error';
  }

  @override
  String get plantEmptyStage =>
      'Noch keine Pflanzen dieses Stadiums in der Sammlung';

  @override
  String get plantEmptyGenus =>
      'Noch keine Pflanzen dieser Gattung in der Sammlung';

  @override
  String get plantNote => 'Notiz';

  @override
  String get plantPropagation => 'Vermehrung';

  @override
  String get plantInitialLeafCount => 'Anfängliche Blattzahl';

  @override
  String get plantInvalidInitialLeafCount => 'Ungültige anfängliche Blattzahl';

  @override
  String get plantLeafAdd => 'Blatt hinzufügen';

  @override
  String get plantLeafRemove => 'Blatt entfernen';

  @override
  String get plantLeafRemoveTitle => 'Was ist mit dem Blatt passiert?';

  @override
  String get plantLeafRemoveCut => 'Abgeschnitten (zum Bewurzeln)';

  @override
  String get plantLeafRemoveEaten => 'Gefressen';

  @override
  String get plantLeafRemoveDried => 'Eingetrocknet';

  @override
  String get plantLeafStatsAnchor => 'Blattstatistik';

  @override
  String get plantLeafStatsTitle => 'Blattwachstum';

  @override
  String plantLeafStatsMonthLine(String month, int gained, int lost) {
    return '$month: dazugekommen $gained, verloren $lost';
  }

  @override
  String get stageUnknown => '🌱 Unbekannt';

  @override
  String get stageStart => '🌱 Start';

  @override
  String get stageBaby => '🌿 Baby';

  @override
  String get stageJuvenile => '🌳 Jungpflanze';

  @override
  String get stageAdult => '🌴 Ausgewachsen';

  @override
  String get stageDescriptionTitle => 'Stadiumsbeschreibung';

  @override
  String get stageStartCheck1 => 'Knolle ohne Wurzeln';

  @override
  String get stageStartCheck2 => 'Blatt mit kleinem Rhizom';

  @override
  String get stageStartCheck3 => 'Bewurzelbarer Steckling';

  @override
  String get stageStartCheck4 => 'Pflanze beginnt gerade zu wachsen';

  @override
  String get stageBabyCheck1 => '1–2 echte Blätter';

  @override
  String get stageBabyCheck2 => 'Wurzelsystem noch im Aufbau';

  @override
  String get stageBabyCheck3 => 'Selbstständiges Wachstum';

  @override
  String get stageJuvenileCheck1 => '3–5 Blätter';

  @override
  String get stageJuvenileCheck2 => 'Gutes Wurzelsystem';

  @override
  String get stageJuvenileCheck3 => 'Aktives Wachstum';

  @override
  String get stageAdultCheck1 => 'Vollständig entwickelte Pflanze';

  @override
  String get stageAdultCheck2 => 'Bildet regelmäßig neue Blätter';

  @override
  String get stageAdultCheck3 => 'Kann geteilt oder Stecklinge genommen werden';

  @override
  String get variegationLabel => 'Panaschierung';

  @override
  String get variegationNone => 'Keine';

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
  String get variegationUnknown => 'Unbekannt';

  @override
  String get watering => 'Gießen';

  @override
  String get wateringHistory => 'Gießverlauf';

  @override
  String get wateringAdd => 'Gießen hinzufügen';

  @override
  String get wateringEdit => 'Gießen bearbeiten';

  @override
  String get wateringDeleteTitle => 'Gießen löschen';

  @override
  String get wateringDeleteConfirm => 'Diesen Eintrag löschen?';

  @override
  String get wateringEmpty => 'Noch keine Gießeinträge';

  @override
  String get fertilizing => 'Düngung';

  @override
  String get fertilizingHistory => 'Düngeverlauf';

  @override
  String get fertilizingAdd => 'Düngung hinzufügen';

  @override
  String get fertilizingEdit => 'Düngung bearbeiten';

  @override
  String get fertilizingDeleteTitle => 'Düngung löschen';

  @override
  String get fertilizingDeleteConfirm => 'Diesen Eintrag löschen?';

  @override
  String get fertilizingEmpty => 'Noch keine Düngeeinträge';

  @override
  String get fertilizingSelectedTitle => 'Ausgewählte Pflanzen düngen';

  @override
  String get fertilizingApplicationMethod => 'Anwendungsmethode';

  @override
  String get fertilizingRoot => 'Wurzel';

  @override
  String get fertilizingFoliar => 'Blattdüngung';

  @override
  String get fertilizingSaved => 'Gespeichert';

  @override
  String get fertilizingNewMix => 'Neuer Mix';

  @override
  String get fertilizingCatalog => 'Katalog';

  @override
  String get fertilizingEmptyCatalog =>
      'Noch keine Dünger. Fertigen Dünger hinzufügen oder Mix speichern.';

  @override
  String get fertilizingGoToNewMix => 'Zu „Neuer Mix“';

  @override
  String get fertilizingSelectFertilizer => 'Dünger auswählen';

  @override
  String get fertilizingViewComposition => 'Zusammensetzung anzeigen';

  @override
  String fertilizingMixWaterVolume(int value) {
    return 'Wassermenge für den Mix: $value ml';
  }

  @override
  String get fertilizingIngredients => 'Inhaltsstoffe';

  @override
  String get fertilizingTapIngredientHint =>
      'Tippen Sie auf einen Inhaltsstoff, um die Menge festzulegen (g oder ml)';

  @override
  String get fertilizingSaveThisMix => 'Diesen Mix speichern';

  @override
  String get fertilizingMixName => 'Mix-Name';

  @override
  String get fertilizingMixNameHint => 'z. B. Wachstumsformel';

  @override
  String get fertilizingWaterVolume => 'Wassermenge';

  @override
  String get fertilizingAddIngredient => 'Inhaltsstoff hinzufügen';

  @override
  String get fertilizingIngredientNameHint => 'Name des Inhaltsstoffs';

  @override
  String get fertilizerFallbackName => 'Dünger';

  @override
  String get fertilizerKindMix => 'Mix';

  @override
  String get fertilizerKindPurchased => 'Fertig';

  @override
  String get fertilizerCustomMix => 'Eigener Mix';

  @override
  String get fertilizerUnknown => 'Unbekannt';

  @override
  String get fertilizerInvalidDose => 'Ungültige Dosis';

  @override
  String get fertilizerNameLabel => 'Name';

  @override
  String get fertilizerNameHint => 'z. B. Pokon Universal';

  @override
  String get fertilizerDoseLabelPurchased => 'Dosis';

  @override
  String get fertilizerDoseLabelMix => 'Menge';

  @override
  String get fertilizerDoseHint => 'z. B. 2';

  @override
  String fertilizerMixComposition(String components) {
    return 'Mix-Zusammensetzung: $components';
  }

  @override
  String fertilizerWithMeta(String name, String kind, int waterMl) {
    return '$name · $kind · $waterMl ml';
  }

  @override
  String fertilizerWaterLine(int value) {
    return 'Wasser: $value ml';
  }

  @override
  String get manageFertilizersTitle => 'Dünger verwalten';

  @override
  String get manageFertilizerIngredientsTitle => 'Inhaltsstoffe verwalten';

  @override
  String get manageComponentsTitle => 'Komponenten verwalten';

  @override
  String get componentNameHint => 'Name der Komponente';

  @override
  String get emptyFertilizers => 'Noch keine Dünger';

  @override
  String get emptyIngredients => 'Noch keine Inhaltsstoffe';

  @override
  String get emptyComponents => 'Noch keine Komponenten';

  @override
  String get emptyComposition => 'Zusammensetzung ist leer';

  @override
  String get repotting => 'Umtopfen';

  @override
  String get repottingHistory => 'Umtopfverlauf';

  @override
  String get repottingAdd => 'Umtopfen hinzufügen';

  @override
  String get repottingEdit => 'Umtopfen bearbeiten';

  @override
  String get repottingDeleteTitle => 'Umtopfen löschen';

  @override
  String get repottingDeleteConfirm => 'Diesen Eintrag löschen?';

  @override
  String get repottingEmpty => 'Noch keine Umtopfeinträge';

  @override
  String get repottingSlowRelease => 'Langzeitdünger';

  @override
  String get repottingSelectSoil => 'Substrat auswählen';

  @override
  String get repottingSoilFallback => 'Substrat';

  @override
  String get repottingSoilComposition => 'Substratzusammensetzung';

  @override
  String get soilCustomMix => 'Eigener Mix';

  @override
  String soilParts(String parts) {
    return '$parts Teile';
  }

  @override
  String get notesEmpty => 'Noch keine Notizen';

  @override
  String get notesAdd => 'Notiz hinzufügen';

  @override
  String get notesAddHint =>
      'Neuen Journaleintrag für diese Pflanze hinzufügen.';

  @override
  String get notesEdit => 'Notiz bearbeiten';

  @override
  String get notesLabel => 'Journaleintrag';

  @override
  String get notesEditLabel => 'Notiz bearbeiten';

  @override
  String get notesCannotBeEmpty => 'Notiz darf nicht leer sein';

  @override
  String get notesDeleteTitle => 'Notiz löschen';

  @override
  String get notesDeleteConfirm => 'Diese Notiz löschen?';

  @override
  String get notesOptional => 'Notiz (optional)';

  @override
  String get fieldRequired => 'Dieses Feld ist erforderlich';

  @override
  String get propagationTitle => 'Vermehrung';

  @override
  String get propagationActiveTab => 'Aktiv';

  @override
  String get propagationArchiveTab => 'Archiv';

  @override
  String get propagationEmptyActive => 'Keine aktiven Vermehrungen';

  @override
  String get propagationEmptyArchive => 'Archiv ist leer';

  @override
  String get propagationEmptyActiveHint =>
      'Charge von einer Pflanzenseite hinzufügen';

  @override
  String get propagationEmptyArchiveHint =>
      'Abgeschlossene Chargen werden 1 Jahr aufbewahrt';

  @override
  String get propagationAdd => 'Vermehrung hinzufügen';

  @override
  String get propagationChangeStage => 'Stadium ändern';

  @override
  String get propagationSell => 'Verkauft';

  @override
  String get propagationGift => 'Verschenkt';

  @override
  String get propagationTrade => 'Getauscht';

  @override
  String get propagationLose => 'Verloren';

  @override
  String get propagationInitialStage => 'Anfangsstadium';

  @override
  String propagationParentLabel(String name) {
    return 'Elternpflanze: $name';
  }

  @override
  String get propagationDetails => 'Vermehrungsdetails';

  @override
  String get propagationQuantity => 'Menge';

  @override
  String get propagationQuantityMin => 'Menge eingeben (mindestens 1)';

  @override
  String get propagationAliveNow => 'Jetzt lebend';

  @override
  String get propagationAliveRequired => 'Anzahl der Lebenden eingeben';

  @override
  String get propagationSellQuantityRequired => 'Verkaufsmenge eingeben';

  @override
  String get propagationGiftQuantityRequired => 'Menge eingeben';

  @override
  String get propagationTradeQuantityRequired => 'Menge eingeben';

  @override
  String get propagationLoseQuantityRequired => 'Menge eingeben';

  @override
  String propagationQuantityExceedsAlive(int count) {
    return 'Darf die Anzahl der Lebenden nicht überschreiten ($count)';
  }

  @override
  String propagationDate(String date) {
    return 'Datum: $date';
  }

  @override
  String propagationSinceDate(String date) {
    return 'seit $date';
  }

  @override
  String propagationSoldCount(int count) {
    return 'verkauft $count';
  }

  @override
  String propagationGiftedCount(int count) {
    return 'verschenkt $count';
  }

  @override
  String propagationTradedCount(int count) {
    return 'getauscht $count';
  }

  @override
  String propagationLostCount(int count) {
    return 'verloren $count';
  }

  @override
  String propagationSoldLabel(int count, String unit) {
    return 'Verkauft: $count $unit';
  }

  @override
  String propagationGiftedLabel(int count, String unit) {
    return 'Verschenkt: $count $unit';
  }

  @override
  String propagationTradedLabel(int count, String unit) {
    return 'Getauscht: $count $unit';
  }

  @override
  String propagationLostLabel(int count, String unit) {
    return 'Verloren: $count $unit';
  }

  @override
  String propagationStartedLabel(int batches, int quantity) {
    return 'Gestartet: $batches Chargen · $quantity Stk.';
  }

  @override
  String propagationStatsTitle(int year) {
    return 'Statistik $year';
  }

  @override
  String propagationByMethods(String methods) {
    return 'Nach Methoden: $methods';
  }

  @override
  String propagationByFamilies(String families) {
    return 'Nach Familien: $families';
  }

  @override
  String propagationQuantityPieces(int count) {
    return '$count Stk.';
  }

  @override
  String get propagationDeleteTitle => 'Vermehrung löschen';

  @override
  String get propagationDeleteConfirm =>
      'Die Vermehrungscharge und der gesamte Stufenverlauf werden unwiderruflich gelöscht. Fortfahren?';

  @override
  String get propagationDeleteHistoryEntry => 'Verlaufseintrag löschen?';

  @override
  String get propagationTimelineEmpty => 'Noch kein Stadiumsverlauf';

  @override
  String daysCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Tage',
      one: '1 Tag',
      zero: 'heute',
    );
    return '$_temp0';
  }

  @override
  String propagationAliveWithMethod(int count, String method) {
    return '$count $method';
  }

  @override
  String get propagationMethodLeaf => 'Blatt';

  @override
  String get propagationMethodLeafPlural => 'Blätter';

  @override
  String get propagationMethodLeafFragment => 'Blattfragment';

  @override
  String get propagationMethodLeafFragmentPlural => 'Blattfragmente';

  @override
  String get propagationMethodRhizome => 'Rhizom';

  @override
  String get propagationMethodRhizomePlural => 'Rhizome';

  @override
  String get propagationMethodTuber => 'Knolle';

  @override
  String get propagationMethodTuberPlural => 'Knollen';

  @override
  String get propagationMethodDivision => 'Teilung';

  @override
  String get propagationMethodDivisionPlural => 'Teilungen';

  @override
  String get propagationMethodOffset => 'Kindel';

  @override
  String get propagationMethodOffsetPlural => 'Kindel';

  @override
  String get propagationMethodCutting => 'Steckling';

  @override
  String get propagationMethodCuttingPlural => 'Stecklinge';

  @override
  String get propagationMethodMicrocloning => 'Mikroklonierung';

  @override
  String get propagationMethodMicrocloningPlural => 'Mikroklone';

  @override
  String get propagationStatusActive => 'Aktiv';

  @override
  String get propagationStatusSold => 'Verkauft';

  @override
  String get propagationStatusGifted => 'Verschenkt';

  @override
  String get propagationStatusTraded => 'Getauscht';

  @override
  String get propagationStatusLost => 'Verloren';

  @override
  String get propagationStartRooting => 'Zur Bewurzelung ansetzen';

  @override
  String get propagationMethodField => 'Methode';

  @override
  String propagationQuantityExceedsOriginal(int count) {
    return 'Nicht mehr als ursprünglich ($count)';
  }

  @override
  String propagationAliveWithPlant(int count, String plantName) {
    return '$count lebend · $plantName';
  }

  @override
  String get propagationSellQuantity => 'Verkaufsmenge';

  @override
  String get propagationGiftQuantity => 'Zu verschenkende Menge';

  @override
  String get propagationTradeQuantity => 'Zu tauschende Menge';

  @override
  String get propagationLoseQuantity => 'Verlorene Menge';

  @override
  String get propagationWriteOff => 'Abschreiben';

  @override
  String get propagationConfirmGift => 'Verschenken';

  @override
  String get propagationConfirmTrade => 'Tauschen';

  @override
  String get propagationTimeline => 'Zeitverlauf';

  @override
  String propagationSoldCountLabel(int count) {
    return 'Verkauft: $count';
  }

  @override
  String propagationGiftedCountLabel(int count) {
    return 'Verschenkt: $count';
  }

  @override
  String propagationTradedCountLabel(int count) {
    return 'Getauscht: $count';
  }

  @override
  String propagationLostCountLabel(int count) {
    return 'Verloren: $count';
  }

  @override
  String propagationOfTotal(int count) {
    return 'von $count';
  }

  @override
  String propagationDeleteStartStageBody(String stageName) {
    return 'Das Löschen der Stufe „$stageName“ entfernt unwiderruflich die gesamte Vermehrungscharge und alle anderen Stufen. Fortfahren?';
  }

  @override
  String get propagationDeleteStageEntryBody =>
      'Es wird nur dieser Stadieneintrag gelöscht. Die übrigen bleiben erhalten.';

  @override
  String get propagationDeleteLastEntryBody =>
      'Dies ist der letzte Verlaufseintrag. Die Vermehrungscharge wird unwiderruflich gelöscht. Fortfahren?';

  @override
  String get deleteEntryConfirm => 'Diesen Eintrag löschen?';

  @override
  String get promptEmptyNotAllowed => 'Wert darf nicht leer sein';

  @override
  String get repottingEmptySoils =>
      'Noch keine gespeicherten Substrate. Erstellen Sie eine neue Mischung.';

  @override
  String get repottingSoilTapHint =>
      'Tippen: +1 Teil · Langer Druck: ½ Teil (nochmal zum Entfernen)';

  @override
  String get repottingSlowReleaseSubtitle => 'Bei der Umtopfung hinzugefügt';

  @override
  String get repottingMixNameHint => 'z. B. Aroiden-Mix';

  @override
  String get fertilizerPurchasedAddTitle => 'Fertigdünger';

  @override
  String get fertilizerEditTitle => 'Dünger bearbeiten';

  @override
  String get fertilizerDeleteTitle => 'Dünger löschen';

  @override
  String get ingredientEditTitle => 'Inhaltsstoff bearbeiten';

  @override
  String get ingredientDeleteTitle => 'Inhaltsstoff löschen';

  @override
  String get componentEditTitle => 'Komponente bearbeiten';

  @override
  String get componentDeleteTitle => 'Komponente löschen';

  @override
  String get componentAddTitle => 'Komponente hinzufügen';

  @override
  String catalogItemDeleteConfirm(String name) {
    return '„$name“ aus dem Katalog entfernen?';
  }

  @override
  String get manageFertilizersHint =>
      'Mischungen werden unter „Neue Mischung“ gespeichert. Typ kann geändert werden: Fertigdünger ↔ Mischung.';

  @override
  String get fertilizerWaterForDilution => 'Wasser zum Anmischen';

  @override
  String fertilizerDoseOnWaterOptional(int waterMl) {
    return 'Dosis pro $waterMl ml (optional)';
  }

  @override
  String get fertilizerDoseOptional => 'Dosis (optional)';

  @override
  String get fertilizerKindSection => 'Art';

  @override
  String get soilComponentsTitle => 'Substratkomponenten';

  @override
  String get noComponents => 'Keine Komponenten';

  @override
  String get doseAmountRequired => 'Menge angeben';

  @override
  String get doseInvalidNumber => 'Ungültige Zahl';

  @override
  String get doseRemove => 'Entfernen';

  @override
  String get wishListTitle => 'WishLeafs';

  @override
  String get wishListAdd => 'Zur Wunschliste hinzufügen';

  @override
  String get wishListEdit => 'Pflanze bearbeiten';

  @override
  String get wishListEmpty => 'Wunschliste ist leer';

  @override
  String get wishListEmptyHint => 'Füge Pflanzen hinzu, die du kaufen möchtest';

  @override
  String get wishListNameEn => 'Name (Englisch)';

  @override
  String get wishListNameAlt => 'Anderer Name';

  @override
  String get wishListNameEnRequired => 'Englischen Namen angeben';

  @override
  String get wishListNameAltRequired => 'Anderen Namen angeben';

  @override
  String get wishListBought => 'Gekauft';

  @override
  String get wishListExchanged => 'Getauscht';

  @override
  String get wishListAcquireTitle => 'Wie hast du sie bekommen?';

  @override
  String get wishListExchangeNoFinanceHint =>
      'Tausch wird nicht in den Finanzen erfasst. Als Nächstes kannst du die Pflanze zur Sammlung hinzufügen.';

  @override
  String get wishListSelectForTrade => 'Pflanze von der Wunschliste';

  @override
  String get wishListSelectForTradeHint =>
      'Wähle die Pflanze, die du im Tausch erhalten hast. Es wird kein Finanzeintrag erstellt.';

  @override
  String get wishListAcquireContinue => 'Weiter';

  @override
  String get wishListExport => 'Exportieren';

  @override
  String get wishListExportEmpty => 'Nichts zu exportieren';

  @override
  String wishListDeleteConfirm(String name) {
    return '„$name“ von der Wunschliste entfernen?';
  }

  @override
  String get financesTitle => 'Finanzen';

  @override
  String get financesAdd => 'Eintrag hinzufügen';

  @override
  String get financesEdit => 'Eintrag bearbeiten';

  @override
  String get financesEmpty => 'Noch keine Finanzeinträge';

  @override
  String get financesEmptyHint =>
      'Erfasse Einnahmen aus Verkäufen und Ausgaben für Pflanzen';

  @override
  String get financesIncome => 'Einnahmen';

  @override
  String get financesExpense => 'Ausgaben';

  @override
  String get financesBalance => 'Saldo';

  @override
  String get financesAnalyticsTitle => 'Letzte 3 Monate';

  @override
  String get financesNoIncome => 'Noch keine Einnahmen';

  @override
  String get financesNoExpense => 'Noch keine Ausgaben';

  @override
  String get financesTitleLabel => 'Bezeichnung';

  @override
  String get financesTitleRequired => 'Bezeichnung angeben';

  @override
  String financesAmountLabel(String symbol) {
    return 'Betrag ($symbol)';
  }

  @override
  String get financesAmountRequired => 'Gültigen Betrag angeben';

  @override
  String financesDeleteConfirm(String title) {
    return '„$title“ löschen?';
  }

  @override
  String get financesAlsoAddToCatalog => 'Auch zum Katalog hinzufügen';

  @override
  String get financesAsSoilComponent => 'Substratkomponente';

  @override
  String get financesAsFertilizer => 'Dünger';

  @override
  String get financesAsPurchasedFertilizer => 'Fertiges Düngemittel';

  @override
  String get financesAsReadyMadeSoil => 'Fertige Substratmischung';

  @override
  String financesPropagationSaleTitle(String plantName, int quantity) {
    return 'Verkauf: $plantName ×$quantity';
  }

  @override
  String financesPlantSaleTitle(String plantName) {
    return 'Pflanzenverkauf: $plantName';
  }

  @override
  String get propagationTradeForWishList => 'Für Wunschlisten-Pflanze';

  @override
  String get commonContinue => 'Weiter';

  @override
  String get commonSkip => 'Überspringen';

  @override
  String get plantMergeTitle => 'Zu einer Gruppe zusammenführen';

  @override
  String plantMergeMemberLabel(int index) {
    return 'Sorte $index';
  }

  @override
  String get plantMergeMembersRequired => 'Geben Sie mindestens zwei Sorten an';

  @override
  String get plantGroupMembers => 'Sorten in der Gruppe';

  @override
  String plantCultivarsLabel(String cultivars) {
    return 'Sorten: $cultivars';
  }

  @override
  String get plantArchiveTitle => 'Pflanzenarchiv';

  @override
  String get plantArchiveEmpty => 'Archiv ist leer';

  @override
  String get plantArchiveEmptyHint => 'Pflanzen bleiben 2 Jahre im Archiv';

  @override
  String get plantArchiveReasonMerged => 'Zusammengeführt';

  @override
  String get plantArchiveReasonDied => 'Abgestorben';

  @override
  String get plantArchiveReasonSold => 'Verkauft';

  @override
  String plantArchiveDate(String date) {
    return 'Archiviert am $date';
  }

  @override
  String plantArchiveNoteLabel(String note) {
    return 'Grund: $note';
  }

  @override
  String get plantDispose => 'Aus der Sammlung entfernen';

  @override
  String get plantDisposeTitle => 'Pflanze entfernen';

  @override
  String get plantDisposeReasonDied => 'Abgestorben';

  @override
  String get plantDisposeReasonSold => 'Verkauft';

  @override
  String get plantDisposeDeathNote => 'Ursachenbeschreibung';

  @override
  String get plantDisposeDeathNoteRequired =>
      'Beschreiben Sie die Todesursache';

  @override
  String get plantDisposeSaleAmount => 'Verkaufsbetrag';

  @override
  String get plantDisposeConfirm => 'Ins Archiv';

  @override
  String get plantDisposeArchived => 'Pflanze ins Archiv verschoben';
}
