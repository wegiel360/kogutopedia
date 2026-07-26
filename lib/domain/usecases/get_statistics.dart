import '../entities/entry.dart';
import '../repositories/entry_repository.dart';

class CharacterCount {
  final String characterName;
  final int count;

  const CharacterCount(this.characterName, this.count);
}

class AppStatistics {
  final int totalEntries;
  final int streakCount;
  final List<CharacterCount> characterBreakdown;
  final int totalMediaCount;

  const AppStatistics({
    required this.totalEntries,
    required this.streakCount,
    required this.characterBreakdown,
    required this.totalMediaCount,
  });
}

class GetStatisticsUseCase {
  final EntryRepository _repository;

  GetStatisticsUseCase(this._repository);

  Future<AppStatistics> call() async {
    final entries = await _repository.getAllEntries();
    final streakCount = await _repository.getStreakCount();

    final characterMap = <String, int>{};
    int mediaCount = 0;

    for (final entry in entries) {
      characterMap[entry.characterName] =
          (characterMap[entry.characterName] ?? 0) + 1;
      if (entry.hasMedia) mediaCount++;
    }

    final breakdown = characterMap.entries
        .map((e) => CharacterCount(e.key, e.value))
        .toList()
      ..sort((a, b) => b.count.compareTo(a.count));

    return AppStatistics(
      totalEntries: entries.length,
      streakCount: streakCount,
      characterBreakdown: breakdown,
      totalMediaCount: mediaCount,
    );
  }
}
