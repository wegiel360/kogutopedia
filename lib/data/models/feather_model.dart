class FeatherModel {
  final String uuid;
  final DateTime createdAt;
  final String title;
  final String? description;
  final String? imagePath;
  final String? characterName;

  FeatherModel({
    required this.uuid,
    required this.createdAt,
    required this.title,
    this.description,
    this.imagePath,
    this.characterName,
  });

  Map<String, dynamic> toJson() => {
        'uuid': uuid,
        'createdAt': createdAt.toIso8601String(),
        'title': title,
        'description': description,
        'imagePath': imagePath,
        'characterName': characterName,
      };

  factory FeatherModel.fromJson(Map<String, dynamic> json) => FeatherModel(
        uuid: json['uuid'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        title: json['title'] as String,
        description: json['description'] as String?,
        imagePath: json['imagePath'] as String?,
        characterName: json['characterName'] as String?,
      );
}
