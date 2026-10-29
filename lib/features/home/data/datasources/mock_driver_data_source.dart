import '../../../../core/localization/localized_string.dart';
import '../models/driver_model.dart';

class MockDriverDataSource {
  const MockDriverDataSource();

  Future<DriverModel> getCurrentDriver() async {
    return const DriverModel(
      id: 'DR-001',
      fullName: LocalizedString(en: 'Ahmed Ali', ar: 'أحمد علي'),
    );
  }
}
