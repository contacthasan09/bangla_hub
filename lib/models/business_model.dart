import 'package:cloud_firestore/cloud_firestore.dart';

class BusinessModel {
  final String id;
  final String name;
  final String category;
  final String description;
  final String ownerName;
  final String contactPhone;
  final String contactEmail;
  final String location;
  final List<String> services;
  final String? logoUrl;
  final double rating;
  final int reviewCount;
  final bool isVerified;
  final DateTime createdAt;

  BusinessModel({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.ownerName,
    required this.contactPhone,
    required this.contactEmail,
    required this.location,
    required this.services,
    this.logoUrl,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.isVerified = false,
    required this.createdAt,
  });

  factory BusinessModel.fromMap(Map<String, dynamic> map, String id) {
    return BusinessModel(
      id: id,
      name: map['name'] ?? '',
      category: map['category'] ?? '',
      description: map['description'] ?? '',
      ownerName: map['ownerName'] ?? '',
      contactPhone: map['contactPhone'] ?? '',
      contactEmail: map['contactEmail'] ?? '',
      location: map['location'] ?? '',
      services: List<String>.from(map['services'] ?? []),
      logoUrl: map['logoUrl'],
      rating: (map['rating'] ?? 0.0).toDouble(),
      reviewCount: (map['reviewCount'] ?? 0).toInt(),
      isVerified: map['isVerified'] ?? false,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category,
      'description': description,
      'ownerName': ownerName,
      'contactPhone': contactPhone,
      'contactEmail': contactEmail,
      'location': location,
      'services': services,
      'logoUrl': logoUrl,
      'rating': rating,
      'reviewCount': reviewCount,
      'isVerified': isVerified,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

class BusinessPartnerRequest {
  final String id;
  final String description;
  final String contactDetails;
  final String budget;
  final String partnerType;
  final String postedBy;
  final DateTime postedAt;

  BusinessPartnerRequest({
    required this.id,
    required this.description,
    required this.contactDetails,
    required this.budget,
    required this.partnerType,
    required this.postedBy,
    required this.postedAt,
  });

  factory BusinessPartnerRequest.fromMap(Map<String, dynamic> map, String id) {
    return BusinessPartnerRequest(
      id: id,
      description: map['description'] ?? '',
      contactDetails: map['contactDetails'] ?? '',
      budget: map['budget'] ?? '',
      partnerType: map['partnerType'] ?? '',
      postedBy: map['postedBy'] ?? '',
      postedAt: (map['postedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'description': description,
      'contactDetails': contactDetails,
      'budget': budget,
      'partnerType': partnerType,
      'postedBy': postedBy,
      'postedAt': Timestamp.fromDate(postedAt),
    };
  }
}