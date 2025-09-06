import 'package:cloud_firestore/cloud_firestore.dart';

class Community {
  final String id;
  final String code;
  final String name;
  final String mobile;
  final String district;
  final String subDistrict;
  final String address;
  final List<String> members;
  final List<String> admin;
  final List<String> joinRequests;
  final String? facebook;
  final String? whatsapp;
  final Timestamp createdAt;

  Community({
    required this.id,
    required this.code,
    required this.name,
    required this.mobile,
    required this.district,
    required this.subDistrict,
    required this.address,
    this.members = const [],
    this.admin = const [],
    this.joinRequests = const [],
    this.facebook,
    this.whatsapp,
    required this.createdAt,
  });

  factory Community.fromJson(Map<String, dynamic> json) {
    return Community(
      id: json['id'] as String,
      code: json['code'] as String,
      name: json['name'] as String,
      mobile: json['mobile'] as String,
      district: json['district'] as String,
      subDistrict: json['subDistrict'] as String,
      address: json['address'] as String,
      members: List<String>.from(json['members'] ?? []),
      admin: List<String>.from(json['admin'] ?? []),
      joinRequests: List<String>.from(json['joinRequests'] ?? []),
      // Safely handle nullable fields by using the null-aware cast `as String?`
      facebook: json['facebook'] as String?,
      whatsapp: json['whatsapp'] as String?,
      createdAt: json['createdAt'] as Timestamp,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'mobile': mobile,
      'district': district,
      'subDistrict': subDistrict,
      'address': address,
      'members': members,
      'admin': admin,
      'joinRequests': joinRequests,
      'facebook': facebook,
      'whatsapp': whatsapp,
      'createdAt': createdAt,
    };
  }
}
