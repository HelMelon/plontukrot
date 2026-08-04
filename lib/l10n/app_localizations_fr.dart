// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appName => 'SKÖRD';

  @override
  String get brandTagline =>
      'Un journal de la lutte pour la lumière et l’humidité. Les germes ne sont pas une garantie. Seule l’observation.';

  @override
  String get commonCancel => 'Annuler';

  @override
  String get commonSave => 'Enregistrer';

  @override
  String get commonDelete => 'Supprimer';

  @override
  String get commonEdit => 'Modifier';

  @override
  String get commonAdd => 'Ajouter';

  @override
  String get commonClose => 'Fermer';

  @override
  String get commonMore => 'Plus';

  @override
  String get commonToday => 'Aujourd’hui';

  @override
  String commonError(String error) {
    return 'Erreur : $error';
  }

  @override
  String get commonShowMore => 'Afficher plus';

  @override
  String get commonLoadMore => 'Charger plus';

  @override
  String get commonCollapse => 'Réduire';

  @override
  String get commonManage => 'Gérer';

  @override
  String get commonOk => 'OK';

  @override
  String get commonNoDate => 'Sans date';

  @override
  String get commonNoData => 'Aucune donnée';

  @override
  String get commonUntitled => 'Sans titre';

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
  String get milliliters => 'Millilitres';

  @override
  String get grams => 'Grammes';

  @override
  String get loading => 'Chargement…';

  @override
  String get preparing => 'Préparation…';

  @override
  String get authSignInGoogle => 'Se connecter avec Google';

  @override
  String get authSigningIn => 'Connexion…';

  @override
  String authSignInError(String error) {
    return 'Erreur de connexion : $error';
  }

  @override
  String get authGoogleIdTokenMissing =>
      'Google n’a pas renvoyé de jeton d’identité.';

  @override
  String get authSignOut => 'Se déconnecter';

  @override
  String get settingsTitle => 'Paramètres';

  @override
  String get settingsLanguage => 'Langue';

  @override
  String get settingsLanguageSystem => 'Langue du système';

  @override
  String get settingsLanguageEnglish => 'English';

  @override
  String get settingsLanguageRussian => 'Русский';

  @override
  String get settingsLanguageGerman => 'Deutsch';

  @override
  String get settingsLanguageFrench => 'Français';

  @override
  String get homeSearchHint => 'Rechercher des plantes…';

  @override
  String get homeNoUserData => 'Aucune donnée utilisateur';

  @override
  String get homeNoPlantsYet => 'Aucune plante ajoutée pour le moment';

  @override
  String get homeNoPropagatingPlants =>
      'Aucune plante en multiplication active';

  @override
  String get homeNoPlantsForFilter =>
      'Aucune plante ne correspond au filtre sélectionné';

  @override
  String get homeAllFamilies => 'Toutes les familles';

  @override
  String get homeAllGenera => 'Tous les genres';

  @override
  String get homeAllStages => 'Tous les stades';

  @override
  String get homeNoFamily => 'Sans famille';

  @override
  String get homePropagation => 'Multiplication';

  @override
  String get homeSort => 'Trier';

  @override
  String get homeSortSpecies => 'Espèce';

  @override
  String get homeSortNickname => 'Surnom';

  @override
  String get homeSortWatering => 'Arrosage';

  @override
  String get homeSortFertilizing => 'Fertilisation';

  @override
  String get homeSortDate => 'Date';

  @override
  String get homeSortFamily => 'Famille';

  @override
  String get homeSortLastWatered => 'Dernier arrosage';

  @override
  String get homeSortLastFertilized => 'Dernière fertilisation';

  @override
  String get homeSortDateAdded => 'Date d’ajout';

  @override
  String homeSelectedCount(int count) {
    return 'Sélectionné : $count';
  }

  @override
  String get homeSelectAll => 'Tout sélectionner';

  @override
  String get homeClearSelection => 'Effacer la sélection';

  @override
  String get homeWatering => 'Arrosage';

  @override
  String get homeFertilizing => 'Fertilisation';

  @override
  String get homeUpdateFamily => 'Modifier la famille';

  @override
  String get homeUpdateFamilyTitle => 'Modifier la famille';

  @override
  String get homeFamilyLabel => 'Famille';

  @override
  String get homeFertilizeSelectedTitle =>
      'Fertiliser les plantes sélectionnées';

  @override
  String get homeDeleteSelectedTitle => 'Supprimer les plantes sélectionnées ?';

  @override
  String homeDeleteSelectedBody(int count) {
    return 'Cela supprimera définitivement $count plante(s).';
  }

  @override
  String homeDeleteSelectedBodyPlural(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Cela supprimera définitivement $count plantes.',
      one: 'Cela supprimera définitivement 1 plante.',
    );
    return '$_temp0';
  }

  @override
  String get searchNoPlantsInJournal => 'Aucune plante dans le journal';

  @override
  String get searchNothingFound => 'Aucun résultat';

  @override
  String get plantAdd => 'Ajouter une plante';

  @override
  String get plantEdit => 'Modifier la plante';

  @override
  String get plantSaveChanges => 'Enregistrer les modifications';

  @override
  String get plantGenus => 'Genre';

  @override
  String get plantSpecies => 'Espèce';

  @override
  String get plantCultivar => 'Cultivar';

  @override
  String get plantTradingName => 'Nom commercial';

  @override
  String get plantFamily => 'Famille';

  @override
  String get plantNickname => 'Surnom';

  @override
  String get plantWateringFrequency => 'Fréquence d’arrosage';

  @override
  String get plantGrowthStage => 'Stade de croissance';

  @override
  String get plantGenusRequired => 'Indiquez le genre de la plante';

  @override
  String get plantSpeciesRequired => 'Indiquez l’espèce de la plante';

  @override
  String get plantInvalidWateringFrequency => 'Fréquence d’arrosage invalide';

  @override
  String get plantUntitled => 'Sans titre';

  @override
  String get plantDefaultTitle => 'Plante';

  @override
  String get plantGenusFallback => 'Genre';

  @override
  String plantSpeciesLabel(String species) {
    return 'Espèce : $species';
  }

  @override
  String plantCultivarLabel(String cultivar) {
    return 'Cultivar : $cultivar';
  }

  @override
  String plantStageLabel(String stage) {
    return 'Stade : $stage';
  }

  @override
  String get plantFamilyLabel => 'Famille';

  @override
  String get plantTradingNameLabel => 'Nom commercial';

  @override
  String get plantGenusPrefix => 'Genre : ';

  @override
  String plantVariegationLabel(String value) {
    return 'Variegation : $value';
  }

  @override
  String get plantBotanicalData => 'Données botaniques';

  @override
  String get plantJournal => 'Journal';

  @override
  String get plantGallery => 'Galerie';

  @override
  String get plantCamera => 'Appareil photo';

  @override
  String plantUploadError(String error) {
    return 'Erreur de téléversement : $error';
  }

  @override
  String get plantEmptyStage =>
      'Aucune plante de ce stade dans la collection pour le moment';

  @override
  String get plantEmptyGenus =>
      'Aucune plante de ce genre dans la collection pour le moment';

  @override
  String get plantNote => 'Note';

  @override
  String get plantPropagation => 'Multiplication';

  @override
  String get stageUnknown => '🌱 Inconnu';

  @override
  String get stageStart => '🌱 Début';

  @override
  String get stageBaby => '🌿 Bébé';

  @override
  String get stageJuvenile => '🌳 Juvénile';

  @override
  String get stageAdult => '🌴 Adulte';

  @override
  String get stageDescriptionTitle => 'Description du stade';

  @override
  String get stageStartCheck1 => 'Tubercule sans racines';

  @override
  String get stageStartCheck2 => 'Feuille avec un petit rhizome';

  @override
  String get stageStartCheck3 => 'Bouture capable de s’enraciner';

  @override
  String get stageStartCheck4 => 'La plante commence juste à croître';

  @override
  String get stageBabyCheck1 => '1–2 vraies feuilles';

  @override
  String get stageBabyCheck2 => 'Système racinaire encore en formation';

  @override
  String get stageBabyCheck3 => 'Croissance autonome';

  @override
  String get stageJuvenileCheck1 => '3–5 feuilles';

  @override
  String get stageJuvenileCheck2 => 'Bon système racinaire';

  @override
  String get stageJuvenileCheck3 => 'Croissance active';

  @override
  String get stageAdultCheck1 => 'Plante pleinement formée';

  @override
  String get stageAdultCheck2 => 'Produit régulièrement de nouvelles feuilles';

  @override
  String get stageAdultCheck3 => 'Peut être divisée ou bouturée';

  @override
  String get variegationLabel => 'Variegation';

  @override
  String get variegationNone => 'Aucune';

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
  String get variegationUnknown => 'Inconnu';

  @override
  String get watering => 'Arrosage';

  @override
  String get wateringHistory => 'Historique d’arrosage';

  @override
  String get wateringAdd => 'Ajouter un arrosage';

  @override
  String get wateringEdit => 'Modifier l’arrosage';

  @override
  String get wateringDeleteTitle => 'Supprimer l’arrosage';

  @override
  String get wateringDeleteConfirm => 'Supprimer cette entrée ?';

  @override
  String get wateringEmpty => 'Aucun arrosage pour le moment';

  @override
  String get fertilizing => 'Fertilisation';

  @override
  String get fertilizingHistory => 'Historique de fertilisation';

  @override
  String get fertilizingAdd => 'Ajouter une fertilisation';

  @override
  String get fertilizingEdit => 'Modifier la fertilisation';

  @override
  String get fertilizingDeleteTitle => 'Supprimer la fertilisation';

  @override
  String get fertilizingDeleteConfirm => 'Supprimer cette entrée ?';

  @override
  String get fertilizingEmpty => 'Aucune fertilisation pour le moment';

  @override
  String get fertilizingSelectedTitle => 'Fertiliser les plantes sélectionnées';

  @override
  String get fertilizingApplicationMethod => 'Mode d’application';

  @override
  String get fertilizingRoot => 'Racinaire';

  @override
  String get fertilizingFoliar => 'Foliaire';

  @override
  String get fertilizingSaved => 'Enregistré';

  @override
  String get fertilizingNewMix => 'Nouveau mélange';

  @override
  String get fertilizingCatalog => 'Catalogue';

  @override
  String get fertilizingEmptyCatalog =>
      'Aucun engrais pour le moment. Ajoutez un produit prêt ou enregistrez un mélange.';

  @override
  String get fertilizingGoToNewMix => 'Aller à « Nouveau mélange »';

  @override
  String get fertilizingSelectFertilizer => 'Sélectionner un engrais';

  @override
  String get fertilizingViewComposition => 'Voir la composition';

  @override
  String fertilizingMixWaterVolume(int value) {
    return 'Volume d’eau du mélange : $value ml';
  }

  @override
  String get fertilizingIngredients => 'Ingrédients';

  @override
  String get fertilizingTapIngredientHint =>
      'Appuyez sur un ingrédient pour définir la quantité (g ou ml)';

  @override
  String get fertilizingSaveThisMix => 'Enregistrer ce mélange';

  @override
  String get fertilizingMixName => 'Nom du mélange';

  @override
  String get fertilizingMixNameHint => 'ex. Formule de croissance';

  @override
  String get fertilizingWaterVolume => 'Volume d’eau';

  @override
  String get fertilizingAddIngredient => 'Ajouter un ingrédient';

  @override
  String get fertilizingIngredientNameHint => 'Nom de l’ingrédient';

  @override
  String get fertilizerFallbackName => 'Engrais';

  @override
  String get fertilizerKindMix => 'Mélange';

  @override
  String get fertilizerKindPurchased => 'Prêt à l’emploi';

  @override
  String get fertilizerCustomMix => 'Mélange perso';

  @override
  String get fertilizerUnknown => 'Inconnu';

  @override
  String get fertilizerInvalidDose => 'Dose invalide';

  @override
  String get fertilizerNameLabel => 'Nom';

  @override
  String get fertilizerNameHint => 'ex. Pokon Universel';

  @override
  String get fertilizerDoseLabelPurchased => 'Dose';

  @override
  String get fertilizerDoseLabelMix => 'Quantité';

  @override
  String get fertilizerDoseHint => 'ex. 2';

  @override
  String fertilizerMixComposition(String components) {
    return 'Composition du mélange : $components';
  }

  @override
  String fertilizerWithMeta(String name, String kind, int waterMl) {
    return '$name · $kind · $waterMl ml';
  }

  @override
  String fertilizerWaterLine(int value) {
    return 'Eau : $value ml';
  }

  @override
  String get manageFertilizersTitle => 'Gérer les engrais';

  @override
  String get manageFertilizerIngredientsTitle => 'Gérer les ingrédients';

  @override
  String get manageComponentsTitle => 'Gérer les composants';

  @override
  String get componentNameHint => 'Nom du composant';

  @override
  String get emptyFertilizers => 'Aucun engrais pour le moment';

  @override
  String get emptyIngredients => 'Aucun ingrédient pour le moment';

  @override
  String get emptyComponents => 'Aucun composant pour le moment';

  @override
  String get emptyComposition => 'La composition est vide';

  @override
  String get repotting => 'Rempotage';

  @override
  String get repottingHistory => 'Historique de rempotage';

  @override
  String get repottingAdd => 'Ajouter un rempotage';

  @override
  String get repottingEdit => 'Modifier le rempotage';

  @override
  String get repottingDeleteTitle => 'Supprimer le rempotage';

  @override
  String get repottingDeleteConfirm => 'Supprimer cette entrée ?';

  @override
  String get repottingEmpty => 'Aucun rempotage pour le moment';

  @override
  String get repottingSlowRelease => 'Engrais à libération lente';

  @override
  String get repottingSelectSoil => 'Sélectionner un substrat';

  @override
  String get repottingSoilFallback => 'Substrat';

  @override
  String get repottingSoilComposition => 'Composition du substrat';

  @override
  String get soilCustomMix => 'Mélange perso';

  @override
  String soilParts(String parts) {
    return '$parts parts';
  }

  @override
  String get notesEmpty => 'Aucune note pour le moment';

  @override
  String get notesAdd => 'Ajouter une note';

  @override
  String get notesAddHint =>
      'Ajoutez une nouvelle entrée de journal pour cette plante.';

  @override
  String get notesEdit => 'Modifier la note';

  @override
  String get notesLabel => 'Entrée de journal';

  @override
  String get notesEditLabel => 'Modifier la note';

  @override
  String get notesCannotBeEmpty => 'La note ne peut pas être vide';

  @override
  String get notesDeleteTitle => 'Supprimer la note';

  @override
  String get notesDeleteConfirm => 'Supprimer cette note ?';

  @override
  String get notesOptional => 'Note (facultatif)';

  @override
  String get fieldRequired => 'Ce champ est obligatoire';

  @override
  String get propagationTitle => 'Multiplication';

  @override
  String get propagationActiveTab => 'Actives';

  @override
  String get propagationArchiveTab => 'Archives';

  @override
  String get propagationEmptyActive => 'Aucune multiplication active';

  @override
  String get propagationEmptyArchive => 'Les archives sont vides';

  @override
  String get propagationEmptyActiveHint =>
      'Ajoutez un lot depuis la page d’une plante';

  @override
  String get propagationEmptyArchiveHint =>
      'Les lots terminés sont conservés 1 an';

  @override
  String get propagationAdd => 'Ajouter une multiplication';

  @override
  String get propagationChangeStage => 'Changer de stade';

  @override
  String get propagationSell => 'Vendue';

  @override
  String get propagationGift => 'Offerte';

  @override
  String get propagationTrade => 'Échangée';

  @override
  String get propagationLose => 'Perdues';

  @override
  String get propagationInitialStage => 'Stade initial';

  @override
  String propagationParentLabel(String name) {
    return 'Parent : $name';
  }

  @override
  String get propagationDetails => 'Détails de la multiplication';

  @override
  String get propagationQuantity => 'Quantité';

  @override
  String get propagationQuantityMin => 'Indiquez une quantité (minimum 1)';

  @override
  String get propagationAliveNow => 'Vivants maintenant';

  @override
  String get propagationAliveRequired => 'Indiquez le nombre de vivants';

  @override
  String get propagationSellQuantityRequired =>
      'Indiquez une quantité à vendre';

  @override
  String get propagationGiftQuantityRequired => 'Indiquez une quantité';

  @override
  String get propagationTradeQuantityRequired => 'Indiquez une quantité';

  @override
  String get propagationLoseQuantityRequired => 'Indiquez une quantité';

  @override
  String propagationQuantityExceedsAlive(int count) {
    return 'Ne peut pas dépasser le nombre de vivants ($count)';
  }

  @override
  String propagationDate(String date) {
    return 'Date : $date';
  }

  @override
  String propagationSinceDate(String date) {
    return 'depuis $date';
  }

  @override
  String propagationSoldCount(int count) {
    return 'vendu $count';
  }

  @override
  String propagationGiftedCount(int count) {
    return 'offert $count';
  }

  @override
  String propagationTradedCount(int count) {
    return 'échangé $count';
  }

  @override
  String propagationLostCount(int count) {
    return 'perdu $count';
  }

  @override
  String propagationSoldLabel(int count, String unit) {
    return 'Vendu : $count $unit';
  }

  @override
  String propagationGiftedLabel(int count, String unit) {
    return 'Offert : $count $unit';
  }

  @override
  String propagationTradedLabel(int count, String unit) {
    return 'Échangé : $count $unit';
  }

  @override
  String propagationLostLabel(int count, String unit) {
    return 'Perdu : $count $unit';
  }

  @override
  String propagationStartedLabel(int batches, int quantity) {
    return 'Lancé : $batches lots · $quantity pcs';
  }

  @override
  String propagationStatsTitle(int year) {
    return 'Statistiques $year';
  }

  @override
  String propagationByMethods(String methods) {
    return 'Par méthodes : $methods';
  }

  @override
  String propagationByFamilies(String families) {
    return 'Par familles : $families';
  }

  @override
  String propagationQuantityPieces(int count) {
    return '$count pcs';
  }

  @override
  String get propagationDeleteTitle => 'Supprimer la multiplication';

  @override
  String get propagationDeleteConfirm => 'Supprimer ce lot de multiplication ?';

  @override
  String get propagationDeleteHistoryEntry =>
      'Supprimer l’entrée d’historique ?';

  @override
  String get propagationTimelineEmpty =>
      'Aucun historique de stades pour le moment';

  @override
  String daysCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jours',
      one: '1 jour',
      zero: 'aujourd’hui',
    );
    return '$_temp0';
  }

  @override
  String propagationAliveWithMethod(int count, String method) {
    return '$count $method';
  }

  @override
  String get propagationMethodLeaf => 'Feuille';

  @override
  String get propagationMethodLeafPlural => 'feuilles';

  @override
  String get propagationMethodLeafFragment => 'Fragment de feuille';

  @override
  String get propagationMethodLeafFragmentPlural => 'fragments de feuille';

  @override
  String get propagationMethodRhizome => 'Rhizome';

  @override
  String get propagationMethodRhizomePlural => 'rhizomes';

  @override
  String get propagationMethodTuber => 'Tubercule';

  @override
  String get propagationMethodTuberPlural => 'tubercules';

  @override
  String get propagationMethodDivision => 'Division';

  @override
  String get propagationMethodDivisionPlural => 'divisions';

  @override
  String get propagationMethodOffset => 'Rejet';

  @override
  String get propagationMethodOffsetPlural => 'rejets';

  @override
  String get propagationMethodCutting => 'Bouture';

  @override
  String get propagationMethodCuttingPlural => 'boutures';

  @override
  String get propagationStatusActive => 'Active';

  @override
  String get propagationStatusSold => 'Vendu';

  @override
  String get propagationStatusGifted => 'Offert';

  @override
  String get propagationStatusTraded => 'Échangé';

  @override
  String get propagationStatusLost => 'Perdu';

  @override
  String get propagationStartRooting => 'Mettre en enracinement';

  @override
  String get propagationMethodField => 'Méthode';

  @override
  String propagationQuantityExceedsOriginal(int count) {
    return 'Ne peut pas dépasser la quantité initiale ($count)';
  }

  @override
  String propagationAliveWithPlant(int count, String plantName) {
    return '$count vivants · $plantName';
  }

  @override
  String get propagationSellQuantity => 'Quantité à vendre';

  @override
  String get propagationGiftQuantity => 'Quantité à offrir';

  @override
  String get propagationTradeQuantity => 'Quantité à échanger';

  @override
  String get propagationLoseQuantity => 'Quantité perdue';

  @override
  String get propagationWriteOff => 'Radier';

  @override
  String get propagationConfirmGift => 'Offrir';

  @override
  String get propagationConfirmTrade => 'Échanger';

  @override
  String get propagationTimeline => 'Chronologie';

  @override
  String propagationSoldCountLabel(int count) {
    return 'Vendu : $count';
  }

  @override
  String propagationGiftedCountLabel(int count) {
    return 'Offert : $count';
  }

  @override
  String propagationTradedCountLabel(int count) {
    return 'Échangé : $count';
  }

  @override
  String propagationLostCountLabel(int count) {
    return 'Perdu : $count';
  }

  @override
  String propagationOfTotal(int count) {
    return 'sur $count';
  }

  @override
  String propagationDeleteStartStageBody(String stageName) {
    return 'Supprimer le stade « $stageName » supprimera tout le lot de multiplication et les autres stades.';
  }

  @override
  String get propagationDeleteStageEntryBody =>
      'Seule cette entrée de stade sera supprimée. Les autres resteront.';

  @override
  String get deleteEntryConfirm => 'Supprimer cette entrée ?';

  @override
  String get promptEmptyNotAllowed => 'La valeur ne peut pas être vide';

  @override
  String get repottingEmptySoils =>
      'Aucun substrat enregistré. Créez un nouveau mélange.';

  @override
  String get repottingSoilTapHint =>
      'Appui : +1 part · Appui long : ½ part (encore pour retirer)';

  @override
  String get repottingSlowReleaseSubtitle => 'Ajouté lors du rempotage';

  @override
  String get repottingMixNameHint => 'p. ex. Mélange pour aroïdes';

  @override
  String get fertilizerPurchasedAddTitle => 'Engrais prêt à l\'emploi';

  @override
  String get fertilizerEditTitle => 'Modifier l\'engrais';

  @override
  String get fertilizerDeleteTitle => 'Supprimer l\'engrais';

  @override
  String get ingredientEditTitle => 'Modifier l\'ingrédient';

  @override
  String get ingredientDeleteTitle => 'Supprimer l\'ingrédient';

  @override
  String get componentEditTitle => 'Modifier le composant';

  @override
  String get componentDeleteTitle => 'Supprimer le composant';

  @override
  String get componentAddTitle => 'Ajouter un composant';

  @override
  String catalogItemDeleteConfirm(String name) {
    return 'Retirer « $name » du catalogue ?';
  }

  @override
  String get manageFertilizersHint =>
      'Les mélanges sont enregistrés depuis « Nouveau mélange ». Le type peut être modifié : prêt à l\'emploi ↔ mélange.';

  @override
  String get fertilizerWaterForDilution => 'Eau de dilution';

  @override
  String fertilizerDoseOnWaterOptional(int waterMl) {
    return 'Dose pour $waterMl ml (facultatif)';
  }

  @override
  String get fertilizerDoseOptional => 'Dose (facultatif)';

  @override
  String get fertilizerKindSection => 'Type';

  @override
  String get soilComponentsTitle => 'Composants du substrat';

  @override
  String get noComponents => 'Aucun composant';

  @override
  String get doseAmountRequired => 'Indiquez une quantité';

  @override
  String get doseInvalidNumber => 'Nombre invalide';

  @override
  String get doseRemove => 'Retirer';
}
