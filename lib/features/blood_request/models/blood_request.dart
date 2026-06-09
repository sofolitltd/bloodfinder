import 'package:cloud_firestore/cloud_firestore.dart';

class BloodRequest {
  final String id;
  final String uid;
  final String name;
  final String mobile;
  final String bloodGroup;
  final String bag;
  final String address;
  final double? latitude;
  final double? longitude;
  final String? locationAddress;
  final String? geohash;
  final String date;
  final String time;
  final String? note;
  final String status;
  final DateTime createdAt;

  BloodRequest({
    required this.id,
    required this.uid,
    required this.name,
    required this.mobile,
    required this.bloodGroup,
    required this.bag,
    required this.address,
    this.latitude,
    this.longitude,
    this.locationAddress,
    this.geohash,
    required this.date,
    required this.time,
    this.note,
    this.status = 'active',
    required this.createdAt,
  });

  bool get isActive => status == 'active';
  bool get isFulfilled => status == 'fulfilled';
  bool get isCancelled => status == 'cancelled';

  factory BloodRequest.fromJson(Map<String, dynamic> json) {
    return BloodRequest(
      id: json['id'] ?? '',
      uid: json['uid'] ?? '',
      name: json['name'] ?? '',
      mobile: json['mobile'] ?? '',
      bloodGroup: json['bloodGroup'] ?? '',
      bag: json['bag'] ?? '',
      address: json['address'] ?? '',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      locationAddress: json['locationAddress'] as String?,
      geohash: json['geohash'] as String?,
      date: json['date'] ?? '',
      time: json['time'] ?? '',
      note: json['note'],
      status: json['status'] as String? ?? 'active',
      createdAt: (json['createdAt'] as Timestamp).toDate(),
    );
  }

  factory BloodRequest.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return BloodRequest.fromJson({...data, 'id': doc.id});
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'uid': uid,
      'name': name,
      'mobile': mobile,
      'bloodGroup': bloodGroup,
      'bag': bag,
      'address': address,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (locationAddress != null) 'locationAddress': locationAddress,
      if (geohash != null) 'geohash': geohash,
      'date': date,
      'time': time,
      'status': status,
      'note': note,
      'createdAt': createdAt,
    };
  }
}
