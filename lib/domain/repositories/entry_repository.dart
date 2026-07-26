import '../entities/entry.dart';

abstract class EntryRepository {
  Future<List<Entry>> getAllEntries();
  Future<Entry?> getEntryById(String uuid);
  Future<Entry> addEntry(Entry entry);
  Future<Entry> updateEntry(Entry entry);
  Future<void> deleteEntry(String uuid);
  Future<List<Entry>> getEntriesByCharacter(String characterName);
  Future<List<Entry>> getEntriesForDate(DateTime date);
  Future<int> getTotalEntryCount();
  Future<int> getStreakCount();
}
