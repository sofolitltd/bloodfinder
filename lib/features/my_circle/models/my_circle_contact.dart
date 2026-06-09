import 'package:cloud_firestore/cloud_firestore.dart';

class MyCircleContact {
  final String id;
  final String ownerId;
  final String name;
  final String phone;
  final String bloodGroup;
  final String relation;
  final bool isAppUser;
  final String? linkedUserId;
  final Timestamp createdAt;

  MyCircleContact({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.phone,
    required this.bloodGroup,
    required this.relation,
    this.isAppUser = false,
    this.linkedUserId,
    required this.createdAt,
  });

  factory MyCircleContact.fromJson(Map<String, dynamic> json) {
    return MyCircleContact(
      id: json['id'] as String,
      ownerId: json['ownerId'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String,
      bloodGroup: json['bloodGroup'] as String,
      relation: json['relation'] as String,
      isAppUser: json['isAppUser'] as bool? ?? false,
      linkedUserId: json['linkedUserId'] as String?,
      createdAt: json['createdAt'] as Timestamp,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ownerId': ownerId,
      'name': name,
      'phone': phone,
      'bloodGroup': bloodGroup,
      'relation': relation,
      'isAppUser': isAppUser,
      if (linkedUserId != null) 'linkedUserId': linkedUserId,
      'createdAt': createdAt,
    };
  }
}
