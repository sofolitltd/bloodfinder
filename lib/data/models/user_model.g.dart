// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_UserModel _$UserModelFromJson(Map<String, dynamic> json) => _UserModel(
  uid: json['uid'] as String,
  firstName: json['firstName'] as String,
  lastName: json['lastName'] as String,
  email: json['email'] as String,
  mobileNumber: json['mobileNumber'] as String,
  gender: json['gender'] as String,
  dateOfBirth: DateTime.parse(json['dateOfBirth'] as String),
  currentAddress: json['currentAddress'] as String,
  district: json['district'] as String,
  subdistrict: json['subdistrict'] as String,
  communities: (json['communities'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  bloodGroup: json['bloodGroup'] as String,
  isDonor: json['isDonor'] as bool,
  isEmergencyDonor: json['isEmergencyDonor'] as bool,
  token: json['token'] as String,
  createdAt: json['createdAt'] as String?,
  isOnline: json['isOnline'] as bool,
  image: json['image'] as String,
);

Map<String, dynamic> _$UserModelToJson(_UserModel instance) =>
    <String, dynamic>{
      'uid': instance.uid,
      'firstName': instance.firstName,
      'lastName': instance.lastName,
      'email': instance.email,
      'mobileNumber': instance.mobileNumber,
      'gender': instance.gender,
      'dateOfBirth': instance.dateOfBirth.toIso8601String(),
      'currentAddress': instance.currentAddress,
      'district': instance.district,
      'subdistrict': instance.subdistrict,
      'communities': instance.communities,
      'bloodGroup': instance.bloodGroup,
      'isDonor': instance.isDonor,
      'isEmergencyDonor': instance.isEmergencyDonor,
      'token': instance.token,
      'createdAt': instance.createdAt,
      'isOnline': instance.isOnline,
      'image': instance.image,
    };
