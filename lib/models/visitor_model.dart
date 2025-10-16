// visitor_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Visitor {
  final String id;
  final String name;
  final String company;
  final String personToVisit;
  final String purpose;
  final DateTime? checkIn;
  final DateTime? checkOut;
  String status;
  final String? photoUrl;

  Visitor({
    required this.id,
    required this.name,
    this.company = '',
    this.personToVisit = '',
    this.purpose = '',
    this.checkIn,
    this.checkOut,
    this.status = 'Expected',
    this.photoUrl,
  });

  /// Safely convert Firestore values to DateTime?
  static DateTime? _toDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is String) {
      // try parse ISO string
      try {
        return DateTime.parse(value);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  /// Factory to build Visitor from DocumentSnapshot
  factory Visitor.fromDocument(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? <String, dynamic>{};
    return Visitor(
      id: doc.id,
      name: data['name'] ?? '',
      company: data['company'] ?? '',
      personToVisit: data['personToVisit'] ?? '',
      purpose: data['purpose'] ?? '',
      checkIn: _toDateTime(data['checkIn']),
      checkOut: _toDateTime(data['checkOut']),
      status: data['status'] ?? 'Expected',
      photoUrl: data['photoUrl'],
    );
  }

  /// Map for saving to Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'company': company,
      'personToVisit': personToVisit,
      'purpose': purpose,
      // convert DateTime -> Timestamp when saving
      'checkIn': checkIn != null ? Timestamp.fromDate(checkIn!) : null,
      'checkOut': checkOut != null ? Timestamp.fromDate(checkOut!) : null,
      'status': status,
      'photoUrl': photoUrl,
    };
  }
}
