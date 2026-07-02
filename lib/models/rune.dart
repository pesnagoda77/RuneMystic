class Rune {
  final String id;
  final String name;
  final String symbol; // Unicode символ руны или строка
  final String title; // Короткое название (сила, удача...)
  final String description; // Описание на сегодня
  final String advice; // Совет дня
  final String element; // Огонь, Вода, Воздух, Земля
  final String? imageAsset; // Путь к PNG в assets

  Rune({
    required this.id,
    required this.name,
    required this.symbol,
    required this.title,
    required this.description,
    required this.advice,
    required this.element,
    this.imageAsset,
  });
}
