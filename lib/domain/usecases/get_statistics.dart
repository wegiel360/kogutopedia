import '../entities/entry.dart';
import '../repositories/entry_repository.dart';

class CharacterCount {
  final String characterName;
  final int count;

  const CharacterCount(this.characterName, this.count);
}

class DailyCount {
  final DateTime date;
  final int count;

  const DailyCount(this.date, this.count);
}

class AppStatistics {
  final int totalEntries;
  final int streakCount;
  final List<CharacterCount> characterBreakdown;
  final int totalMediaCount;
  final List<DailyCount> dailyEntries;

  const AppStatistics({
    required this.totalEntries,
    required this.streakCount,
    required this.characterBreakdown,
    required this.totalMediaCount,
    required this.dailyEntries,
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
    final dailyMap = <String, List<Entry>>{};

    for (final entry in entries) {
      characterMap[entry.characterName] =
          (characterMap[entry.characterName] ?? 0) + 1;
      if (entry.hasMedia) mediaCount++;

      final key = _dateKey(entry.entryDate);
      dailyMap.putIfAbsent(key, () => []).add(entry);
    }

    final breakdown = characterMap.entries
        .map((e) => CharacterCount(e.key, e.value))
        .toList()
      ..sort((a, b) => b.count.compareTo(a.count));

    final sortedKeys = dailyMap.keys.toList()..sort();
    final dailyEntries = sortedKeys.map((key) {
      final parts = key.split('-');
      final date = DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );
      return DailyCount(date, dailyMap[key]!.length);
    }).toList();

    return AppStatistics(
      totalEntries: entries.length,
      streakCount: streakCount,
      characterBreakdown: breakdown,
      totalMediaCount: mediaCount,
      dailyEntries: dailyEntries,
    );
  }

  String _dateKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
