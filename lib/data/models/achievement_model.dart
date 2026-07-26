import 'package:isar/isar.dart';

part 'achievement_model.g.dart';

@collection
class AchievementModel {
  Id id = Isar.autoIncrement;
  late String achievementId;
  late String title;
  late String description;
  late String iconName;
  late DateTime unlockedAt;
  late bool isDailyChallenge;

  AchievementModel({
    required this.achievementId,
    required this.title,
    required this.description,
    required this.iconName,
    required this.unlockedAt,
    this.isDailyChallenge = false,
  });
}
