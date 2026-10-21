import '../entities/driver.dart';
import '../repositories/driver_repository.dart';

class GetCurrentDriver {
  final DriverRepository _repository;

  const GetCurrentDriver(this._repository);

  Future<Driver> call() => _repository.getCurrentDriver();
}
