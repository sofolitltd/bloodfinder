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
    // Optional because an admin can add a donor with only a phone number.
    String? email,
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
    // Country derived from coordinates
    String? country,
    // Saved addresses for the user
    @Default([]) List<AddressModel> savedAddresses,
    // Firebase Auth UID once this person has their own account. Null for a
    // record a superadmin/community admin added manually before that.
    String? authUid,
    // "unclaimed" for an admin-added record with no Firebase Auth account
    // yet; "active" once self-registered or claimed via signup.
    @Default('active') String accountStatus,
    @Default('self') String createdBy,
    String? createdByAdminEmail,
  }) = _UserModel;

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel.fromJson({...data, 'uid': doc.id});
  }
}
