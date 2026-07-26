class AchievementModel {
  final int? id;
  final String achievementId;
  final String title;
  final String description;
  final String iconName;
  final DateTime unlockedAt;
  final bool isDailyChallenge;

  AchievementModel({
    this.id,
    required this.achievementId,
    required this.title,
    required this.description,
    required this.iconName,
    required this.unlockedAt,
    this.isDailyChallenge = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'achievementId': achievementId,
        'title': title,
        'description': description,
        'iconName': iconName,
        'unlockedAt': unlockedAt.toIso8601String(),
        'isDailyChallenge': isDailyChallenge,
      };

  factory AchievementModel.fromJson(Map<String, dynamic> json) =>
      AchievementModel(
        id: json['id'] as int?,
        achievementId: json['achievementId'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
        iconName: json['iconName'] as String,
        unlockedAt: DateTime.parse(json['unlockedAt'] as String),
        isDailyChallenge: json['isDailyChallenge'] as bool? ?? false,
      );
}
