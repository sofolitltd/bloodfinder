import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class BloodEvent {
  final String id;
  final String title;
  final String organizerName;
  final String organizerUid;
  final String description;
  final double latitude;
  final double longitude;
  final String geohash;
  final String locationAddress;
  final DateTime eventDate;
  final DateTime? endDate;
  final String? imageUrl;
  final int rsvpCount;
  final String country;
  final DateTime createdAt;

  BloodEvent({
    required this.id,
    required this.title,
    required this.organizerName,
    required this.organizerUid,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.geohash,
    required this.locationAddress,
    required this.eventDate,
    this.endDate,
    this.imageUrl,
    this.rsvpCount = 0,
    this.country = '',
    required this.createdAt,
  });

  bool get isMultiDay =>
      endDate != null && !_isSameDay(eventDate, endDate!);

  String get dateDisplay {
    if (!isMultiDay) {
      return DateFormat('MMM dd, yyyy').format(eventDate);
    }
    return '${DateFormat('MMM dd').format(eventDate)} - ${DateFormat('MMM dd, yyyy').format(endDate!)}';
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  factory BloodEvent.fromJson(Map<String, dynamic> json) {
    return BloodEvent(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      organizerName: json['organizerName'] as String? ?? '',
      organizerUid: json['organizerUid'] as String? ?? '',
      description: json['description'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      geohash: json['geohash'] as String? ?? '',
      locationAddress: json['locationAddress'] as String? ?? '',
      eventDate: (json['eventDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: (json['endDate'] as Timestamp?)?.toDate(),
      imageUrl: json['imageUrl'] as String?,
      rsvpCount: (json['rsvpCount'] as num?)?.toInt() ?? 0,
      country: json['country'] as String? ?? '',
      createdAt:
          (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'organizerName': organizerName,
        'organizerUid': organizerUid,
        'description': description,
        'latitude': latitude,
        'longitude': longitude,
        'geohash': geohash,
        'locationAddress': locationAddress,
        'eventDate': Timestamp.fromDate(eventDate),
        if (endDate != null) 'endDate': Timestamp.fromDate(endDate!),
        'imageUrl': imageUrl,
        'rsvpCount': rsvpCount,
        'country': country,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}
