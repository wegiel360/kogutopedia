import '../entities/entry.dart';
import '../repositories/entry_repository.dart';

class GetEntriesUseCase {
  final EntryRepository _repository;

  GetEntriesUseCase(this._repository);

  Future<List<Entry>> all() => _repository.getAllEntries();

  Future<List<Entry>> byCharacter(String character) =>
      _repository.getEntriesByCharacter(character);

  Future<List<Entry>> byDate(DateTime date) =>
      _repository.getEntriesForDate(date);
}
