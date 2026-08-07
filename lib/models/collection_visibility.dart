enum CollectionVisibility {
  friends,
  private;

  String get code => name;

  static CollectionVisibility fromCode(String? code) {
    if (code == 'private') return CollectionVisibility.private;
    return CollectionVisibility.friends;
  }
}
