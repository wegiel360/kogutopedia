import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../models/entry_model.dart';
import '../models/achievement_model.dart';

class KogutopediaDatabase {
  static KogutopediaDatabase? _instance;
  late Isar _isar;

  KogutopediaDatabase._();

  static Future<KogutopediaDatabase> getInstance() async {
    if (_instance != null) return _instance!;
    _instance = KogutopediaDatabase._();
    await _instance._init();
    return _instance!;
  }

  Future<void> _init() async {
    final dir = await getApplicationDocumentsDirectory();
    _isar = await Isar.open(
      [EntryModelSchema, AchievementModelSchema],
      directory: dir.path,
      name: 'kogutopedia',
    );
  }

  Isar get isar => _isar;

  Future<void> close() => _isar.close();
}
