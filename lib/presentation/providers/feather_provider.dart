import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../data/repositories/feather_repository_impl.dart';
import '../../domain/entities/feather.dart';
import '../../domain/repositories/feather_repository.dart';
import 'entry_provider.dart';

class FeatherState {
  final List<Feather> feathers;
  final bool isLoading;
  final String? error;

  const FeatherState({
    this.feathers = const [],
    this.isLoading = false,
    this.error,
  });

  FeatherState copyWith({
    List<Feather>? feathers,
    bool? isLoading,
    String? error,
  }) {
    return FeatherState(
      feathers: feathers ?? this.feathers,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

final featherRepositoryProvider = Provider<FeatherRepository>((ref) {
  final db = ref.read(databaseProvider);
  return FeatherRepositoryImpl(db);
});

class FeatherNotifier extends StateNotifier<FeatherState> {
  final FeatherRepository _repo;
  final _uuid = const Uuid();

  FeatherNotifier(this._repo) : super(const FeatherState());

  Future<void> loadFeathers() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final feathers = await _repo.getAllFeathers();
      state = state.copyWith(feathers: feathers, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Wystąpił błąd podczas ładowania piór',
      );
    }
  }

  Future<Feather?> addFeather({
    required String title,
    String? description,
    String? imagePath,
    String? characterName,
  }) async {
    try {
      final feather = Feather(
        uuid: _uuid.v4(),
        createdAt: DateTime.now(),
        title: title,
        description: description,
        imagePath: imagePath,
        characterName: characterName,
      );
      await _repo.addFeather(feather);
      await loadFeathers();
      return feather;
    } catch (e) {
      state = state.copyWith(error: 'Nie udało się dodać pióra');
      return null;
    }
  }

  Future<void> deleteFeather(String uuid) async {
    try {
      final deleted = state.feathers.firstWhere((f) => f.uuid == uuid);
      await _repo.deleteFeather(uuid);
      if (deleted.imagePath != null) {
        final file = File(deleted.imagePath!);
        if (await file.exists()) await file.delete();
      }
      await loadFeathers();
    } catch (e) {
      state = state.copyWith(error: 'Nie udało się usunąć pióra');
    }
  }

  void clearError() => state = state.copyWith(error: null);
}

final featherNotifierProvider =
    StateNotifierProvider<FeatherNotifier, FeatherState>((ref) {
  final repo = ref.read(featherRepositoryProvider);
  return FeatherNotifier(repo);
});
