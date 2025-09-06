import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String firstName;
  final String lastName;
  final String email;
  final String mobileNumber;
  final String gender;
  final DateTime dateOfBirth;
  final List<UserAddress> address;
  final List<String> communities;
  final String bloodGroup;
  final bool isDonor;
  final bool isEmergencyDonor;
  final String token;
  final Timestamp? createdAt;
  final bool isOnline;
  final bool isTyping;

  UserModel({
    required this.uid,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.mobileNumber,
    required this.gender,
    required this.dateOfBirth,
    required this.address,
    required this.communities,
    required this.bloodGroup,
    required this.isDonor,
    required this.isEmergencyDonor,
    required this.token,
    this.createdAt,
    required this.isOnline,
    required this.isTyping,
  });

  // Factory constructor to create a User from a Firestore document
  factory UserModel.fromMap(Map<String, dynamic> data, String uid) {
    return UserModel(
      uid: uid,
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      email: data['email'] ?? '',
      mobileNumber: data['mobileNumber'] ?? '',
      gender: data['gender'] ?? '',
      dateOfBirth: DateTime.parse(
        data['dateOfBirth'] ?? '1970-01-01T00:00:00Z',
      ),
      address: (data['address'] as List? ?? [])
          .map((addr) => UserAddress.fromMap(addr))
          .toList(),
      communities:
          (data['communities'] as List<dynamic>?)
              ?.map((item) => item.toString())
              .toList() ??
          [],
      bloodGroup: data['bloodGroup'] ?? '',
      isDonor: data['isDonor'] ?? false,
      isEmergencyDonor: data['isEmergencyDonor'] ?? false,
      token: data['token'] ?? '',
      createdAt: data['createdAt'] as Timestamp?,
      isOnline: data['isOnline'] ?? false,
      isTyping: data['isTyping'] ?? false,
    );
  }

  // Method to convert the User object to a map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'mobileNumber': mobileNumber,
      'gender': gender,
      'dateOfBirth': dateOfBirth.toIso8601String(),
      'address': address.map((addr) => addr.toMap()).toList(),
      'communities': communities,
      'bloodGroup': bloodGroup,
      'isDonor': isDonor,
      'isEmergencyDonor': isEmergencyDonor,
      'token': token,
      'createdAt': FieldValue.serverTimestamp(),
      'isOnline': isOnline,
      'isTyping': isTyping,
    };
  }
}

// Model for the nested Address object
class UserAddress {
  final String type;
  final String currentAddress;
  final String district;
  final String subdistrict;

  UserAddress({
    required this.type,
    required this.currentAddress,
    required this.district,
    required this.subdistrict,
  });

  factory UserAddress.fromMap(Map<String, dynamic> data) {
    return UserAddress(
      type: data['type'] ?? '',
      currentAddress: data['currentAddress'] ?? '',
      district: data['district'] ?? '',
      subdistrict: data['subdistrict'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'currentAddress': currentAddress,
      'district': district,
      'subdistrict': subdistrict,
    };
  }
}
