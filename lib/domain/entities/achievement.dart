class Achievement {
  final String achievementId;
  final String title;
  final String description;
  final String iconName;
  final DateTime unlockedAt;
  final bool isDailyChallenge;

  const Achievement({
    required this.achievementId,
    required this.title,
    required this.description,
    required this.iconName,
    required this.unlockedAt,
    this.isDailyChallenge = false,
  });
}
