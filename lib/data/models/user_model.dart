import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:freezed_annotation/freezed_annotation.dart';

import 'address_model.dart';

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
    required List<String> communities,
    required String bloodGroup,
    required bool isDonor,
    required bool isEmergencyDonor,
    required String token,
    required String createdAt,
    required bool isOnline,
    required String image,
    // Location fields — used for geohash proximity search
    double? latitude,
    double? longitude,
    String? geohash,
    // Human-readable address from reverse geocoding (display only, never queried)
    String? locationAddress,
    // Saved addresses for the user
    @Default([]) List<AddressModel> savedAddresses,
  }) = _UserModel;

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel.fromJson({...data, 'uid': doc.id});
  }
}
