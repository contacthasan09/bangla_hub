import 'package:cloud_firestore/cloud_firestore.dart';

/*   class ServiceProviderModel {
  final String id;
  final String name;
  final String category;
  final String subCategory;
  final String description;
  final String contactName;
  final String contactPhone;
  final String contactEmail;
  final String location;
  final bool isBengaliSpeaking;
  final List<String> services;
  final String? imageUrl;
  final double rating;
  final int reviewCount;
  final DateTime createdAt;

  ServiceProviderModel({
    required this.id,
    required this.name,
    required this.category,
    required this.subCategory,
    required this.description,
    required this.contactName,
    required this.contactPhone,
    required this.contactEmail,
    required this.location,
    required this.isBengaliSpeaking,
    required this.services,
    this.imageUrl,
    this.rating = 0.0,
    this.reviewCount = 0,
    required this.createdAt,
  });

  factory ServiceProviderModel.fromMap(Map<String, dynamic> map, String id) {
    return ServiceProviderModel(
      id: id,
      name: map['name'] ?? '',
      category: map['category'] ?? '',
      subCategory: map['subCategory'] ?? '',
      description: map['description'] ?? '',
      contactName: map['contactName'] ?? '',
      contactPhone: map['contactPhone'] ?? '',
      contactEmail: map['contactEmail'] ?? '',
      location: map['location'] ?? '',
      isBengaliSpeaking: map['isBengaliSpeaking'] ?? false,
      services: List<String>.from(map['services'] ?? []),
      imageUrl: map['imageUrl'],
      rating: (map['rating'] ?? 0.0).toDouble(),
      reviewCount: (map['reviewCount'] ?? 0).toInt(),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category,
      'subCategory': subCategory,
      'description': description,
      'contactName': contactName,
      'contactPhone': contactPhone,
      'contactEmail': contactEmail,
      'location': location,
      'isBengaliSpeaking': isBengaliSpeaking,
      'services': services,
      'imageUrl': imageUrl,
      'rating': rating,
      'reviewCount': reviewCount,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  String get displayName {
    if (isBengaliSpeaking) {
      return '$name (বাংলা)';
    }
    return name;
  }
}  */