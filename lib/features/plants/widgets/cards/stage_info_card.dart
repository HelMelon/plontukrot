class StageInfo {
  final int value;
  final String title;
  final List<String> checklist;

  const StageInfo({
    required this.value,
    required this.title,
    required this.checklist,
  });
}

const stageInfos = [
  StageInfo(
    value: 0,
    title: "🌱 Unknown",
    checklist: [],
  ),
  StageInfo(
    value: 1,
    title: "🌱 Start",
    checklist: [
      "Клубень без корней",
      "Лист с небольшой ризомой",
      "Укореняемый черенок",
      "Растение только начинает рост",
    ],
  ),
  StageInfo(
    value: 2,
    title: "🌿 Kiddo",
    checklist: [
      "1–2 настоящих листа",
      "Корневая только формируется",
      "Самостоятельный рост",
    ],
  ),
  StageInfo(
    value: 3,
    title: "🌳 Juvenile",
    checklist: [
      "3–5 листьев",
      "Хорошая корневая",
      "Активный рост",
    ],
  ),
  StageInfo(
    value: 4,
    title: "🌴 Mature",
    checklist: [
      "Полностью сформированное растение",
      "Регулярно выпускает новые листья",
      "Можно делить или брать черенки",
    ],
  ),
];
