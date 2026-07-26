import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../data/database/kogutopedia_db.dart';
import '../../data/models/feather_model.dart';
import 'entry_provider.dart';

class FeatherState {
  final List<FeatherModel> feathers;
  final bool isLoading;
  final String? error;

  const FeatherState({
    this.feathers = const [],
    this.isLoading = false,
    this.error,
  });

  FeatherState copyWith({
    List<FeatherModel>? feathers,
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

class FeatherNotifier extends StateNotifier<FeatherState> {
  final KogutopediaDatabase _db;
  final _uuid = const Uuid();

  FeatherNotifier(this._db) : super(const FeatherState());

  Future<void> loadFeathers() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final feathers = await _db.getFeathers();
      state = state.copyWith(feathers: feathers, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Wystąpił błąd podczas ładowania piór',
      );
    }
  }

  Future<FeatherModel?> addFeather({
    required String title,
    String? description,
    String? imagePath,
    String? characterName,
  }) async {
    try {
      final feather = FeatherModel(
        uuid: _uuid.v4(),
        createdAt: DateTime.now(),
        title: title,
        description: description,
        imagePath: imagePath,
        characterName: characterName,
      );
      final feathers = [...state.feathers, feather];
      await _db.saveFeathers(feathers);
      await loadFeathers();
      return feather;
    } catch (e) {
      state = state.copyWith(error: 'Nie udało się dodać pióra');
      return null;
    }
  }

  Future<void> deleteFeather(String uuid) async {
    try {
      final feathers = state.feathers.where((f) => f.uuid != uuid).toList();
      final deleted = state.feathers.firstWhere((f) => f.uuid == uuid);
      await _db.saveFeathers(feathers);
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
  final db = ref.read(databaseProvider);
  return FeatherNotifier(db);
});
