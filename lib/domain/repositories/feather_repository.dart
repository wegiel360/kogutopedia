import '../entities/feather.dart';

abstract class FeatherRepository {
  Future<List<Feather>> getAllFeathers();
  Future<Feather> addFeather(Feather feather);
  Future<void> deleteFeather(String uuid);
}
