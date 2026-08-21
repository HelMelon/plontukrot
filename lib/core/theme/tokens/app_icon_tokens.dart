import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

/// Semantic icon tokens for the app. Fill once here — screens read via
/// `context.icons`.
@immutable
class AppIconTokens {
  const AppIconTokens({
    // Generic actions & controls
    required this.add,
    required this.remove,
    required this.edit,
    required this.editOutlined,
    required this.delete,
    required this.deleteFilled,
    required this.clear,
    required this.close,
    required this.back,
    required this.search,
    required this.copy,
    required this.share,
    required this.uploadFile,
    required this.check,
    required this.checkCircleOutlined,
    required this.chevronRight,
    required this.chevronDown,
    required this.chevronUp,
    required this.arrowDownward,
    required this.arrowUpward,
    required this.radioChecked,
    required this.radioUnchecked,
    required this.selectAll,
    required this.deselectAll,
    required this.removeCircle,
    required this.addCircle,

    // Dialogs, Info & Status
    required this.info,
    required this.help,
    required this.error,
    required this.calendar,
    required this.calendarOutlined,

    // Navigation & Main Features
    required this.propagations,
    required this.wishlist,
    required this.finances,
    required this.archive,
    required this.archiveAction,
    required this.gift,
    required this.notifications,
    required this.friends,
    required this.profile,
    required this.collection,
    required this.friendRemove,

    // Plants, Botany & Photos
    required this.genus,
    required this.species,
    required this.cultivar,
    required this.tradingName,
    required this.family,
    required this.familyHub,
    required this.nickname,
    required this.stage,
    required this.leaf,
    required this.photoAdd,
    required this.photoDelete,
    required this.laurelWreath,
    required this.camera,
    required this.cameraOutlined,
    required this.gallery,
    required this.galleryOutlined,
    required this.image,
    required this.addImage,
    required this.brokenImage,
    required this.addPhotoPlaceholder,
    required this.addPhotoOutlined,
    required this.plantPlaceholder,
    required this.plantSearchIcon,

    // Care & Manipulations
    required this.watering,
    required this.wateringFilled,
    required this.wateringHistory,
    required this.fertilizing,
    required this.fertilizingFilled,
    required this.fertilizingEco,
    required this.repotting,
    required this.repottingAction,
    required this.note,
    required this.noteAction,
    required this.notesOutlined,
    required this.paymentsOutlined,
    required this.merge,
    required this.pinching,
    required this.rerooting,
    required this.stimulator,
    required this.leafCut,
    required this.leafEaten,
    required this.lossDied,
    required this.lossSold,

    // Auth & Inputs
    required this.personOutline,
    required this.email,
    required this.emailUnread,
    required this.lock,
    required this.visibility,
    required this.visibilityOff,
    required this.link,
    required this.translate,
  });

  static const standard = AppIconTokens(
    // Generic actions & controls
    add: Icons.add,
    remove: Icons.remove,
    edit: Icons.edit,
    editOutlined: Icons.edit_outlined,
    delete: Icons.delete_outline,
    deleteFilled: Icons.delete,
    clear: Icons.clear,
    close: Icons.close,
    back: Icons.arrow_back,
    search: Icons.search,
    copy: Icons.copy,
    share: Icons.ios_share_outlined,
    uploadFile: Icons.upload_file_outlined,
    check: Icons.check,
    checkCircleOutlined: Icons.check_circle_outline,
    chevronRight: Icons.chevron_right,
    chevronDown: Icons.keyboard_arrow_down,
    chevronUp: Icons.keyboard_arrow_up,
    arrowDownward: Icons.arrow_downward,
    arrowUpward: Icons.arrow_upward,
    radioChecked: Icons.radio_button_checked,
    radioUnchecked: Icons.radio_button_off,
    selectAll: Icons.select_all,
    deselectAll: Icons.deselect,
    removeCircle: Icons.remove_circle_outline,
    addCircle: Icons.add_circle_outline,

    // Dialogs, Info & Status
    info: Icons.info_outline,
    help: Icons.help_outline,
    error: Icons.error_outline,
    calendar: Icons.calendar_today,
    calendarOutlined: Icons.calendar_today_outlined,

    // Navigation & Main Features
    propagations: HugeIcons.strokeRoundedEcoLab01,
    wishlist: HugeIcons.strokeRoundedBookHeart,
    finances: HugeIcons.strokeRoundedCoins01,
    archive: Icons.inventory_2_outlined,
    archiveAction: Icons.archive_outlined,
    gift: Icons.card_giftcard_outlined,
    notifications: Icons.notifications_outlined,
    friends: Icons.people_outline,
    profile: Icons.person,
    collection: Icons.grid_view,
    friendRemove: Icons.person_remove_outlined,

    // Plants, Botany & Photos
    genus: Icons.park_outlined,
    species: Icons.eco,
    cultivar: Icons.spa_outlined,
    tradingName: Icons.storefront_outlined,
    family: Icons.family_restroom,
    familyHub: Icons.hub_outlined,
    nickname: HugeIcons.strokeRoundedHouseHeart,
    stage: Icons.eco_rounded,
    leaf: HugeIcons.strokeRoundedLeaf01,
    photoAdd: HugeIcons.strokeRoundedAdd01,
    photoDelete: HugeIcons.strokeRoundedDelete02,
    laurelWreath: HugeIcons.strokeRoundedLaurelWreath01,
    camera: Icons.camera_alt,
    cameraOutlined: Icons.camera_alt_outlined,
    gallery: Icons.photo_library,
    galleryOutlined: Icons.photo_library_outlined,
    image: Icons.image_outlined,
    addImage: Icons.add_photo_alternate_outlined,
    brokenImage: Icons.broken_image_outlined,
    addPhotoPlaceholder: Icons.add_a_photo,
    addPhotoOutlined: Icons.add_a_photo_outlined,
    plantPlaceholder: Icons.local_florist_outlined,
    plantSearchIcon: Icons.local_florist,

    // Care & Manipulations
    watering: Icons.water_drop_outlined,
    wateringFilled: Icons.water_drop,
    wateringHistory: Icons.water_drop_rounded,
    fertilizing: Icons.science_outlined,
    fertilizingFilled: Icons.science,
    fertilizingEco: Icons.eco_outlined,
    repotting: HugeIcons.strokeRoundedShovel,
    repottingAction: Icons.flaky,
    note: HugeIcons.strokeRoundedNoteEdit,
    noteAction: Icons.sticky_note_2_outlined,
    notesOutlined: Icons.notes_outlined,
    paymentsOutlined: Icons.payments_outlined,
    merge: Icons.merge_type,
    pinching: Icons.content_cut_outlined,
    rerooting: Icons.healing_outlined,
    stimulator: Icons.biotech_outlined,
    leafCut: Icons.content_cut,
    leafEaten: Icons.restaurant,
    lossDied: Icons.heart_broken_outlined,
    lossSold: Icons.sell_outlined,

    // Auth & Inputs
    personOutline: Icons.person_outline,
    email: Icons.email_outlined,
    emailUnread: Icons.mark_email_unread_outlined,
    lock: Icons.lock_outline,
    visibility: Icons.visibility_outlined,
    visibilityOff: Icons.visibility_off_outlined,
    link: Icons.language,
    translate: Icons.translate,
  );

  // Generic actions & controls
  final IconData add;
  final IconData remove;
  final IconData edit;
  final IconData editOutlined;
  final IconData delete;
  final IconData deleteFilled;
  final IconData clear;
  final IconData close;
  final IconData back;
  final IconData search;
  final IconData copy;
  final IconData share;
  final IconData uploadFile;
  final IconData check;
  final IconData checkCircleOutlined;
  final IconData chevronRight;
  final IconData chevronDown;
  final IconData chevronUp;
  final IconData arrowDownward;
  final IconData arrowUpward;
  final IconData radioChecked;
  final IconData radioUnchecked;
  final IconData selectAll;
  final IconData deselectAll;
  final IconData removeCircle;
  final IconData addCircle;

  // Dialogs, Info & Status
  final IconData info;
  final IconData help;
  final IconData error;
  final IconData calendar;
  final IconData calendarOutlined;

  // Navigation & Main Features
  final List<List<dynamic>> propagations;
  final List<List<dynamic>> wishlist;
  final List<List<dynamic>> finances;
  final IconData archive;
  final IconData archiveAction;
  final IconData gift;
  final IconData notifications;
  final IconData friends;
  final IconData profile;
  final IconData collection;
  final IconData friendRemove;

  // Plants, Botany & Photos
  final IconData genus;
  final IconData species;
  final IconData cultivar;
  final IconData tradingName;
  final IconData family;
  final IconData familyHub;
  final List<List<dynamic>> nickname;
  final IconData stage;
  final List<List<dynamic>> leaf;
  final List<List<dynamic>> photoAdd;
  final List<List<dynamic>> photoDelete;
  final List<List<dynamic>> laurelWreath;
  final IconData camera;
  final IconData cameraOutlined;
  final IconData gallery;
  final IconData galleryOutlined;
  final IconData image;
  final IconData addImage;
  final IconData brokenImage;
  final IconData addPhotoPlaceholder;
  final IconData addPhotoOutlined;
  final IconData plantPlaceholder;
  final IconData plantSearchIcon;

  // Care & Manipulations
  final IconData watering;
  final IconData wateringFilled;
  final IconData wateringHistory;
  final IconData fertilizing;
  final IconData fertilizingFilled;
  final IconData fertilizingEco;
  final List<List<dynamic>> repotting;
  final IconData repottingAction;
  final List<List<dynamic>> note;
  final IconData noteAction;
  final IconData notesOutlined;
  final IconData paymentsOutlined;
  final IconData merge;
  final IconData pinching;
  final IconData rerooting;
  final IconData stimulator;
  final IconData leafCut;
  final IconData leafEaten;
  final IconData lossDied;
  final IconData lossSold;

  // Auth & Inputs
  final IconData personOutline;
  final IconData email;
  final IconData emailUnread;
  final IconData lock;
  final IconData visibility;
  final IconData visibilityOff;
  final IconData link;
  final IconData translate;

  AppIconTokens copyWith({
    IconData? add,
    IconData? remove,
    IconData? edit,
    IconData? editOutlined,
    IconData? delete,
    IconData? deleteFilled,
    IconData? clear,
    IconData? close,
    IconData? back,
    IconData? search,
    IconData? copy,
    IconData? share,
    IconData? uploadFile,
    IconData? check,
    IconData? checkCircleOutlined,
    IconData? chevronRight,
    IconData? chevronDown,
    IconData? chevronUp,
    IconData? arrowDownward,
    IconData? arrowUpward,
    IconData? radioChecked,
    IconData? radioUnchecked,
    IconData? selectAll,
    IconData? deselectAll,
    IconData? removeCircle,
    IconData? addCircle,
    IconData? info,
    IconData? help,
    IconData? error,
    IconData? calendar,
    IconData? calendarOutlined,
    List<List<dynamic>>? propagations,
    List<List<dynamic>>? wishlist,
    List<List<dynamic>>? finances,
    IconData? archive,
    IconData? archiveAction,
    IconData? gift,
    IconData? notifications,
    IconData? friends,
    IconData? profile,
    IconData? collection,
    IconData? friendRemove,
    IconData? genus,
    IconData? species,
    IconData? cultivar,
    IconData? tradingName,
    IconData? family,
    IconData? familyHub,
    List<List<dynamic>>? nickname,
    IconData? stage,
    List<List<dynamic>>? leaf,
    List<List<dynamic>>? photoAdd,
    List<List<dynamic>>? photoDelete,
    List<List<dynamic>>? laurelWreath,
    IconData? camera,
    IconData? cameraOutlined,
    IconData? gallery,
    IconData? galleryOutlined,
    IconData? image,
    IconData? addImage,
    IconData? brokenImage,
    IconData? addPhotoPlaceholder,
    IconData? addPhotoOutlined,
    IconData? plantPlaceholder,
    IconData? plantSearchIcon,
    IconData? watering,
    IconData? wateringFilled,
    IconData? wateringHistory,
    IconData? fertilizing,
    IconData? fertilizingFilled,
    IconData? fertilizingEco,
    List<List<dynamic>>? repotting,
    IconData? repottingAction,
    List<List<dynamic>>? note,
    IconData? noteAction,
    IconData? notesOutlined,
    IconData? paymentsOutlined,
    IconData? merge,
    IconData? pinching,
    IconData? rerooting,
    IconData? stimulator,
    IconData? leafCut,
    IconData? leafEaten,
    IconData? lossDied,
    IconData? lossSold,
    IconData? personOutline,
    IconData? email,
    IconData? emailUnread,
    IconData? lock,
    IconData? visibility,
    IconData? visibilityOff,
    IconData? link,
    IconData? translate,
  }) {
    return AppIconTokens(
      add: add ?? this.add,
      remove: remove ?? this.remove,
      edit: edit ?? this.edit,
      editOutlined: editOutlined ?? this.editOutlined,
      delete: delete ?? this.delete,
      deleteFilled: deleteFilled ?? this.deleteFilled,
      clear: clear ?? this.clear,
      close: close ?? this.close,
      back: back ?? this.back,
      search: search ?? this.search,
      copy: copy ?? this.copy,
      share: share ?? this.share,
      uploadFile: uploadFile ?? this.uploadFile,
      check: check ?? this.check,
      checkCircleOutlined: checkCircleOutlined ?? this.checkCircleOutlined,
      chevronRight: chevronRight ?? this.chevronRight,
      chevronDown: chevronDown ?? this.chevronDown,
      chevronUp: chevronUp ?? this.chevronUp,
      arrowDownward: arrowDownward ?? this.arrowDownward,
      arrowUpward: arrowUpward ?? this.arrowUpward,
      radioChecked: radioChecked ?? this.radioChecked,
      radioUnchecked: radioUnchecked ?? this.radioUnchecked,
      selectAll: selectAll ?? this.selectAll,
      deselectAll: deselectAll ?? this.deselectAll,
      removeCircle: removeCircle ?? this.removeCircle,
      addCircle: addCircle ?? this.addCircle,
      info: info ?? this.info,
      help: help ?? this.help,
      error: error ?? this.error,
      calendar: calendar ?? this.calendar,
      calendarOutlined: calendarOutlined ?? this.calendarOutlined,
      propagations: propagations ?? this.propagations,
      wishlist: wishlist ?? this.wishlist,
      finances: finances ?? this.finances,
      archive: archive ?? this.archive,
      archiveAction: archiveAction ?? this.archiveAction,
      gift: gift ?? this.gift,
      notifications: notifications ?? this.notifications,
      friends: friends ?? this.friends,
      profile: profile ?? this.profile,
      collection: collection ?? this.collection,
      friendRemove: friendRemove ?? this.friendRemove,
      genus: genus ?? this.genus,
      species: species ?? this.species,
      cultivar: cultivar ?? this.cultivar,
      tradingName: tradingName ?? this.tradingName,
      family: family ?? this.family,
      familyHub: familyHub ?? this.familyHub,
      nickname: nickname ?? this.nickname,
      stage: stage ?? this.stage,
      leaf: leaf ?? this.leaf,
      photoAdd: photoAdd ?? this.photoAdd,
      photoDelete: photoDelete ?? this.photoDelete,
      laurelWreath: laurelWreath ?? this.laurelWreath,
      camera: camera ?? this.camera,
      cameraOutlined: cameraOutlined ?? this.cameraOutlined,
      gallery: gallery ?? this.gallery,
      galleryOutlined: galleryOutlined ?? this.galleryOutlined,
      image: image ?? this.image,
      addImage: addImage ?? this.addImage,
      brokenImage: brokenImage ?? this.brokenImage,
      addPhotoPlaceholder: addPhotoPlaceholder ?? this.addPhotoPlaceholder,
      addPhotoOutlined: addPhotoOutlined ?? this.addPhotoOutlined,
      plantPlaceholder: plantPlaceholder ?? this.plantPlaceholder,
      plantSearchIcon: plantSearchIcon ?? this.plantSearchIcon,
      watering: watering ?? this.watering,
      wateringFilled: wateringFilled ?? this.wateringFilled,
      wateringHistory: wateringHistory ?? this.wateringHistory,
      fertilizing: fertilizing ?? this.fertilizing,
      fertilizingFilled: fertilizingFilled ?? this.fertilizingFilled,
      fertilizingEco: fertilizingEco ?? this.fertilizingEco,
      repotting: repotting ?? this.repotting,
      repottingAction: repottingAction ?? this.repottingAction,
      note: note ?? this.note,
      noteAction: noteAction ?? this.noteAction,
      notesOutlined: notesOutlined ?? this.notesOutlined,
      paymentsOutlined: paymentsOutlined ?? this.paymentsOutlined,
      merge: merge ?? this.merge,
      pinching: pinching ?? this.pinching,
      rerooting: rerooting ?? this.rerooting,
      stimulator: stimulator ?? this.stimulator,
      leafCut: leafCut ?? this.leafCut,
      leafEaten: leafEaten ?? this.leafEaten,
      lossDied: lossDied ?? this.lossDied,
      lossSold: lossSold ?? this.lossSold,
      personOutline: personOutline ?? this.personOutline,
      email: email ?? this.email,
      emailUnread: emailUnread ?? this.emailUnread,
      lock: lock ?? this.lock,
      visibility: visibility ?? this.visibility,
      visibilityOff: visibilityOff ?? this.visibilityOff,
      link: link ?? this.link,
      translate: translate ?? this.translate,
    );
  }
}
