import '../entities/entry.dart';
import '../repositories/entry_repository.dart';

class AddEntryUseCase {
  final EntryRepository _repository;

  AddEntryUseCase(this._repository);

  Future<Entry> call(Entry entry) => _repository.addEntry(entry);
}
