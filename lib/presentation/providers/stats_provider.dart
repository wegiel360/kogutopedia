import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/usecases/get_statistics.dart';
import 'entry_provider.dart';

class StatsState {
  final AppStatistics? statistics;
  final bool isLoading;
  final String? error;

  const StatsState({
    this.statistics,
    this.isLoading = false,
    this.error,
  });

  StatsState copyWith({
    AppStatistics? statistics,
    bool? isLoading,
    String? error,
  }) {
    return StatsState(
      statistics: statistics ?? this.statistics,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class StatsNotifier extends StateNotifier<StatsState> {
  final GetStatisticsUseCase _getStatistics;

  StatsNotifier(this._getStatistics) : super(const StatsState());

  Future<void> loadStatistics() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final stats = await _getStatistics();
      state = state.copyWith(statistics: stats, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Nie udało się załadować statystyk',
      );
    }
  }
}

final statsNotifierProvider =
    StateNotifierProvider<StatsNotifier, StatsState>((ref) {
  final getStats = ref.read(getStatisticsUseCaseProvider);
  return StatsNotifier(getStats);
});
