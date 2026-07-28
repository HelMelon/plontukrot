enum PropagationMethod {
  leaf('Лист', 'листов'),
  leafFragment('Фрагмент листа', 'фрагментов листа'),
  rhizome('Ризома', 'ризом'),
  tuber('Клубень', 'клубней'),
  division('Деление', 'делений'),
  offset('Детка', 'деток'),
  cutting('Черенок', 'черенков');

  const PropagationMethod(this.label, this.pluralLabel);

  final String label;
  final String pluralLabel;

  String get code => name;

  static PropagationMethod fromCode(String? code) {
    return PropagationMethod.values.firstWhere(
      (method) => method.name == code,
      orElse: () => PropagationMethod.leaf,
    );
  }
}
