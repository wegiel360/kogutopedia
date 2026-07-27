class Feather {
  final String uuid;
  final DateTime createdAt;
  final String title;
  final String? description;
  final String? imagePath;
  final String? characterName;

  const Feather({
    required this.uuid,
    required this.createdAt,
    required this.title,
    this.description,
    this.imagePath,
    this.characterName,
  });

  Feather copyWith({
    String? uuid,
    DateTime? createdAt,
    String? title,
    String? description,
    String? imagePath,
    String? characterName,
  }) {
    return Feather(
      uuid: uuid ?? this.uuid,
      createdAt: createdAt ?? this.createdAt,
      title: title ?? this.title,
      description: description ?? this.description,
      imagePath: imagePath ?? this.imagePath,
      characterName: characterName ?? this.characterName,
    );
  }
}
