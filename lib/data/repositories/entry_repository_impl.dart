import 'package:isar/isar.dart';
import 'package:uuid/uuid.dart';
import '../../core/errors/app_exceptions.dart';
import '../../core/utils/date_utils.dart';
import '../../domain/entities/entry.dart';
import '../../domain/repositories/entry_repository.dart';
import '../database/kogutopedia_db.dart';
import '../models/entry_model.dart';

class EntryRepositoryImpl implements EntryRepository {
  final KogutopediaDatabase _db;
  final Uuid _uuid = const Uuid();

  EntryRepositoryImpl(this._db);

  @override
  Future<List<Entry>> getAllEntries() async {
    try {
      final models = await _db.isar.entryModels
          .where()
          .sortByEntryDateDesc()
          .findAll();
      return models.map(_toEntity).toList();
    } catch (e) {
      throw DatabaseException('Failed to fetch entries: $e');
    }
  }

  @override
  Future<Entry?> getEntryById(String uuid) async {
    try {
      final model = await _db.isar.entryModels
          .filter()
          .uuidEqualTo(uuid)
          .findFirst();
      return model != null ? _toEntity(model) : null;
    } catch (e) {
      throw DatabaseException('Failed to fetch entry: $e');
    }
  }

  @override
  Future<Entry> addEntry(Entry entry) async {
    try {
      final model = _toModel(entry);
      model.uuid = _uuid.v4();
      await _db.isar.writeTxn(() async {
        await _db.isar.entryModels.put(model);
      });
      return _toEntity(model);
    } catch (e) {
      throw DatabaseException('Failed to add entry: $e');
    }
  }

  @override
  Future<Entry> updateEntry(Entry entry) async {
    try {
      final existing = await _db.isar.entryModels
          .filter()
          .uuidEqualTo(entry.uuid)
          .findFirst();
      if (existing == null) {
        throw DatabaseException('Entry not found');
      }
      final model = _toModel(entry);
      model.id = existing.id;
      await _db.isar.writeTxn(() async {
        await _db.isar.entryModels.put(model);
      });
      return _toEntity(model);
    } catch (e) {
      if (e is DatabaseException) rethrow;
      throw DatabaseException('Failed to update entry: $e');
    }
  }

  @override
  Future<void> deleteEntry(String uuid) async {
    try {
      final existing = await _db.isar.entryModels
          .filter()
          .uuidEqualTo(uuid)
          .findFirst();
      if (existing != null) {
        await _db.isar.writeTxn(() async {
          await _db.isar.entryModels.delete(existing.id);
        });
      }
    } catch (e) {
      throw DatabaseException('Failed to delete entry: $e');
    }
  }

  @override
  Future<List<Entry>> getEntriesByCharacter(String characterName) async {
    try {
      final models = await _db.isar.entryModels
          .filter()
          .characterNameEqualTo(characterName)
          .sortByEntryDateDesc()
          .findAll();
      return models.map(_toEntity).toList();
    } catch (e) {
      throw DatabaseException('Failed to fetch entries by character: $e');
    }
  }

  @override
  Future<List<Entry>> getEntriesForDate(DateTime date) async {
    try {
      final dateKey = AppDateUtils.dateKey(date);
      final models = await _db.isar.entryModels
          .filter()
          .dateKeyEqualTo(dateKey)
          .findAll();
      return models.map(_toEntity).toList();
    } catch (e) {
      throw DatabaseException('Failed to fetch entries for date: $e');
    }
  }

  @override
  Future<int> getTotalEntryCount() async {
    try {
      return await _db.isar.entryModels.count();
    } catch (e) {
      throw DatabaseException('Failed to count entries: $e');
    }
  }

  @override
  Future<int> getStreakCount() async {
    try {
      final tomekEntries = await _db.isar.entryModels
          .filter()
          .characterNameEqualTo('Tomek')
          .sortByDateKeyDesc()
          .findAll();

      final uniqueDays = <String>{};
      for (final entry in tomekEntries) {
        uniqueDays.add(entry.dateKey);
      }
      return uniqueDays.length;
    } catch (e) {
      throw DatabaseException('Failed to calculate streak: $e');
    }
  }

  Entry _toEntity(EntryModel model) {
    return Entry(
      uuid: model.uuid,
      createdAt: model.createdAt,
      entryDate: model.entryDate,
      characterName: model.characterName,
      title: model.title,
      description: model.description,
      mediaPath: model.mediaPath,
      mediaType: model.mediaType,
    );
  }

  EntryModel _toModel(Entry entry) {
    return EntryModel(
      uuid: entry.uuid,
      createdAt: entry.createdAt,
      entryDate: entry.entryDate,
      characterName: entry.characterName,
      title: entry.title,
      description: entry.description,
      mediaPath: entry.mediaPath,
      mediaType: entry.mediaType,
    );
  }
}
