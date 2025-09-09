import 'package:cloud_firestore/cloud_firestore.dart';

class Community {
  final String id;
  final String code;
  final String name;
  final String mobile;
  final String district;
  final String subDistrict;
  final String address;
  final List<String> admin;
  final String? facebook;
  final String? whatsapp;
  final int memberCount;
  final Timestamp createdAt;
  final List<String> images;

  Community({
    required this.id,
    required this.code,
    required this.name,
    required this.mobile,
    required this.district,
    required this.subDistrict,
    required this.address,
    this.admin = const [],
    this.facebook,
    this.whatsapp,
    required this.memberCount,
    required this.createdAt,
    required this.images,
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
      admin: List<String>.from(json['admin'] ?? []),
      facebook: json['facebook'] as String?,
      whatsapp: json['whatsapp'] as String?,
      memberCount: json['memberCount'] as int,
      createdAt: json['createdAt'] as Timestamp,
      images: List<String>.from(json['images'] ?? []),
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
      'admin': admin,
      'facebook': facebook,
      'whatsapp': whatsapp,
      'memberCount': memberCount,
      'createdAt': createdAt,
      'images': images,
    };
  }
}
