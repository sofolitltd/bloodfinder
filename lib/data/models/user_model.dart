import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

@freezed
abstract class UserModel with _$UserModel {
  const factory UserModel({
    required String uid,
    required String firstName,
    required String lastName,
    required String email,
    required String mobileNumber,
    required String gender,
    required DateTime dateOfBirth,
    required String currentAddress,
    required String district,
    required String subdistrict,
    required List<String> communities,
    required String bloodGroup,
    required bool isDonor,
    required bool isEmergencyDonor,
    required String token,
    required String createdAt,
    required bool isOnline,
    required String image,
  }) = _UserModel;

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel.fromJson({...data, 'uid': doc.id});
  }
}
