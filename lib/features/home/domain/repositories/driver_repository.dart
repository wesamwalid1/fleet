import '../entities/driver.dart';

abstract class DriverRepository {
  Future<Driver> getCurrentDriver();
}
