import '../../domain/entities/driver.dart';
import '../../domain/repositories/driver_repository.dart';
import '../datasources/mock_driver_data_source.dart';

class DriverRepositoryImpl implements DriverRepository {
  final MockDriverDataSource _dataSource;

  const DriverRepositoryImpl(this._dataSource);

  @override
  Future<Driver> getCurrentDriver() async {
    final model = await _dataSource.getCurrentDriver();
    return model.toEntity();
  }
}
