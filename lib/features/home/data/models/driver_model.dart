import '../../../../core/localization/localized_string.dart';
import '../../domain/entities/driver.dart';

class DriverModel {
  final String id;
  final LocalizedString fullName;

  const DriverModel({this.id = 'DR-001', required this.fullName});

  Driver toEntity() => Driver(id: id, fullName: fullName);
}
