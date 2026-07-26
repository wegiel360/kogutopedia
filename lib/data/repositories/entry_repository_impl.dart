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
  int _nextId = 1;

  EntryRepositoryImpl(this._db);

  @override
  Future<List<Entry>> getAllEntries() async {
    try {
      final models = await _db.getEntries();
      models.sort((a, b) => b.entryDate.compareTo(a.entryDate));
      return models.map(_toEntity).toList();
    } catch (e) {
      throw DatabaseException('Failed to fetch entries: $e');
    }
  }

  @override
  Future<Entry?> getEntryById(String uuid) async {
    try {
      final models = await _db.getEntries();
      final model = models.where((e) => e.uuid == uuid).firstOrNull;
      return model != null ? _toEntity(model) : null;
    } catch (e) {
      throw DatabaseException('Failed to fetch entry: $e');
    }
  }

  @override
  Future<Entry> addEntry(Entry entry) async {
    try {
      final models = await _db.getEntries();
      final model = _toModel(entry);
      _nextId = models.fold(0, (max, e) => e.id != null && e.id! > max ? e.id! : max) + 1;
      final newModel = EntryModel(
        id: _nextId,
        uuid: _uuid.v4(),
        createdAt: entry.createdAt,
        entryDate: entry.entryDate,
        characterName: entry.characterName,
        title: entry.title,
        description: entry.description,
        mediaPath: entry.mediaPath,
        mediaType: entry.mediaType,
      );
      models.add(newModel);
      await _db.saveEntries(models);
      return _toEntity(newModel);
    } catch (e) {
      throw DatabaseException('Failed to add entry: $e');
    }
  }

  @override
  Future<Entry> updateEntry(Entry entry) async {
    try {
      final models = await _db.getEntries();
      final index = models.indexWhere((e) => e.uuid == entry.uuid);
      if (index == -1) {
        throw DatabaseException('Entry not found');
      }
      final existing = models[index];
      final updated = EntryModel(
        id: existing.id,
        uuid: existing.uuid,
        createdAt: existing.createdAt,
        entryDate: entry.entryDate,
        characterName: entry.characterName,
        title: entry.title,
        description: entry.description,
        mediaPath: entry.mediaPath,
        mediaType: entry.mediaType,
      );
      models[index] = updated;
      await _db.saveEntries(models);
      return _toEntity(updated);
    } catch (e) {
      if (e is DatabaseException) rethrow;
      throw DatabaseException('Failed to update entry: $e');
    }
  }

  @override
  Future<void> deleteEntry(String uuid) async {
    try {
      final models = await _db.getEntries();
      models.removeWhere((e) => e.uuid == uuid);
      await _db.saveEntries(models);
    } catch (e) {
      throw DatabaseException('Failed to delete entry: $e');
    }
  }

  @override
  Future<List<Entry>> getEntriesByCharacter(String characterName) async {
    try {
      final models = await _db.getEntries();
      final filtered = models.where((e) => e.characterName == characterName).toList();
      filtered.sort((a, b) => b.entryDate.compareTo(a.entryDate));
      return filtered.map(_toEntity).toList();
    } catch (e) {
      throw DatabaseException('Failed to fetch entries by character: $e');
    }
  }

  @override
  Future<List<Entry>> getEntriesForDate(DateTime date) async {
    try {
      final dateKey = AppDateUtils.dateKey(date);
      final models = await _db.getEntries();
      final filtered = models.where((e) => e.dateKey == dateKey).toList();
      return filtered.map(_toEntity).toList();
    } catch (e) {
      throw DatabaseException('Failed to fetch entries for date: $e');
    }
  }

  @override
  Future<int> getTotalEntryCount() async {
    try {
      final models = await _db.getEntries();
      return models.length;
    } catch (e) {
      throw DatabaseException('Failed to count entries: $e');
    }
  }

  @override
  Future<int> getStreakCount() async {
    try {
      final models = await _db.getEntries();
      final tomekEntries = models.where((e) => e.characterName == 'Tomek').toList();
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
