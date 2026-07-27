class Entry {
  final String uuid;
  final DateTime createdAt;
  final DateTime entryDate;
  final String characterName;
  final String title;
  final String? description;
  final List<String> mediaPaths;
  final List<String> mediaTypes;

  const Entry({
    required this.uuid,
    required this.createdAt,
    required this.entryDate,
    required this.characterName,
    required this.title,
    this.description,
    this.mediaPaths = const [],
    this.mediaTypes = const [],
  });

  Entry copyWith({
    String? uuid,
    DateTime? createdAt,
    DateTime? entryDate,
    String? characterName,
    String? title,
    String? description,
    List<String>? mediaPaths,
    List<String>? mediaTypes,
  }) {
    return Entry(
      uuid: uuid ?? this.uuid,
      createdAt: createdAt ?? this.createdAt,
      entryDate: entryDate ?? this.entryDate,
      characterName: characterName ?? this.characterName,
      title: title ?? this.title,
      description: description ?? this.description,
      mediaPaths: mediaPaths ?? this.mediaPaths,
      mediaTypes: mediaTypes ?? this.mediaTypes,
    );
  }

  bool get hasDescription => description != null && description!.isNotEmpty;
  bool get hasMedia => mediaPaths.isNotEmpty;
  bool get isImage => mediaTypes.isNotEmpty && mediaTypes.first == 'image';
  bool get isVideo => mediaTypes.isNotEmpty && mediaTypes.first == 'video';
  String? get primaryMediaPath => mediaPaths.isNotEmpty ? mediaPaths.first : null;
  String? get primaryMediaType => mediaTypes.isNotEmpty ? mediaTypes.first : null;
}
