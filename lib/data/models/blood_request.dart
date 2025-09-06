import 'package:cloud_firestore/cloud_firestore.dart';

class BloodRequest {
  final String id;
  final String uid;
  final String name;
  final String mobile;
  final String bloodGroup;
  final String bag;
  final String address;
  final String district;
  final String subdistrict;
  final String date;
  final String time;
  final String? note;
  final DateTime createdAt;

  BloodRequest({
    required this.id,
    required this.uid,
    required this.name,
    required this.mobile,
    required this.bloodGroup,
    required this.bag,
    required this.address,
    required this.district,
    required this.subdistrict,
    required this.date,
    required this.time,
    this.note,
    required this.createdAt,
  });

  factory BloodRequest.fromJson(Map<String, dynamic> json) {
    return BloodRequest(
      id: json['id'] ?? '',
      uid: json['uid'] ?? '',
      name: json['name'] ?? '',
      mobile: json['mobile'] ?? '',
      bloodGroup: json['bloodGroup'] ?? '',
      bag: json['bag'] ?? '',
      address: json['address'] ?? '',
      district: json['district'] ?? '',
      subdistrict: json['subdistrict'] ?? '',
      date: json['date'] ?? '',
      time: json['time'] ?? '',
      note: json['note'],
      createdAt: (json['createdAt'] as Timestamp).toDate(),
    );
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
      'district': district,
      'subdistrict': subdistrict,
      'date': date,
      'time': time,
      'note': note,
      'createdAt': createdAt,
    };
  }
}
