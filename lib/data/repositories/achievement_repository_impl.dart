import 'package:isar/isar.dart';
import '../../core/errors/app_exceptions.dart';
import '../../domain/entities/achievement.dart';
import '../../domain/repositories/achievement_repository.dart';
import '../database/kogutopedia_db.dart';
import '../models/achievement_model.dart';

class AchievementRepositoryImpl implements AchievementRepository {
  final KogutopediaDatabase _db;

  AchievementRepositoryImpl(this._db);

  @override
  Future<List<Achievement>> getAllAchievements() async {
    try {
      final models = await _db.isar.achievementModels
          .where()
          .sortByUnlockedAtDesc()
          .findAll();
      return models.map(_toEntity).toList();
    } catch (e) {
      throw DatabaseException('Failed to fetch achievements: $e');
    }
  }

  @override
  Future<bool> isAchievementUnlocked(String achievementId) async {
    try {
      final result = await _db.isar.achievementModels
          .filter()
          .achievementIdEqualTo(achievementId)
          .findFirst();
      return result != null;
    } catch (e) {
      throw DatabaseException('Failed to check achievement: $e');
    }
  }

  @override
  Future<Achievement> unlockAchievement(Achievement achievement) async {
    try {
      final existing = await _db.isar.achievementModels
          .filter()
          .achievementIdEqualTo(achievement.achievementId)
          .findFirst();
      if (existing != null) return _toEntity(existing);

      final model = _toModel(achievement);
      await _db.isar.writeTxn(() async {
        await _db.isar.achievementModels.put(model);
      });
      return _toEntity(model);
    } catch (e) {
      throw DatabaseException('Failed to unlock achievement: $e');
    }
  }

  @override
  Future<int> getAchievementCount() async {
    try {
      return await _db.isar.achievementModels.count();
    } catch (e) {
      throw DatabaseException('Failed to count achievements: $e');
    }
  }

  @override
  Future<void> clearDailyChallenge() async {
    try {
      final dailyChallenges = await _db.isar.achievementModels
          .filter()
          .isDailyChallengeEqualTo(true)
          .findAll();
      await _db.isar.writeTxn(() async {
        await _db.isar.achievementModels.deleteAll(
          dailyChallenges.map((e) => e.id).toList(),
        );
      });
    } catch (e) {
      throw DatabaseException('Failed to clear daily challenges: $e');
    }
  }

  Achievement _toEntity(AchievementModel model) {
    return Achievement(
      achievementId: model.achievementId,
      title: model.title,
      description: model.description,
      iconName: model.iconName,
      unlockedAt: model.unlockedAt,
      isDailyChallenge: model.isDailyChallenge,
    );
  }

  AchievementModel _toModel(Achievement achievement) {
    return AchievementModel(
      achievementId: achievement.achievementId,
      title: achievement.title,
      description: achievement.description,
      iconName: achievement.iconName,
      unlockedAt: achievement.unlockedAt,
      isDailyChallenge: achievement.isDailyChallenge,
    );
  }
}
