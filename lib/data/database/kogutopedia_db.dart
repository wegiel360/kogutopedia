import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/entry_model.dart';
import '../models/achievement_model.dart';
import '../models/feather_model.dart';

class KogutopediaDatabase {
  static KogutopediaDatabase? _instance;
  late String _dbPath;
  late String _mediaPath;

  KogutopediaDatabase._();

  static Future<KogutopediaDatabase> getInstance() async {
    if (_instance != null) return _instance!;
    final db = KogutopediaDatabase._();
    await db._init();
    _instance = db;
    return db;
  }

  Future<void> _init() async {
    final dir = await getApplicationDocumentsDirectory();
    _dbPath = '${dir.path}/kogutopedia';
    _mediaPath = '$_dbPath/media';
    for (final p in [_dbPath, _mediaPath]) {
      final d = Directory(p);
      if (!await d.exists()) {
        await d.create(recursive: true);
      }
    }
  }

  String get _entriesPath => '$_dbPath/entries.json';
  String get _achievementsPath => '$_dbPath/achievements.json';
  String get _feathersPath => '$_dbPath/feathers.json';

  Future<List<EntryModel>> getEntries() async {
    final file = File(_entriesPath);
    if (!await file.exists()) return [];
    final content = await file.readAsString();
    final list = jsonDecode(content) as List;
    return list.map((e) => EntryModel.fromJson(e)).toList();
  }

  Future<void> saveEntries(List<EntryModel> entries) async {
    final file = File(_entriesPath);
    final content = jsonEncode(entries.map((e) => e.toJson()).toList());
    await file.writeAsString(content);
  }

  Future<List<AchievementModel>> getAchievements() async {
    final file = File(_achievementsPath);
    if (!await file.exists()) return [];
    final content = await file.readAsString();
    final list = jsonDecode(content) as List;
    return list.map((e) => AchievementModel.fromJson(e)).toList();
  }

  Future<void> saveAchievements(List<AchievementModel> achievements) async {
    final file = File(_achievementsPath);
    final content =
        jsonEncode(achievements.map((e) => e.toJson()).toList());
    await file.writeAsString(content);
  }

  Future<List<FeatherModel>> getFeathers() async {
    final file = File(_feathersPath);
    if (!await file.exists()) return [];
    final content = await file.readAsString();
    final list = jsonDecode(content) as List;
    return list.map((e) => FeatherModel.fromJson(e)).toList();
  }

  Future<void> saveFeathers(List<FeatherModel> feathers) async {
    final file = File(_feathersPath);
    final content = jsonEncode(feathers.map((e) => e.toJson()).toList());
    await file.writeAsString(content);
  }

  String getMediaPath() => _mediaPath;
}
