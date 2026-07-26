import 'package:isar/isar.dart';

part 'entry_model.g.dart';

@collection
class EntryModel {
  Id id = Isar.autoIncrement;
  late String uuid;
  late DateTime createdAt;
  late DateTime entryDate;
  late String characterName;
  late String title;
  String? description;
  String? mediaPath;
  String? mediaType; // 'image' or 'video'
  late bool synced;

  @Index()
  late String dateKey;

  EntryModel({
    required this.uuid,
    required this.createdAt,
    required this.entryDate,
    required this.characterName,
    required this.title,
    this.description,
    this.mediaPath,
    this.mediaType,
    this.synced = false,
    String? dateKey,
  }) : dateKey = dateKey ?? _formatDateKey(entryDate);

  static String _formatDateKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
