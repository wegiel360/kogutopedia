import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/errors/app_exceptions.dart';
import '../../data/database/kogutopedia_db.dart';
import '../../data/repositories/entry_repository_impl.dart';
import '../../domain/entities/entry.dart';
import '../../domain/repositories/entry_repository.dart';
import '../../domain/usecases/add_entry.dart';
import '../../domain/usecases/get_entries.dart';
import '../../domain/usecases/get_statistics.dart';

final databaseProvider = Provider<KogutopediaDatabase>((ref) {
  throw UnimplementedError('Database must be initialized before use');
});

final entryRepositoryProvider = Provider<EntryRepository>((ref) {
  final db = ref.read(databaseProvider);
  return EntryRepositoryImpl(db);
});

final getEntriesUseCaseProvider = Provider<GetEntriesUseCase>((ref) {
  return GetEntriesUseCase(ref.read(entryRepositoryProvider));
});

final addEntryUseCaseProvider = Provider<AddEntryUseCase>((ref) {
  return AddEntryUseCase(ref.read(entryRepositoryProvider));
});

final getStatisticsUseCaseProvider = Provider<GetStatisticsUseCase>((ref) {
  return GetStatisticsUseCase(ref.read(entryRepositoryProvider));
});

class EntryState {
  final List<Entry> entries;
  final bool isLoading;
  final String? error;
  final String? searchQuery;
  final String? characterFilter;

  const EntryState({
    this.entries = const [],
    this.isLoading = false,
    this.error,
    this.searchQuery,
    this.characterFilter,
  });

  EntryState copyWith({
    List<Entry>? entries,
    bool? isLoading,
    String? error,
    String? searchQuery,
    String? characterFilter,
  }) {
    return EntryState(
      entries: entries ?? this.entries,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      searchQuery: searchQuery ?? this.searchQuery,
      characterFilter: characterFilter ?? this.characterFilter,
    );
  }

  List<Entry> get filteredEntries {
    var result = entries;
    if (characterFilter != null && characterFilter!.isNotEmpty) {
      result = result.where((e) => e.characterName == characterFilter).toList();
    }
    if (searchQuery != null && searchQuery!.isNotEmpty) {
      final query = searchQuery!.toLowerCase();
      result = result
          .where((e) =>
              e.title.toLowerCase().contains(query) ||
              (e.description?.toLowerCase().contains(query) ?? false))
          .toList();
    }
    return result;
  }
}

class EntryNotifier extends StateNotifier<EntryState> {
  final GetEntriesUseCase _getEntries;
  final AddEntryUseCase _addEntry;
  final EntryRepository _repository;

  EntryNotifier(this._getEntries, this._addEntry, this._repository)
      : super(const EntryState());

  Future<void> loadEntries() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final entries = await _getEntries.all();
      state = state.copyWith(entries: entries, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e is AppException ? e.message : 'Wystąpił błąd podczas ładowania',
      );
    }
  }

  Future<Entry?> addEntry(Entry entry) async {
    try {
      final added = await _addEntry(entry);
      await loadEntries();
      return added;
    } catch (e) {
      state = state.copyWith(
        error: e is AppException ? e.message : 'Nie udało się dodać wpisu',
      );
      return null;
    }
  }

  Future<void> deleteEntry(String uuid) async {
    try {
      await _repository.deleteEntry(uuid);
      await loadEntries();
    } catch (e) {
      state = state.copyWith(
        error: e is AppException ? e.message : 'Nie udało się usunąć wpisu',
      );
    }
  }

  void setCharacterFilter(String? character) {
    state = state.copyWith(characterFilter: character);
  }

  void setSearchQuery(String? query) {
    state = state.copyWith(searchQuery: query);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final entryNotifierProvider =
    StateNotifierProvider<EntryNotifier, EntryState>((ref) {
  final getEntries = ref.read(getEntriesUseCaseProvider);
  final addEntry = ref.read(addEntryUseCaseProvider);
  final repository = ref.read(entryRepositoryProvider);
  return EntryNotifier(getEntries, addEntry, repository);
});
