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
  communities: (json['communities'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  bloodGroup: json['bloodGroup'] as String,
  isDonor: json['isDonor'] as bool,
  isEmergencyDonor: json['isEmergencyDonor'] as bool,
  token: json['token'] as String,
  createdAt: json['createdAt'] as String,
  isOnline: json['isOnline'] as bool,
  image: json['image'] as String,
  latitude: (json['latitude'] as num?)?.toDouble(),
  longitude: (json['longitude'] as num?)?.toDouble(),
  geohash: json['geohash'] as String?,
  locationAddress: json['locationAddress'] as String?,
  country: json['country'] as String?,
  savedAddresses:
      (json['savedAddresses'] as List<dynamic>?)
          ?.map((e) => AddressModel.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
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
      'communities': instance.communities,
      'bloodGroup': instance.bloodGroup,
      'isDonor': instance.isDonor,
      'isEmergencyDonor': instance.isEmergencyDonor,
      'token': instance.token,
      'createdAt': instance.createdAt,
      'isOnline': instance.isOnline,
      'image': instance.image,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'geohash': instance.geohash,
      'locationAddress': instance.locationAddress,
      'country': instance.country,
      'savedAddresses': instance.savedAddresses.map((e) => e.toJson()).toList(),
    };
