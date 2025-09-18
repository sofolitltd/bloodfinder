import '/data/models/blood_request.dart';
import '/data/models/user_model.dart';

class BloodRequestWithUser {
  final BloodRequest request;
  final UserModel user;

  BloodRequestWithUser({required this.request, required this.user});
}
