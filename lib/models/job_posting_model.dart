/* import 'package:cloud_firestore/cloud_firestore.dart';

class JobPostingModel {
  final String id;
  final String title;
  final String company;
  final String description;
  final String location;
  final String workHours;
  final String wages;
  final List<String> facilities;
  final String contactEmail;
  final String contactPhone;
  final String postedBy;
  final DateTime postedAt;
  final bool isActive;

  JobPostingModel({
    required this.id,
    required this.title,
    required this.company,
    required this.description,
    required this.location,
    required this.workHours,
    required this.wages,
    required this.facilities,
    required this.contactEmail,
    required this.contactPhone,
    required this.postedBy,
    required this.postedAt,
    this.isActive = true,
  });

  factory JobPostingModel.fromMap(Map<String, dynamic> map, String id) {
    return JobPostingModel(
      id: id,
      title: map['title'] ?? '',
      company: map['company'] ?? '',
      description: map['description'] ?? '',
      location: map['location'] ?? '',
      workHours: map['workHours'] ?? '',
      wages: map['wages'] ?? '',
      facilities: List<String>.from(map['facilities'] ?? []),
      contactEmail: map['contactEmail'] ?? '',
      contactPhone: map['contactPhone'] ?? '',
      postedBy: map['postedBy'] ?? '',
      postedAt: (map['postedAt'] as Timestamp).toDate(),
      isActive: map['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'company': company,
      'description': description,
      'location': location,
      'workHours': workHours,
      'wages': wages,
      'facilities': facilities,
      'contactEmail': contactEmail,
      'contactPhone': contactPhone,
      'postedBy': postedBy,
      'postedAt': Timestamp.fromDate(postedAt),
      'isActive': isActive,
    };
  }

  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(postedAt);
    
    if (difference.inDays == 0) {
      return 'Posted today';
    } else if (difference.inDays == 1) {
      return 'Posted yesterday';
    } else if (difference.inDays < 7) {
      return 'Posted ${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      return 'Posted ${(difference.inDays / 7).floor()} weeks ago';
    } else {
      return DateFormat('MMM d, y').format(postedAt);
    }
  }
}  */