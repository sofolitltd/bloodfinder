import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../shared/models/social_media_link.dart';

class Community {
  final String id;
  final String code;
  final String name;
  final String mobile;
  final String address;
  final double? latitude;
  final double? longitude;
  final String? locationAddress;
  final String? geohash;
  final List<String> admin;
  final List<SocialMediaLink>? socialMediaLinks;
  final int memberCount;
  final Timestamp createdAt;
  final List<String> images;
  final Map<String, int>? bloodGroupCounts;

  Community({
    required this.id,
    required this.code,
    required this.name,
    required this.mobile,
    required this.address,
    this.latitude,
    this.longitude,
    this.locationAddress,
    this.geohash,
    this.admin = const [],
    this.socialMediaLinks,
    required this.memberCount,
    required this.createdAt,
    required this.images,
    this.bloodGroupCounts,
  });

  factory Community.fromJson(Map<String, dynamic> json) {
    return Community(
      id: json['id'] as String,
      code: json['code'] as String,
      name: json['name'] as String,
      mobile: json['mobile'] as String,
      address: json['address'] as String,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      locationAddress: json['locationAddress'] as String?,
      geohash: json['geohash'] as String?,
      admin: List<String>.from(json['admin'] ?? []),
      socialMediaLinks: _parseSocialMediaLinks(json),
      memberCount: json['memberCount'] as int,
      createdAt: json['createdAt'] as Timestamp,
      images: List<String>.from(json['images'] ?? []),
      bloodGroupCounts: (json['bloodGroupCounts'] as Map<String, dynamic>?)
          ?.map((k, v) => MapEntry(k, (v as num).toInt())),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'mobile': mobile,
      'address': address,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (locationAddress != null) 'locationAddress': locationAddress,
      if (geohash != null) 'geohash': geohash,
      'admin': admin,
      if (socialMediaLinks != null)
        'socialMediaLinks':
            socialMediaLinks!.map((l) => l.toJson()).toList(),
      'memberCount': memberCount,
      'createdAt': createdAt,
      'images': images,
      if (bloodGroupCounts != null) 'bloodGroupCounts': bloodGroupCounts,
    };
  }

  static List<SocialMediaLink>? _parseSocialMediaLinks(
      Map<String, dynamic> json) {
    if (json['socialMediaLinks'] != null) {
      return (json['socialMediaLinks'] as List)
          .map((e) =>
              SocialMediaLink.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    final legacy = <SocialMediaLink>[];
    final fb = json['facebook'] as String?;
    if (fb != null && fb.isNotEmpty) {
      legacy.add(SocialMediaLink(platform: 'Facebook', url: fb));
    }
    final wa = json['whatsapp'] as String?;
    if (wa != null && wa.isNotEmpty) {
      legacy.add(SocialMediaLink(platform: 'WhatsApp', url: wa));
    }
    return legacy.isNotEmpty ? legacy : null;
  }
}
