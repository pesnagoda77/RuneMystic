import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/rune.dart';
import '../data/runes.dart';

class RuneService {
  static final RuneService _instance = RuneService._internal();
  factory RuneService() => _instance;
  RuneService._internal();

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Ключи SharedPreferences
  static const String _lastDrawDateKey = 'last_draw_date';
  static const String _lastRuneIdKey = 'last_rune_id';
  static const String _collectedRunesKey = 'collected_runes';
  static const String _premiumKey = 'is_premium';

  // Проверяем, тянули ли уже сегодня
  bool get canDrawToday {
    if (_prefs == null) return false;
    final lastDrawStr = _prefs!.getString(_lastDrawDateKey);
    if (lastDrawStr == null) return true;
    final lastDraw = DateTime.parse(lastDrawStr);
    final now = DateTime.now();
    return lastDraw.year != now.year ||
        lastDraw.month != now.month ||
        lastDraw.day != now.day;
  }

  // Тянем руну
  Future<Rune> drawRune() async {
    if (_prefs == null) await init();

    final now = DateTime.now();
    final random = Random(now.millisecondsSinceEpoch);
    final index = random.nextInt(allRunes.length);
    final rune = allRunes[index];

    await _prefs!.setString(_lastDrawDateKey, now.toIso8601String());
    await _prefs!.setString(_lastRuneIdKey, rune.id);

    // Добавляем в коллекцию
    final collected = getCollectedRunes();
    if (!collected.contains(rune.id)) {
      collected.add(rune.id);
      await _prefs!.setStringList(_collectedRunesKey, collected);
    }

    return rune;
  }

  // Получить последнюю вытянутую руну
  Rune? getLastRune() {
    if (_prefs == null) return null;
    final id = _prefs!.getString(_lastRuneIdKey);
    if (id == null) return null;
    try {
      return allRunes.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }

  // Коллекция вытянутых рун
  List<String> getCollectedRunes() {
    if (_prefs == null) return [];
    return _prefs!.getStringList(_collectedRunesKey) ?? [];
  }

  List<Rune> getCollectedRunesData() {
    final ids = getCollectedRunes();
    return allRunes.where((r) => ids.contains(r.id)).toList();
  }

  int get collectedCount => getCollectedRunes().length;
  int get totalCount => allRunes.length;

  // Freemium: подписка (заглушка для MVP)
  bool get isPremium {
    if (_prefs == null) return false;
    return _prefs!.getBool(_premiumKey) ?? false;
  }

  Future<void> setPremium(bool value) async {
    if (_prefs == null) await init();
    await _prefs!.setBool(_premiumKey, value);
  }

  // Для freemium: если не премиум, то 1 руна в день
  bool get isLimited => !isPremium && !canDrawToday;
}
