import '../../data/models/district.dart';
import 'blood_groups_data.dart';
import 'districts_data.dart';

export 'blood_groups_data.dart';
export 'districts_data.dart';

class AppData {
  static const List<String> genders = ['Male', 'Female'];

  static List<District> get districts => AppDistricts.districts;

  static List<String> get bloodGroups => AppBloodGroups.bloodGroups;
}
