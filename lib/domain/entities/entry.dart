class Entry {
  final String uuid;
  final DateTime createdAt;
  final DateTime entryDate;
  final String characterName;
  final String title;
  final String? description;
  final String? mediaPath;
  final String? mediaType;

  const Entry({
    required this.uuid,
    required this.createdAt,
    required this.entryDate,
    required this.characterName,
    required this.title,
    this.description,
    this.mediaPath,
    this.mediaType,
  });

  Entry copyWith({
    String? uuid,
    DateTime? createdAt,
    DateTime? entryDate,
    String? characterName,
    String? title,
    String? description,
    String? mediaPath,
    String? mediaType,
  }) {
    return Entry(
      uuid: uuid ?? this.uuid,
      createdAt: createdAt ?? this.createdAt,
      entryDate: entryDate ?? this.entryDate,
      characterName: characterName ?? this.characterName,
      title: title ?? this.title,
      description: description ?? this.description,
      mediaPath: mediaPath ?? this.mediaPath,
      mediaType: mediaType ?? this.mediaType,
    );
  }

  bool get hasDescription => description != null && description!.isNotEmpty;
  bool get hasMedia => mediaPath != null && mediaPath!.isNotEmpty;
  bool get isImage => mediaType == 'image';
  bool get isVideo => mediaType == 'video';
}
