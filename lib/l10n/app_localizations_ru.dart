// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appName => 'SKÖRD';

  @override
  String get brandTagline =>
      'Журнал борьбы за свет и влагу. Всходы — не гарантия. Только наблюдение.';

  @override
  String get commonCancel => 'Отмена';

  @override
  String get commonSave => 'Сохранить';

  @override
  String get commonDelete => 'Удалить';

  @override
  String get commonEdit => 'Редактировать';

  @override
  String get commonAdd => 'Добавить';

  @override
  String get commonClose => 'Закрыть';

  @override
  String get commonMore => 'Ещё';

  @override
  String get commonToday => 'Сегодня';

  @override
  String commonError(String error) {
    return 'Ошибка: $error';
  }

  @override
  String get commonShowMore => 'Показать ещё';

  @override
  String get commonLoadMore => 'Загрузить ещё';

  @override
  String get commonCollapse => 'Свернуть';

  @override
  String get commonManage => 'Управление';

  @override
  String get commonOk => 'OK';

  @override
  String get commonNoDate => 'Без даты';

  @override
  String get commonNoData => 'Нет данных';

  @override
  String get commonUntitled => 'Без названия';

  @override
  String get commonComposition => 'Состав';

  @override
  String get unitMl => 'мл';

  @override
  String get unitGrams => 'г';

  @override
  String get unitPiecesShort => 'шт';

  @override
  String unitMlWithValue(int value) {
    return '$value мл';
  }

  @override
  String get milliliters => 'Миллилитры';

  @override
  String get grams => 'Граммы';

  @override
  String get loading => 'Загрузка…';

  @override
  String get preparing => 'Подготовка…';

  @override
  String get authSignInGoogle => 'Войти через Google';

  @override
  String get authSigningIn => 'Вход…';

  @override
  String authSignInError(String error) {
    return 'Ошибка входа: $error';
  }

  @override
  String get authSignInNetworkError =>
      'Нет соединения с интернетом. Проверьте сеть и попробуйте снова.';

  @override
  String get authSignInFailed => 'Не удалось войти. Попробуйте ещё раз.';

  @override
  String get authGoogleIdTokenMissing => 'Google не вернул ID-токен.';

  @override
  String get authSignOut => 'Выйти';

  @override
  String get authConsentLabel =>
      'Согласен(на) на обработку персональных данных';

  @override
  String get privacyPolicyLink => 'Политика конфиденциальности';

  @override
  String get authConsentGateTitle => 'Согласие на обработку данных';

  @override
  String get authConsentGateBody =>
      'Чтобы продолжить пользоваться приложением, примите Политику конфиденциальности.';

  @override
  String get authConsentContinue => 'Продолжить';

  @override
  String get profileTitle => 'Профиль';

  @override
  String get profileEmDash => '—';

  @override
  String get profilePlantCount => 'Растений';

  @override
  String get profileFavoriteFamily => 'Любимое семейство';

  @override
  String get profileFavoriteGenus => 'Любимый род';

  @override
  String get profileActivePropagations => 'На размножении';

  @override
  String get profileConsentAccepted =>
      'Согласие на обработку персональных данных получено';

  @override
  String get profileDeleteAccount => 'Удалить профиль';

  @override
  String get profileDeleteAccountConfirmTitle => 'Удалить профиль?';

  @override
  String get profileDeleteAccountConfirmBody =>
      'Аккаунт, растения, фото и все связанные данные будут удалены безвозвратно.';

  @override
  String get profileDeleteAccountConfirmAction => 'Удалить навсегда';

  @override
  String get profileDeletingAccount => 'Удаление профиля…';

  @override
  String profileDeleteAccountError(String error) {
    return 'Не удалось удалить профиль: $error';
  }

  @override
  String get profileDeleteAccountFailed =>
      'Не удалось удалить профиль. Попробуйте ещё раз.';

  @override
  String get profileFriends => 'Друзья';

  @override
  String get profileMyUid => 'Ваш ID';

  @override
  String get profileCopyUid => 'Копировать ID';

  @override
  String get profileUidCopied => 'ID скопирован';

  @override
  String get profileCollectionVisibility => 'Видимость коллекции';

  @override
  String get profileCollectionFriends => 'Видна друзьям';

  @override
  String get profileCollectionPrivate => 'Приватная';

  @override
  String get friendsTitle => 'Друзья';

  @override
  String get friendsEmpty => 'Пока нет друзей';

  @override
  String get friendsUnknownName => 'Друг';

  @override
  String get friendsAddTitle => 'Добавить друга';

  @override
  String get friendsAddHint => 'ID пользователя';

  @override
  String get friendsAddAction => 'Отправить заявку';

  @override
  String get friendsIncoming => 'Входящие заявки';

  @override
  String get friendsOutgoing => 'Исходящие заявки';

  @override
  String get friendsAccept => 'Принять';

  @override
  String get friendsDecline => 'Отклонить';

  @override
  String get friendsCancelRequest => 'Отменить';

  @override
  String get friendsRemove => 'Удалить из друзей';

  @override
  String friendsRemoveConfirm(String name) {
    return 'Удалить $name из друзей?';
  }

  @override
  String get friendsRequestSent => 'Заявка отправлена';

  @override
  String get friendsOpenCollection => 'Коллекция';

  @override
  String get friendsOpenWishList => 'WishLeafs';

  @override
  String get friendsGiftsInbox => 'Подарки растений';

  @override
  String friendsGiftFrom(String name) {
    return 'От $name';
  }

  @override
  String get friendsGiftAccept => 'Принять подарок';

  @override
  String get friendsGiftDecline => 'Отклонить';

  @override
  String get friendsGiftAccepted => 'Растение добавлено в коллекцию';

  @override
  String get friendsGiftEmpty => 'Нет ожидающих подарков';

  @override
  String friendsCollectionTitle(String name) {
    return '$name';
  }

  @override
  String get friendsCollectionEmpty => 'Нет растений';

  @override
  String get friendsCollectionPrivate => 'Коллекция скрыта';

  @override
  String friendsWishListTitle(String name) {
    return 'WishLeafs — $name';
  }

  @override
  String get friendsWishListEmpty => 'Список желаний пуст';

  @override
  String get friendsWishListPrivate => 'Список желаний скрыт';

  @override
  String get friendsWishListLoadError => 'Не удалось загрузить список желаний';

  @override
  String get friendsReadOnly => 'Только просмотр';

  @override
  String get plantGift => 'Подарить';

  @override
  String get plantGiftTitle => 'Подарок другу';

  @override
  String get plantGiftPickFriend => 'Выберите друга';

  @override
  String get plantGiftNoFriends => 'Сначала добавьте друзей';

  @override
  String get plantGiftConfirm => 'Отправить подарок';

  @override
  String get plantGiftSent =>
      'Подарок отправлен — растение уйдёт из коллекции после принятия';

  @override
  String get plantGiftMessageHint => 'Сообщение (необязательно)';

  @override
  String get plantArchiveReasonGifted => 'Подарено';

  @override
  String get settingsTitle => 'Настройки';

  @override
  String get settingsLanguage => 'Язык';

  @override
  String get settingsLanguageSystem => 'Системный';

  @override
  String get settingsLanguageEnglish => 'English';

  @override
  String get settingsLanguageRussian => 'Русский';

  @override
  String get settingsLanguageGerman => 'Deutsch';

  @override
  String get settingsLanguageFrench => 'Français';

  @override
  String get settingsCurrency => 'Валюта';

  @override
  String get settingsCurrencyUsd => 'Доллар США';

  @override
  String get settingsCurrencyEur => 'Евро';

  @override
  String get settingsCurrencyRub => 'Российский рубль';

  @override
  String get settingsCurrencyByn => 'Белорусский рубль';

  @override
  String get homeSearchHint => 'Поиск растений…';

  @override
  String get homeNoUserData => 'Нет данных пользователя';

  @override
  String get homeNoPlantsYet => 'Растения ещё не добавлены';

  @override
  String get homeNoPropagatingPlants => 'Нет растений с активным размножением';

  @override
  String get homeNoGroupPlants => 'Нет объединённых групп';

  @override
  String get homeNoPlantsForFilter => 'Нет растений по выбранному фильтру';

  @override
  String get homeAllFamilies => 'Все семейства';

  @override
  String get homeAllGenera => 'Все роды';

  @override
  String get homeAllStages => 'Все стадии';

  @override
  String get homeNoFamily => 'Без семейства';

  @override
  String get homePropagation => 'Размножение';

  @override
  String get homeGroups => 'Группы';

  @override
  String get homeArchive => 'Архив';

  @override
  String get homeMerge => 'Объединить';

  @override
  String get homeMergeNeedCount => 'Выберите от 2 до 3 растений';

  @override
  String get homeMergeNeedSameGenus => 'Для объединения нужен одинаковый род';

  @override
  String get homeWishList => 'WishLeafs';

  @override
  String get homeFinances => 'Финансы';

  @override
  String get homeSort => 'Сортировка';

  @override
  String get homeSortSpecies => 'Вид';

  @override
  String get homeSortNickname => 'Прозвище';

  @override
  String get homeSortWatering => 'Полив';

  @override
  String get homeSortFertilizing => 'Подкормка';

  @override
  String get homeSortDate => 'Дата';

  @override
  String get homeSortFamily => 'Семейство';

  @override
  String get homeSortLastWatered => 'Последний полив';

  @override
  String get homeSortLastFertilized => 'Последняя подкормка';

  @override
  String get homeSortDateAdded => 'Дата добавления';

  @override
  String homeSelectedCount(int count) {
    return 'Выбрано: $count';
  }

  @override
  String get homeSelectAll => 'Выбрать все';

  @override
  String get homeClearSelection => 'Снять выделение';

  @override
  String get homeWatering => 'Полив';

  @override
  String get homeFertilizing => 'Подкормка';

  @override
  String get homeRepotting => 'Пересадка';

  @override
  String get homeUpdateFamily => 'Изменить семейство';

  @override
  String get homeUpdateFamilyTitle => 'Изменить семейство';

  @override
  String get homeFamilyLabel => 'Семейство';

  @override
  String get homeFertilizeSelectedTitle => 'Подкормить выбранные растения';

  @override
  String get homeRepotSelectedTitle => 'Пересадить выбранные растения';

  @override
  String get homeDeleteSelectedTitle => 'Удалить выбранные растения?';

  @override
  String homeDeleteSelectedBody(int count) {
    return 'Это навсегда удалит $count растение(й).';
  }

  @override
  String homeDeleteSelectedBodyPlural(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Это навсегда удалит $count растений.',
      many: 'Это навсегда удалит $count растений.',
      few: 'Это навсегда удалит $count растения.',
      one: 'Это навсегда удалит 1 растение.',
    );
    return '$_temp0';
  }

  @override
  String get searchNoPlantsInJournal => 'В журнале нет растений';

  @override
  String get searchNothingFound => 'Ничего не найдено';

  @override
  String get plantAdd => 'Добавить растение';

  @override
  String get plantEdit => 'Редактировать растение';

  @override
  String get plantSaveChanges => 'Сохранить изменения';

  @override
  String get plantGenus => 'Род';

  @override
  String get plantSpecies => 'Вид';

  @override
  String get plantCultivar => 'Сорт';

  @override
  String get plantTradingName => 'Торговое название';

  @override
  String get plantFamily => 'Семейство';

  @override
  String get plantNickname => 'Прозвище';

  @override
  String get plantWateringFrequency => 'Частота полива';

  @override
  String get plantGrowthStage => 'Стадия роста';

  @override
  String get plantGenusRequired => 'Укажите род растения';

  @override
  String get plantSpeciesRequired => 'Укажите вид растения';

  @override
  String get plantInvalidWateringFrequency => 'Некорректная частота полива';

  @override
  String get plantUntitled => 'Без названия';

  @override
  String get plantDefaultTitle => 'Растение';

  @override
  String get plantGenusFallback => 'Род';

  @override
  String plantSpeciesLabel(String species) {
    return 'Вид: $species';
  }

  @override
  String plantCultivarLabel(String cultivar) {
    return 'Сорт: $cultivar';
  }

  @override
  String plantStageLabel(String stage) {
    return 'Стадия: $stage';
  }

  @override
  String get plantFamilyLabel => 'Семейство';

  @override
  String get plantTradingNameLabel => 'Торговое название';

  @override
  String get plantGenusPrefix => 'Род: ';

  @override
  String plantVariegationLabel(String value) {
    return 'Вариегатность: $value';
  }

  @override
  String get plantBotanicalData => 'Ботанические данные';

  @override
  String get plantDateAddedLabel => 'Дата добавления';

  @override
  String get plantJournal => 'Журнал';

  @override
  String get plantGallery => 'Галерея';

  @override
  String get plantCamera => 'Камера';

  @override
  String plantUploadError(String error) {
    return 'Ошибка загрузки: $error';
  }

  @override
  String get plantPhotoDeleteTitle => 'Удалить фото';

  @override
  String get plantPhotoDeleteConfirm => 'Удалить это фото растения?';

  @override
  String get plantCropTitle => 'Кадрирование';

  @override
  String get plantCropConfirm => 'Готово';

  @override
  String plantCropError(String error) {
    return 'Ошибка кадрирования: $error';
  }

  @override
  String get plantEmptyStage => 'Растений этой стадии в коллекции пока нет';

  @override
  String get plantEmptyGenus => 'Растений этого рода в коллекции пока нет';

  @override
  String get plantNote => 'Заметка';

  @override
  String get plantPropagation => 'Размножение';

  @override
  String get plantInitialLeafCount => 'Начальное число листьев';

  @override
  String get plantInvalidInitialLeafCount =>
      'Некорректное начальное число листьев';

  @override
  String get plantLeafAdd => 'Добавить лист';

  @override
  String get plantLeafRemove => 'Убрать лист';

  @override
  String get plantLeafRemoveTitle => 'Куда делся лист?';

  @override
  String get plantLeafRemoveCut => 'Срезала (на укоренение)';

  @override
  String get plantLeafRemoveEaten => 'Скушал';

  @override
  String get plantLeafRemoveDried => 'Отсушил';

  @override
  String get plantLeafStatsAnchor => 'Статистика листьев';

  @override
  String get plantLeafStatsTitle => 'Рост листьев';

  @override
  String get plantLeafStatsGained => 'Прибыло';

  @override
  String get plantLeafStatsLost => 'Убыло';

  @override
  String plantLeafStatsMonthLine(String month, int gained, int lost) {
    return '$month: прибыло $gained, убыло $lost';
  }

  @override
  String get stageUnknown => '🌱 Неизвестно';

  @override
  String get stageStart => '🌱 Старт';

  @override
  String get stageBaby => '🌿 Детка';

  @override
  String get stageJuvenile => '🌳 Ювенил';

  @override
  String get stageAdult => '🌴 Взрослое';

  @override
  String get stageDescriptionTitle => 'Описание стадии';

  @override
  String get stageStartCheck1 => 'Клубень без корней';

  @override
  String get stageStartCheck2 => 'Лист с небольшой ризомой';

  @override
  String get stageStartCheck3 => 'Укореняемый черенок';

  @override
  String get stageStartCheck4 => 'Растение только начинает рост';

  @override
  String get stageBabyCheck1 => '1–2 настоящих листа';

  @override
  String get stageBabyCheck2 => 'Корневая только формируется';

  @override
  String get stageBabyCheck3 => 'Самостоятельный рост';

  @override
  String get stageJuvenileCheck1 => '3–5 листьев';

  @override
  String get stageJuvenileCheck2 => 'Хорошая корневая';

  @override
  String get stageJuvenileCheck3 => 'Активный рост';

  @override
  String get stageAdultCheck1 => 'Полностью сформированное растение';

  @override
  String get stageAdultCheck2 => 'Регулярно выпускает новые листья';

  @override
  String get stageAdultCheck3 => 'Можно делить или брать черенки';

  @override
  String get variegationLabel => 'Вариегатность';

  @override
  String get variegationNone => 'Нет';

  @override
  String get variegationAurea => 'Аурея';

  @override
  String get variegationAlba => 'Альба';

  @override
  String get variegationPink => 'Пинк';

  @override
  String get variegationSplash => 'Сплеш';

  @override
  String get variegationMint => 'Минт';

  @override
  String get variegationMulticolor => 'Мультиколор';

  @override
  String get variegationTricolor => 'Триколор';

  @override
  String get variegationUnknown => 'Неизвестно';

  @override
  String get watering => 'Полив';

  @override
  String get wateringHistory => 'История поливов';

  @override
  String get wateringAdd => 'Добавить полив';

  @override
  String get wateringEdit => 'Редактировать полив';

  @override
  String get wateringDeleteTitle => 'Удалить полив';

  @override
  String get wateringDeleteConfirm => 'Удалить эту запись?';

  @override
  String get wateringEmpty => 'Поливов пока нет';

  @override
  String get fertilizing => 'Подкормка';

  @override
  String get fertilizingHistory => 'История подкормок';

  @override
  String get fertilizingAdd => 'Добавить подкормку';

  @override
  String get fertilizingEdit => 'Редактировать подкормку';

  @override
  String get fertilizingDeleteTitle => 'Удалить подкормку';

  @override
  String get fertilizingDeleteConfirm => 'Удалить эту запись?';

  @override
  String get fertilizingEmpty => 'Подкормок пока нет';

  @override
  String get fertilizingSelectedTitle => 'Подкормить выбранные растения';

  @override
  String get fertilizingApplicationMethod => 'Способ внесения';

  @override
  String get fertilizingRoot => 'Корневое';

  @override
  String get fertilizingFoliar => 'Внекорневое';

  @override
  String get fertilizingSaved => 'Сохранённые';

  @override
  String get fertilizingNewMix => 'Новый микс';

  @override
  String get fertilizingCatalog => 'Каталог';

  @override
  String get fertilizingEmptyCatalog =>
      'Удобрений пока нет. Добавьте готовое или сохраните микс.';

  @override
  String get fertilizingGoToNewMix => 'Перейти к «Новый микс»';

  @override
  String get fertilizingSelectFertilizer => 'Выберите удобрение';

  @override
  String get fertilizingViewComposition => 'Посмотреть состав';

  @override
  String fertilizingMixWaterVolume(int value) {
    return 'Объём воды для микса: $value мл';
  }

  @override
  String get fertilizingIngredients => 'Ингредиенты';

  @override
  String get fertilizingTapIngredientHint =>
      'Нажмите на ингредиент, чтобы задать количество (г или мл)';

  @override
  String get fertilizingSaveThisMix => 'Сохранить этот микс';

  @override
  String get fertilizingMixName => 'Название микса';

  @override
  String get fertilizingMixNameHint => 'напр. Формула роста';

  @override
  String get fertilizingWaterVolume => 'Объём воды';

  @override
  String get fertilizingAddIngredient => 'Добавить ингредиент';

  @override
  String get fertilizingIngredientNameHint => 'Название ингредиента';

  @override
  String get fertilizerFallbackName => 'Удобрение';

  @override
  String get fertilizerKindMix => 'Микс';

  @override
  String get fertilizerKindPurchased => 'Готовое';

  @override
  String get fertilizerCustomMix => 'Свой микс';

  @override
  String get fertilizerUnknown => 'Неизвестно';

  @override
  String get fertilizerInvalidDose => 'Некорректная доза';

  @override
  String get fertilizerNameLabel => 'Название';

  @override
  String get fertilizerNameHint => 'напр. Pokon Универсальное';

  @override
  String get fertilizerDoseLabelPurchased => 'Доза';

  @override
  String get fertilizerDoseLabelMix => 'Количество';

  @override
  String get fertilizerDoseHint => 'напр. 2';

  @override
  String fertilizerMixComposition(String components) {
    return 'Состав микса: $components';
  }

  @override
  String fertilizerWithMeta(String name, String kind, int waterMl) {
    return '$name · $kind · $waterMl мл';
  }

  @override
  String fertilizerWaterLine(int value) {
    return 'Вода: $value мл';
  }

  @override
  String get manageFertilizersTitle => 'Управление удобрениями';

  @override
  String get manageFertilizerIngredientsTitle => 'Управление ингредиентами';

  @override
  String get manageComponentsTitle => 'Управление компонентами';

  @override
  String get componentNameHint => 'Название компонента';

  @override
  String get emptyFertilizers => 'Удобрений пока нет';

  @override
  String get emptyIngredients => 'Ингредиентов пока нет';

  @override
  String get emptyComponents => 'Компонентов пока нет';

  @override
  String get emptyComposition => 'Состав пуст';

  @override
  String get repotting => 'Пересадка';

  @override
  String get repottingHistory => 'История пересадок';

  @override
  String get repottingAdd => 'Добавить пересадку';

  @override
  String get repottingEdit => 'Редактировать пересадку';

  @override
  String get repottingDeleteTitle => 'Удалить пересадку';

  @override
  String get repottingDeleteConfirm => 'Удалить эту запись?';

  @override
  String get repottingEmpty => 'Пересадок пока нет';

  @override
  String get repottingSlowRelease => 'Удобрение длительного действия';

  @override
  String get repottingSelectSoil => 'Выберите грунт';

  @override
  String get repottingSoilFallback => 'Грунт';

  @override
  String get repottingSoilComposition => 'Состав грунта';

  @override
  String get soilCustomMix => 'Свой микс';

  @override
  String soilParts(String parts) {
    return '$parts ч.';
  }

  @override
  String get notesEmpty => 'Заметок пока нет';

  @override
  String get notesAdd => 'Добавить заметку';

  @override
  String get notesAddHint =>
      'Добавьте новую запись в журнал для этого растения.';

  @override
  String get notesEdit => 'Редактировать заметку';

  @override
  String get notesLabel => 'Запись в журнале';

  @override
  String get notesEditLabel => 'Редактировать заметку';

  @override
  String get notesCannotBeEmpty => 'Заметка не может быть пустой';

  @override
  String get notesDeleteTitle => 'Удалить заметку';

  @override
  String get notesDeleteConfirm => 'Удалить эту заметку?';

  @override
  String get notesOptional => 'Заметка (необязательно)';

  @override
  String get fieldRequired => 'Это поле обязательно';

  @override
  String get propagationTitle => 'Размножение';

  @override
  String get propagationActiveTab => 'Активные';

  @override
  String get propagationArchiveTab => 'Архив';

  @override
  String get propagationEmptyActive => 'Нет активных размножений';

  @override
  String get propagationEmptyArchive => 'Архив пуст';

  @override
  String get propagationEmptyActiveHint =>
      'Добавьте партию со страницы растения';

  @override
  String get propagationEmptyArchiveHint => 'Завершённые партии хранятся 1 год';

  @override
  String get propagationAdd => 'Добавить размножение';

  @override
  String get propagationChangeStage => 'Изменить стадию';

  @override
  String get propagationSell => 'Продала';

  @override
  String get propagationGift => 'Подарила';

  @override
  String get propagationTrade => 'Обменяла';

  @override
  String get propagationLose => 'Погибли';

  @override
  String get propagationInitialStage => 'Начальная стадия';

  @override
  String propagationParentLabel(String name) {
    return 'Родитель: $name';
  }

  @override
  String get propagationDetails => 'Детали размножения';

  @override
  String get propagationQuantity => 'Количество';

  @override
  String get propagationQuantityMin => 'Укажите количество (минимум 1)';

  @override
  String get propagationAliveNow => 'Живых сейчас';

  @override
  String get propagationAliveRequired => 'Укажите число живых';

  @override
  String get propagationSellQuantityRequired => 'Укажите количество на продажу';

  @override
  String get propagationGiftQuantityRequired => 'Укажите количество';

  @override
  String get propagationTradeQuantityRequired => 'Укажите количество';

  @override
  String get propagationLoseQuantityRequired => 'Укажите количество';

  @override
  String propagationQuantityExceedsAlive(int count) {
    return 'Нельзя превысить число живых ($count)';
  }

  @override
  String propagationDate(String date) {
    return 'Дата: $date';
  }

  @override
  String propagationSinceDate(String date) {
    return 'с $date';
  }

  @override
  String propagationSoldCount(int count) {
    return 'продано $count';
  }

  @override
  String propagationGiftedCount(int count) {
    return 'подарено $count';
  }

  @override
  String propagationTradedCount(int count) {
    return 'обменяно $count';
  }

  @override
  String propagationLostCount(int count) {
    return 'погибло $count';
  }

  @override
  String propagationSoldLabel(int count, String unit) {
    return 'Продано: $count $unit';
  }

  @override
  String propagationGiftedLabel(int count, String unit) {
    return 'Подарено: $count $unit';
  }

  @override
  String propagationTradedLabel(int count, String unit) {
    return 'Обменяно: $count $unit';
  }

  @override
  String propagationLostLabel(int count, String unit) {
    return 'Погибло: $count $unit';
  }

  @override
  String propagationStartedLabel(int batches, int quantity) {
    return 'Поставлено: $batches парт. · $quantity шт';
  }

  @override
  String propagationStatsTitle(int year) {
    return 'Статистика $year';
  }

  @override
  String propagationByMethods(String methods) {
    return 'По способам: $methods';
  }

  @override
  String propagationByFamilies(String families) {
    return 'По семействам: $families';
  }

  @override
  String propagationQuantityPieces(int count) {
    return '$count шт';
  }

  @override
  String get propagationDeleteTitle => 'Удалить размножение';

  @override
  String get propagationDeleteConfirm =>
      'Партия размножения и вся история стадий будут удалены безвозвратно. Продолжить?';

  @override
  String get propagationDeleteHistoryEntry => 'Удалить запись истории?';

  @override
  String get propagationTimelineEmpty => 'Истории стадий пока нет';

  @override
  String daysCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count дней',
      many: '$count дней',
      few: '$count дня',
      one: '1 день',
      zero: 'сегодня',
    );
    return '$_temp0';
  }

  @override
  String propagationAliveWithMethod(int count, String method) {
    return '$count $method';
  }

  @override
  String get propagationMethodLeaf => 'Лист';

  @override
  String get propagationMethodLeafPlural => 'листов';

  @override
  String get propagationMethodLeafFragment => 'Фрагмент листа';

  @override
  String get propagationMethodLeafFragmentPlural => 'фрагментов листа';

  @override
  String get propagationMethodRhizome => 'Ризома';

  @override
  String get propagationMethodRhizomePlural => 'ризом';

  @override
  String get propagationMethodTuber => 'Клубень';

  @override
  String get propagationMethodTuberPlural => 'клубней';

  @override
  String get propagationMethodDivision => 'Деление';

  @override
  String get propagationMethodDivisionPlural => 'делений';

  @override
  String get propagationMethodOffset => 'Детка';

  @override
  String get propagationMethodOffsetPlural => 'деток';

  @override
  String get propagationMethodCutting => 'Черенок';

  @override
  String get propagationMethodCuttingPlural => 'черенков';

  @override
  String get propagationMethodMicrocloning => 'Микроклонирование';

  @override
  String get propagationMethodMicrocloningPlural => 'микроклонов';

  @override
  String get propagationStatusActive => 'Активно';

  @override
  String get propagationStatusSold => 'Продано';

  @override
  String get propagationStatusGifted => 'Подарено';

  @override
  String get propagationStatusTraded => 'Обменяно';

  @override
  String get propagationStatusLost => 'Погибло';

  @override
  String get propagationStartRooting => 'Поставить на укоренение';

  @override
  String get propagationMethodField => 'Способ';

  @override
  String propagationQuantityExceedsOriginal(int count) {
    return 'Не больше исходных $count шт.';
  }

  @override
  String propagationAliveWithPlant(int count, String plantName) {
    return '$count живых · $plantName';
  }

  @override
  String get propagationSellQuantity => 'Сколько продать';

  @override
  String get propagationGiftQuantity => 'Сколько подарить';

  @override
  String get propagationTradeQuantity => 'Сколько обменять';

  @override
  String get propagationLoseQuantity => 'Сколько погибло';

  @override
  String get propagationWriteOff => 'Списать';

  @override
  String get propagationConfirmGift => 'Подарить';

  @override
  String get propagationConfirmTrade => 'Обменять';

  @override
  String get propagationTimeline => 'Таймлайн';

  @override
  String propagationSoldCountLabel(int count) {
    return 'Продано: $count';
  }

  @override
  String propagationGiftedCountLabel(int count) {
    return 'Подарено: $count';
  }

  @override
  String propagationTradedCountLabel(int count) {
    return 'Обменяно: $count';
  }

  @override
  String propagationLostCountLabel(int count) {
    return 'Погибло: $count';
  }

  @override
  String propagationOfTotal(int count) {
    return 'из $count';
  }

  @override
  String propagationDeleteStartStageBody(String stageName) {
    return 'Удаление стадии «$stageName» безвозвратно удалит всю партию размножения и все остальные стадии. Продолжить?';
  }

  @override
  String get propagationDeleteStageEntryBody =>
      'Будет удалена только эта запись стадии. Остальные останутся.';

  @override
  String get propagationDeleteLastEntryBody =>
      'Это последняя запись истории. Партия размножения будет удалена безвозвратно. Продолжить?';

  @override
  String get deleteEntryConfirm => 'Удалить эту запись?';

  @override
  String get promptEmptyNotAllowed => 'Значение не может быть пустым';

  @override
  String get repottingEmptySoils =>
      'Пока нет сохранённых грунтов. Создайте новый микс.';

  @override
  String get repottingSoilTapHint =>
      'Нажатие: +1 часть · Долгое нажатие: ½ части (ещё раз — убрать)';

  @override
  String get repottingSlowReleaseSubtitle => 'Вносилось ли при пересадке';

  @override
  String get repottingMixNameHint => 'напр. Микс для ароидов';

  @override
  String get fertilizerPurchasedAddTitle => 'Готовое удобрение';

  @override
  String get fertilizerEditTitle => 'Изменить удобрение';

  @override
  String get fertilizerDeleteTitle => 'Удалить удобрение';

  @override
  String get ingredientEditTitle => 'Изменить ингредиент';

  @override
  String get ingredientDeleteTitle => 'Удалить ингредиент';

  @override
  String get componentEditTitle => 'Изменить компонент';

  @override
  String get componentDeleteTitle => 'Удалить компонент';

  @override
  String get componentAddTitle => 'Добавить компонент';

  @override
  String catalogItemDeleteConfirm(String name) {
    return 'Удалить «$name» из каталога?';
  }

  @override
  String catalogItemAlreadyExists(String name) {
    return '«$name» уже есть в каталоге';
  }

  @override
  String get manageFertilizersHint =>
      'Миксы сохраняются из «Новый микс». Вид можно менять: готовое ↔ микс.';

  @override
  String get fertilizerWaterForDilution => 'Вода для разведения';

  @override
  String fertilizerDoseOnWaterOptional(int waterMl) {
    return 'Доза на $waterMl мл (необязательно)';
  }

  @override
  String get fertilizerDoseOptional => 'Доза (необязательно)';

  @override
  String get fertilizerKindSection => 'Вид';

  @override
  String get soilComponentsTitle => 'Компоненты грунта';

  @override
  String get noComponents => 'Нет компонентов';

  @override
  String get doseAmountRequired => 'Укажите количество';

  @override
  String get doseInvalidNumber => 'Некорректное число';

  @override
  String get doseRemove => 'Убрать';

  @override
  String get wishListTitle => 'WishLeafs';

  @override
  String get wishListAdd => 'Добавить в список желаний';

  @override
  String get wishListEdit => 'Изменить растение';

  @override
  String get wishListEmpty => 'Список желаний пуст';

  @override
  String get wishListEmptyHint => 'Добавьте растения, которые хотите купить';

  @override
  String get wishListNameEn => 'Название (английский)';

  @override
  String get wishListNameAlt => 'Другое название';

  @override
  String get wishListNameEnRequired => 'Укажите английское название';

  @override
  String get wishListNameAltRequired => 'Укажите другое название';

  @override
  String get wishListBought => 'Купила';

  @override
  String get wishListExchanged => 'Обменяла';

  @override
  String get wishListAcquireTitle => 'Как получили растение?';

  @override
  String get wishListExchangeNoFinanceHint =>
      'Обмен не записывается в финансы. Дальше можно добавить растение в коллекцию.';

  @override
  String get wishListSelectForTrade => 'Растение из вишлиста';

  @override
  String get wishListSelectForTradeHint =>
      'Выберите растение, которое получили при обмене. Финансовая запись не создаётся.';

  @override
  String get wishListAcquireContinue => 'Продолжить';

  @override
  String get wishListExport => 'Экспорт';

  @override
  String get wishListExportEmpty => 'Нечего экспортировать';

  @override
  String wishListDeleteConfirm(String name) {
    return 'Удалить «$name» из списка желаний?';
  }

  @override
  String get financesTitle => 'Финансы';

  @override
  String get financesAdd => 'Добавить запись';

  @override
  String get financesEdit => 'Изменить запись';

  @override
  String get financesEmpty => 'Финансовых записей пока нет';

  @override
  String get financesEmptyHint =>
      'Учитывайте доходы от продаж и расходы на растения';

  @override
  String get financesIncome => 'Доходы';

  @override
  String get financesExpense => 'Расходы';

  @override
  String get financesBalance => 'Баланс';

  @override
  String get financesAnalyticsTitle => 'Последние 3 месяца';

  @override
  String get financesNoIncome => 'Доходов пока нет';

  @override
  String get financesNoExpense => 'Расходов пока нет';

  @override
  String get financesTitleLabel => 'Название';

  @override
  String get financesTitleRequired => 'Укажите название';

  @override
  String financesAmountLabel(String symbol) {
    return 'Сумма ($symbol)';
  }

  @override
  String get financesAmountRequired => 'Укажите корректную сумму';

  @override
  String financesDeleteConfirm(String title) {
    return 'Удалить «$title»?';
  }

  @override
  String get financesAlsoAddToCatalog => 'Также добавить в каталог';

  @override
  String get financesAsSoilComponent => 'Компонент грунта';

  @override
  String get financesAsFertilizer => 'Удобрение';

  @override
  String get financesAsPurchasedFertilizer => 'Готовое удобрение';

  @override
  String get financesAsReadyMadeSoil => 'Готовый грунт';

  @override
  String financesPropagationSaleTitle(String plantName, int quantity) {
    return 'Продажа: $plantName ×$quantity';
  }

  @override
  String financesPlantSaleTitle(String plantName) {
    return 'Продажа растения: $plantName';
  }

  @override
  String get propagationTradeForWishList => 'На растение из вишлиста';

  @override
  String get commonContinue => 'Продолжить';

  @override
  String get commonSkip => 'Пропустить';

  @override
  String get plantMergeTitle => 'Объединить в группу';

  @override
  String plantMergeMemberLabel(int index) {
    return 'Сорт $index';
  }

  @override
  String get plantMergeMembersRequired => 'Укажите хотя бы два сорта';

  @override
  String get plantGroupMembers => 'Сорта в группе';

  @override
  String plantCultivarsLabel(String cultivars) {
    return 'Сорта: $cultivars';
  }

  @override
  String get plantArchiveTitle => 'Архив растений';

  @override
  String get plantArchiveEmpty => 'Архив пуст';

  @override
  String get plantArchiveEmptyHint => 'Растения хранятся в архиве 2 года';

  @override
  String get plantArchiveReasonMerged => 'Объединено';

  @override
  String get plantArchiveReasonDied => 'Умерло';

  @override
  String get plantArchiveReasonSold => 'Продано';

  @override
  String plantArchiveDate(String date) {
    return 'В архиве с $date';
  }

  @override
  String plantArchiveNoteLabel(String note) {
    return 'Причина: $note';
  }

  @override
  String get plantDispose => 'Убрать из коллекции';

  @override
  String get plantDisposeTitle => 'Убрать растение';

  @override
  String get plantDisposeReasonDied => 'Умерло';

  @override
  String get plantDisposeReasonSold => 'Продано';

  @override
  String get plantDisposeDeathNote => 'Описание причин';

  @override
  String get plantDisposeDeathNoteRequired => 'Опишите причину гибели';

  @override
  String get plantDisposeSaleAmount => 'Сумма продажи';

  @override
  String get plantDisposeConfirm => 'В архив';

  @override
  String get plantDisposeArchived => 'Растение перемещено в архив';
}
