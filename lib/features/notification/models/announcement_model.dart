import 'package:cloud_firestore/cloud_firestore.dart';

/// Model for admin announcements shown on the "Announcements" tab.
class AnnouncementModel {
  final String id;
  final String title;
  final String body;
  final String type;
  final String target;
  final String? country;
  final DateTime createdAt;

  AnnouncementModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.target,
    this.country,
    required this.createdAt,
  });

  factory AnnouncementModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AnnouncementModel(
      id: doc.id,
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      type: data['type'] ?? '',
      target: data['target'] ?? '',
      country: data['country'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
