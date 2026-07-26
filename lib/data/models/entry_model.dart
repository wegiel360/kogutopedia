class EntryModel {
  final int? id;
  final String uuid;
  final DateTime createdAt;
  final DateTime entryDate;
  final String characterName;
  final String title;
  final String? description;
  final String? mediaPath;
  final String? mediaType;
  final String dateKey;

  EntryModel({
    this.id,
    required this.uuid,
    required this.createdAt,
    required this.entryDate,
    required this.characterName,
    required this.title,
    this.description,
    this.mediaPath,
    this.mediaType,
    String? dateKey,
  }) : dateKey = dateKey ?? _formatDateKey(entryDate);

  static String _formatDateKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  Map<String, dynamic> toJson() => {
        'id': id,
        'uuid': uuid,
        'createdAt': createdAt.toIso8601String(),
        'entryDate': entryDate.toIso8601String(),
        'characterName': characterName,
        'title': title,
        'description': description,
        'mediaPath': mediaPath,
        'mediaType': mediaType,
        'dateKey': dateKey,
      };

  factory EntryModel.fromJson(Map<String, dynamic> json) => EntryModel(
        id: json['id'] as int?,
        uuid: json['uuid'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        entryDate: DateTime.parse(json['entryDate'] as String),
        characterName: json['characterName'] as String,
        title: json['title'] as String,
        description: json['description'] as String?,
        mediaPath: json['mediaPath'] as String?,
        mediaType: json['mediaType'] as String?,
        dateKey: json['dateKey'] as String?,
      );
}
