// models/community_services_models.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:convert';

// Predefined States
class CommunityStates {
  static const List<String> states = [
    'Florida',
    'Georgia',
    'South Carolina',
    'North Carolina',
    'Virginia',
    'New York',
    'New Jersey',
    'Alabama',
    'Tennessee',
    'Texas',
    'California',
    'Pennsylvania',
    'Maryland',
    'Michigan',
  ];
}

// Service Categories Enum
enum ServiceCategory {
  accountantsAndTaxPreparers,
  legalServices,
  healthcareNeeds,
  religious,
//  bengaliRestaurantsGrocery,
halalGroceryStores,
halalDeshiRestaurants,
  realEstateAgents,
  handymanServices,
}

extension ServiceCategoryExtension on ServiceCategory {
  String get displayName {
    switch (this) {
      case ServiceCategory.accountantsAndTaxPreparers:
        return 'Accountants and Tax Preparers';
      case ServiceCategory.legalServices:
        return 'Legal Services';
      case ServiceCategory.healthcareNeeds:
        return 'Healthcare Needs';
      case ServiceCategory.religious:
        return 'Religious';
    //  case ServiceCategory.bengaliRestaurantsGrocery:
    //    return 'Bengali Restaurants & Grocery Stores';
      case ServiceCategory.halalGroceryStores:
        return 'Halal Grocery Stores';
      case ServiceCategory.halalDeshiRestaurants:
        return 'Halal Deshi Restaurants';
      case ServiceCategory.realEstateAgents:
        return 'Real Estate Agents';
      case ServiceCategory.handymanServices:
        return 'Handyman Services';
    }
  }

  String get stringValue {
    switch (this) {
      case ServiceCategory.accountantsAndTaxPreparers:
        return 'accountants_and_tax_preparers';
      case ServiceCategory.legalServices:
        return 'legal_services';
      case ServiceCategory.healthcareNeeds:
        return 'healthcare_needs';
      case ServiceCategory.religious:
        return 'religious';
    //  case ServiceCategory.bengaliRestaurantsGrocery:
    //    return 'bengali_restaurants_grocery';
      case ServiceCategory.halalGroceryStores:
        return 'halal_grocery_stores';
      case ServiceCategory.halalDeshiRestaurants:
        return 'halal_deshi_restaurants';
      case ServiceCategory.realEstateAgents:
        return 'real_estate_agents';
      case ServiceCategory.handymanServices:
        return 'handyman_services';
    }
  }

  // Get available service providers for each category
  List<String> get serviceProviders {
    switch (this) {
      case ServiceCategory.accountantsAndTaxPreparers:
        return ['Personal Tax Preparers', 'Business Tax Preparers', 'Business Setup Services'];
      case ServiceCategory.legalServices:
        return ['Bengali Speaking Attorneys', 'Non-Bengali Attorneys', 'Free Consultation Services'];
      case ServiceCategory.healthcareNeeds:
        return ['Health Insurance Agent', 'Bengali Doctors'];
      case ServiceCategory.religious:
        return ['Mosque, Temple & Cultural Center Listings', 'Religious Classes & Community Talks', 'Funeral & Janaza Support Coordination'];
    //  case ServiceCategory.bengaliRestaurantsGrocery:
    //    return ['Bengali Restaurants', 'Bengali/Indian Grocery Stores'];
      case ServiceCategory.halalGroceryStores:
        return ['Halal Grocery Stores','Others'];
      case ServiceCategory.halalDeshiRestaurants:
        return ['Halal Deshi Restaurants', 'Others'];
      case ServiceCategory.realEstateAgents:
        return ['Residential Real Estate Agents', 'Commercial Real Estate Agents', 'Business Broker'];
      case ServiceCategory.handymanServices:
        return ['Bengali/Spanish Handyman', 'Bengali Car Mechanics'];
    }
  }

  // Get sub-service providers for each service provider
  Map<String, List<String>> get subServiceProviders {
    switch (this) {
      case ServiceCategory.healthcareNeeds:
        return {
          'Health Insurance Agent': ['Bengali Agents', 'Non-Bengali Agents'],
          'Bengali Doctors': ['Bengali Family Physicians', 'Bengali Dentist'],
        };
      case ServiceCategory.legalServices:
        return {
          'Bengali Speaking Attorneys': ['Corporate Law', 'Immigration Law', 'Family Law'],
          'Non-Bengali Attorneys': ['Corporate Law', 'Immigration Law', 'Family Law'],
        };
      case ServiceCategory.religious:
        return {
          'Mosque, Temple & Cultural Center Listings': ['Masjid Lists', 'Temple Lists'],
          'Religious Classes & Community Talks': ['Arabic/Islamic School', 'Quran Teaching Mentor'],
          'Funeral & Janaza Support Coordination': ['Funeral Services', 'Janaza Coordination'],
        };
      default:
        return {};
    }
  }

  IconData get icon {
    switch (this) {
      case ServiceCategory.accountantsAndTaxPreparers:
        return Icons.account_balance_wallet_rounded;
      case ServiceCategory.legalServices:
        return Icons.gavel_rounded;
      case ServiceCategory.healthcareNeeds:
        return Icons.medical_services_rounded;
      case ServiceCategory.religious:
        return Icons.mosque_rounded;
    //  case ServiceCategory.bengaliRestaurantsGrocery:
    //    return Icons.restaurant_rounded;
      case ServiceCategory.halalGroceryStores:
        return Icons.local_grocery_store_rounded;
      case ServiceCategory.halalDeshiRestaurants:
        return Icons.local_restaurant_rounded;
      case ServiceCategory.realEstateAgents:
        return Icons.home_work_rounded;
      case ServiceCategory.handymanServices:
        return Icons.handyman_rounded;
    }
  }
}

// Main Service Provider Model
class ServiceProviderModel {
  String? id;
  String fullName;
  String companyName;
  String phone;
  String email;
  String address;  
  String state;
  String city;
  ServiceCategory serviceCategory;
  String serviceProvider; // e.g., 'Personal Tax Preparers'
  String? subServiceProvider; // e.g., 'Bengali Agents' (nullable)
  String? profileImageBase64; // Base64 encoded image
  String? description;
  String? website;
  String? businessHours;
  String? yearsOfExperience;
  List<String> languagesSpoken;
  List<String> serviceTags;
  List<String> serviceAreas; // Areas served within the city
  double rating;
  int totalReviews;
  bool isVerified;
  bool isAvailable;
  bool isDeleted;
  String createdBy;
  DateTime createdAt;
  DateTime updatedAt;
  Map<String, dynamic>? additionalInfo;
  List<String>? galleryImagesBase64; // Base64 encoded gallery images
  String? licenseNumber;
  String? specialties;
  double? consultationFee;
  bool? acceptsInsurance;
  List<String>? acceptedPaymentMethods; 
  
  // Like functionality
  int totalLikes;
  List<String> likedByUsers; // List of user IDs who liked this service

    final double? latitude;
  final double? longitude;

  ServiceProviderModel({
    this.id,
    required this.fullName,
    required this.companyName,
    required this.phone,
    required this.email,
    required this.address,
    required this.state,
    required this.city,
    required this.serviceCategory,
    required this.serviceProvider,
    this.subServiceProvider,
    this.profileImageBase64,
    this.description,
    this.website,
    this.businessHours,
    this.yearsOfExperience,
    this.languagesSpoken = const ['English'],
    this.serviceTags = const [],
    this.serviceAreas = const [],
    this.rating = 0.0,
    this.totalReviews = 0,
    this.isVerified = false,
    this.isAvailable = true,
    this.isDeleted = false,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.additionalInfo,
    this.galleryImagesBase64,
    this.licenseNumber,
    this.specialties,
    this.consultationFee,
    this.acceptsInsurance,
    this.acceptedPaymentMethods,
    this.totalLikes = 0,
    this.likedByUsers = const [],

        this.latitude,
    this.longitude,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'companyName': companyName,
      'phone': phone,
      'email': email,
      'address': address,
      'state': state,
      'city': city,
      'serviceCategory': serviceCategory.stringValue,
      'serviceCategoryName': serviceCategory.displayName,
      'serviceProvider': serviceProvider,
      'subServiceProvider': subServiceProvider ?? '',
      'profileImageBase64': profileImageBase64 ?? '',
      'description': description ?? '',
      'website': website ?? '',
      'businessHours': businessHours ?? '',
      'yearsOfExperience': yearsOfExperience ?? '',
      'languagesSpoken': languagesSpoken,
      'serviceTags': serviceTags,
      'serviceAreas': serviceAreas,
      'rating': rating,
      'totalReviews': totalReviews,
      'isVerified': isVerified,
      'isAvailable': isAvailable,
      'isDeleted': isDeleted,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'additionalInfo': additionalInfo ?? {},
      'galleryImagesBase64': galleryImagesBase64 ?? [],
      'licenseNumber': licenseNumber ?? '',
      'specialties': specialties ?? '',
      'consultationFee': consultationFee ?? 0.0,
      'acceptsInsurance': acceptsInsurance ?? false,
      'acceptedPaymentMethods': acceptedPaymentMethods ?? [],
      'totalLikes': totalLikes,
      'likedByUsers': likedByUsers,
      // Search optimization fields
      'searchKeywords': _generateSearchKeywords(),
      'state_city': '${state}_$city',
      'category_provider': '${serviceCategory.stringValue}_$serviceProvider',

            'latitude': latitude,
      'longitude': longitude,
    };
  }

  // Generate search keywords for better searching
  List<String> _generateSearchKeywords() {
    final keywords = <String>[
      fullName.toLowerCase(),
      companyName.toLowerCase(),
      phone.toLowerCase(),
      email.toLowerCase(),
      address.toLowerCase(),
      state.toLowerCase(),
      city.toLowerCase(),
      serviceProvider.toLowerCase(),
      if (subServiceProvider != null) subServiceProvider!.toLowerCase(),
      ...languagesSpoken.map((lang) => lang.toLowerCase()),
      ...serviceTags.map((tag) => tag.toLowerCase()),
      ...serviceAreas.map((area) => area.toLowerCase()),
    ];

    // Split multi-word fields
    keywords.addAll(fullName.toLowerCase().split(' '));
    keywords.addAll(companyName.toLowerCase().split(' '));
    keywords.addAll(address.toLowerCase().split(' '));
    
    // Remove duplicates and empty strings
    return keywords
        .where((keyword) => keyword.isNotEmpty && keyword.length > 2)
        .toSet()
        .toList();
  }

  // Create from Firestore document
  factory ServiceProviderModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Parse service category
    ServiceCategory category;
    try {
      category = ServiceCategory.values.firstWhere(
        (cat) => cat.stringValue == data['serviceCategory'],
        orElse: () => ServiceCategory.accountantsAndTaxPreparers,
      );
    } catch (e) {
      category = ServiceCategory.accountantsAndTaxPreparers;
    }

    return ServiceProviderModel(
      id: doc.id,
      fullName: data['fullName'] ?? '',
      companyName: data['companyName'] ?? '',
      phone: data['phone'] ?? '',
      email: data['email'] ?? '',
      address: data['address'] ?? '',
      state: data['state'] ?? '',
      city: data['city'] ?? '',
      serviceCategory: category,
      serviceProvider: data['serviceProvider'] ?? '',
      subServiceProvider: data['subServiceProvider'],
      profileImageBase64: data['profileImageBase64'],
      description: data['description'],
      website: data['website'],
      businessHours: data['businessHours'],
      yearsOfExperience: data['yearsOfExperience'],
      languagesSpoken: List<String>.from(data['languagesSpoken'] ?? []),
      serviceTags: List<String>.from(data['serviceTags'] ?? []),
      serviceAreas: List<String>.from(data['serviceAreas'] ?? []),
      rating: (data['rating'] ?? 0).toDouble(),
      totalReviews: data['totalReviews'] ?? 0,
      isVerified: data['isVerified'] ?? false,
      isAvailable: data['isAvailable'] ?? true,
      isDeleted: data['isDeleted'] ?? false,
      createdBy: data['createdBy'] ?? '',
createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      additionalInfo: Map<String, dynamic>.from(data['additionalInfo'] ?? {}),
      galleryImagesBase64: List<String>.from(data['galleryImagesBase64'] ?? []),
      licenseNumber: data['licenseNumber'],
      specialties: data['specialties'],
      consultationFee: (data['consultationFee'] ?? 0).toDouble(),
      acceptsInsurance: data['acceptsInsurance'] ?? false,
      acceptedPaymentMethods: List<String>.from(data['acceptedPaymentMethods'] ?? []),
      totalLikes: data['totalLikes'] ?? 0,
      likedByUsers: List<String>.from(data['likedByUsers'] ?? []),

latitude: data['latitude']?.toDouble(),
longitude: data['longitude']?.toDouble(),
    );
  }

  // Copy with method for updates
  ServiceProviderModel copyWith({
    String? id,
    String? fullName,
    String? companyName,
    String? phone,
    String? email,
    String? address,
    String? state,
    String? city,
    ServiceCategory? serviceCategory,
    String? serviceProvider,
    String? subServiceProvider,
    String? profileImageBase64,
    String? description,
    String? website,
    String? businessHours,
    String? yearsOfExperience,
    List<String>? languagesSpoken,
    List<String>? serviceTags,
    List<String>? serviceAreas,
    double? rating,
    int? totalReviews,
    bool? isVerified,
    bool? isAvailable,
    bool? isDeleted,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? additionalInfo,
    List<String>? galleryImagesBase64,
    String? licenseNumber,
    String? specialties,
    double? consultationFee,
    bool? acceptsInsurance,
    List<String>? acceptedPaymentMethods,
    int? totalLikes,
    List<String>? likedByUsers,
    double? latitude,
    double? longitude,
  }) {
    return ServiceProviderModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      companyName: companyName ?? this.companyName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      state: state ?? this.state,
      city: city ?? this.city,
      serviceCategory: serviceCategory ?? this.serviceCategory,
      serviceProvider: serviceProvider ?? this.serviceProvider,
      subServiceProvider: subServiceProvider ?? this.subServiceProvider,
      profileImageBase64: profileImageBase64 ?? this.profileImageBase64,
      description: description ?? this.description,
      website: website ?? this.website,
      businessHours: businessHours ?? this.businessHours,
      yearsOfExperience: yearsOfExperience ?? this.yearsOfExperience,
      languagesSpoken: languagesSpoken ?? this.languagesSpoken,
      serviceTags: serviceTags ?? this.serviceTags,
      serviceAreas: serviceAreas ?? this.serviceAreas,
      rating: rating ?? this.rating,
      totalReviews: totalReviews ?? this.totalReviews,
      isVerified: isVerified ?? this.isVerified,
      isAvailable: isAvailable ?? this.isAvailable,
      isDeleted: isDeleted ?? this.isDeleted,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      additionalInfo: additionalInfo ?? this.additionalInfo,
      galleryImagesBase64: galleryImagesBase64 ?? this.galleryImagesBase64,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      specialties: specialties ?? this.specialties,
      consultationFee: consultationFee ?? this.consultationFee,
      acceptsInsurance: acceptsInsurance ?? this.acceptsInsurance,
      acceptedPaymentMethods: acceptedPaymentMethods ?? this.acceptedPaymentMethods,
      totalLikes: totalLikes ?? this.totalLikes,
      likedByUsers: likedByUsers ?? this.likedByUsers,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }

  // Helper method to check if a user has liked this service
  bool isLikedByUser(String userId) {
    return likedByUsers.contains(userId);
  }

  // Helper method to toggle like for a user
  ServiceProviderModel toggleLike(String userId) {
    final newLikedByUsers = List<String>.from(likedByUsers);
    if (newLikedByUsers.contains(userId)) {
      newLikedByUsers.remove(userId);
    } else {
      newLikedByUsers.add(userId);
    }
    
    return copyWith(
      totalLikes: newLikedByUsers.length,
      likedByUsers: newLikedByUsers,
      updatedAt: DateTime.now(),
    );
  }

  // Helper method to get profile image widget
  Widget getProfileImageWidget({
    double size = 100,
    BoxShape shape = BoxShape.circle,
  }) {
    try {
      if (profileImageBase64 == null || profileImageBase64!.isEmpty) {
        return _buildDefaultProfileImage(size: size, shape: shape);
      }

      final base64String = cleanBase64String(profileImageBase64!);
      
      try {
        final bytes = base64Decode(base64String);
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: shape,
            image: DecorationImage(
              image: MemoryImage(bytes),
              fit: BoxFit.cover,
            ),
            border: Border.all(
              color: Colors.grey.shade300,
              width: 1,
            ),
          ),
        );
      } catch (e) {
        print('Error decoding base64 image: $e');
        return _buildDefaultProfileImage(size: size, shape: shape);
      }
    } catch (e) {
      return _buildDefaultProfileImage(size: size, shape: shape);
    }
  }

  String cleanBase64String(String base64) {
    String cleaned = base64.trim();
    
    // Remove data URL prefix if present
    if (cleaned.contains('base64,')) {
      cleaned = cleaned.split('base64,').last;
    }
    
    // Remove any whitespace
    cleaned = cleaned.replaceAll(RegExp(r'\s'), '');
    
    // Add padding if needed
    if (cleaned.length % 4 != 0) {
      cleaned = cleaned.padRight(cleaned.length + (4 - cleaned.length % 4), '=');
    }
    
    return cleaned;
  }

  Widget _buildDefaultProfileImage({
    required double size,
    required BoxShape shape,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: shape,
        color: Colors.grey.shade200,
        border: Border.all(
          color: Colors.grey.shade300,
          width: 1,
        ),
      ),
      child: Icon(
        Icons.person,
        size: size * 0.5,
        color: Colors.grey.shade600,
      ),
    );
  }

  // Get gallery images as widgets
  List<Widget> getGalleryImageWidgets({
    double size = 80,
    BoxShape shape = BoxShape.rectangle,
  }) {
    if (galleryImagesBase64 == null || galleryImagesBase64!.isEmpty) {
      return [];
    }

    return galleryImagesBase64!.map((base64) {
      try {
        final cleanedBase64 = cleanBase64String(base64);
        final bytes = base64Decode(cleanedBase64);
        return Container(
          width: size,
          height: size,
          margin: EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            borderRadius: shape == BoxShape.rectangle 
                ? BorderRadius.circular(8) 
                : null,
            shape: shape,
            image: DecorationImage(
              image: MemoryImage(bytes),
              fit: BoxFit.cover,
            ),
            border: Border.all(color: Colors.grey.shade300),
          ),
        );
      } catch (e) {
        return SizedBox.shrink();
      }
    }).toList();
  }

  // Check if has sub-service providers
  bool get hasSubServiceProviders {
    final subProviders = serviceCategory.subServiceProviders[serviceProvider];
    return subProviders != null && subProviders.isNotEmpty;
  }

  // Get available sub-service providers for current selection
  List<String> get availableSubServiceProviders {
    return serviceCategory.subServiceProviders[serviceProvider] ?? [];
  }

  // Formatted address
  String get formattedAddress {
    return '$address, $city, $state';
  }

  // Status badge
  Widget get statusBadge {
    if (isDeleted) {
      return Chip(
        label: Text('Deleted'),
        backgroundColor: Colors.red.shade100,
        labelStyle: TextStyle(color: Colors.red.shade800),
      );
    }
    
    if (!isAvailable) {
      return Chip(
        label: Text('Not Available'),
        backgroundColor: Colors.orange.shade100,
        labelStyle: TextStyle(color: Colors.orange.shade800),
      );
    }
    
    if (isVerified) {
      return Chip(
        label: Text('Verified'),
        backgroundColor: Colors.green.shade100,
        labelStyle: TextStyle(color: Colors.green.shade800),
        avatar: Icon(Icons.verified, size: 14),
      );
    }
    
    return Chip(
      label: Text('Unverified'),
      backgroundColor: Colors.grey.shade200,
      labelStyle: TextStyle(color: Colors.grey.shade700),
    );
  }
}