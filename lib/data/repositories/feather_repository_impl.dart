import '../../core/errors/app_exceptions.dart';
import '../../domain/entities/feather.dart';
import '../../domain/repositories/feather_repository.dart';
import '../database/kogutopedia_db.dart';
import '../models/feather_model.dart';

class FeatherRepositoryImpl implements FeatherRepository {
  final KogutopediaDatabase _db;

  FeatherRepositoryImpl(this._db);

  static Feather _toEntity(FeatherModel model) => Feather(
        uuid: model.uuid,
        createdAt: model.createdAt,
        title: model.title,
        description: model.description,
        imagePath: model.imagePath,
        characterName: model.characterName,
      );

  static FeatherModel _toModel(Feather entity) => FeatherModel(
        uuid: entity.uuid,
        createdAt: entity.createdAt,
        title: entity.title,
        description: entity.description,
        imagePath: entity.imagePath,
        characterName: entity.characterName,
      );

  @override
  Future<List<Feather>> getAllFeathers() async {
    try {
      final models = await _db.getFeathers();
      return models.map(_toEntity).toList();
    } catch (e) {
      throw DatabaseException('Failed to fetch feathers: $e');
    }
  }

  @override
  Future<Feather> addFeather(Feather feather) async {
    try {
      final all = await _db.getFeathers();
      final updated = [...all, _toModel(feather)];
      await _db.saveFeathers(updated);
      return feather;
    } catch (e) {
      throw DatabaseException('Failed to add feather: $e');
    }
  }

  @override
  Future<void> deleteFeather(String uuid) async {
    try {
      final all = await _db.getFeathers();
      final updated = all.where((f) => f.uuid != uuid).toList();
      await _db.saveFeathers(updated);
    } catch (e) {
      throw DatabaseException('Failed to delete feather: $e');
    }
  }
}
