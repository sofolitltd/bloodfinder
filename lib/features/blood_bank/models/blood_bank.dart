import '../../../shared/models/social_media_link.dart';

class BloodBank {
  final String name;
  final String slug;
  final String address;
  final String mobile1;
  final String? mobile2;
  final String? imageUrl;
  final String? website;
  final List<SocialMediaLink>? socialMediaLinks;
  final double? latitude;
  final double? longitude;
  final String? geohash;
  final String? locationAddress;

  BloodBank({
    required this.name,
    required this.slug,
    required this.address,
    required this.mobile1,
    this.mobile2,
    this.imageUrl,
    this.website,
    this.socialMediaLinks,
    this.latitude,
    this.longitude,
    this.geohash,
    this.locationAddress,
  });

  factory BloodBank.fromJson(Map<String, dynamic> json) {
    return BloodBank(
      name: json['name'] as String,
      slug: json['slug'] as String,
      address: json['address'] as String,
      mobile1: json['mobile1'] as String,
      mobile2: json['mobile2'] as String?,
      imageUrl: json['imageUrl'] as String?,
      website: json['website'] as String?,
      socialMediaLinks: _parseSocialMediaLinks(json),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      geohash: json['geohash'] as String?,
      locationAddress: json['locationAddress'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'slug': slug,
      'address': address,
      'mobile1': mobile1,
      if (mobile2 != null) 'mobile2': mobile2,
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (website != null) 'website': website,
      if (socialMediaLinks != null)
        'socialMediaLinks':
            socialMediaLinks!.map((l) => l.toJson()).toList(),
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (geohash != null) 'geohash': geohash,
      if (locationAddress != null) 'locationAddress': locationAddress,
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
    final ws = json['website'] as String?;
    if (ws != null && ws.isNotEmpty) {
      legacy.add(SocialMediaLink(platform: 'Website', url: ws));
    }
    return legacy.isNotEmpty ? legacy : null;
  }
}
