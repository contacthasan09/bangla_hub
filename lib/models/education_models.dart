import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:convert';

// ====================== ENUMS & CONSTANTS ======================

// Education Categories Enum
enum EducationCategory {
  tutoringHomework,
  schoolCollegeAdmissions,
  banglaLanguageCulture,
  localSports,
}

extension EducationCategoryExtension on EducationCategory {
  String get displayName {
    switch (this) {
      case EducationCategory.tutoringHomework:
        return 'Tutoring & Homework Help';
      case EducationCategory.schoolCollegeAdmissions:
        return 'School & College Admissions Guidance';
      case EducationCategory.banglaLanguageCulture:
        return 'Bangla Language & Culture Classes';
      case EducationCategory.localSports:
        return 'Local Sports';
    }
  }

  String get stringValue {
    switch (this) {
      case EducationCategory.tutoringHomework:
        return 'tutoring_homework';
      case EducationCategory.schoolCollegeAdmissions:
        return 'school_college_admissions';
      case EducationCategory.banglaLanguageCulture:
        return 'bangla_language_culture';
      case EducationCategory.localSports:
        return 'local_sports';
    }
  }

  IconData get icon {
    switch (this) {
      case EducationCategory.tutoringHomework:
        return Icons.school_rounded;
      case EducationCategory.schoolCollegeAdmissions:
        return Icons.business_center_rounded;
      case EducationCategory.banglaLanguageCulture:
        return Icons.language_rounded;
      case EducationCategory.localSports:
        return Icons.sports_rounded;
    }
  }

  Color get color {
    switch (this) {
      case EducationCategory.tutoringHomework:
        return Color(0xFF2196F3);
      case EducationCategory.schoolCollegeAdmissions:
        return Color(0xFF4CAF50);
      case EducationCategory.banglaLanguageCulture:
        return Color(0xFFFF9800);
      case EducationCategory.localSports:
        return Color(0xFFF44336);
    }
  }
}

// Tutoring Subject Enum
enum TutoringSubject {
  math,
  science,
  english,
  history,
  computerScience,
  bangla,
  physics,
  chemistry,
  biology,
  economics,
  arts,
  music,
}

extension TutoringSubjectExtension on TutoringSubject {
  String get displayName {
    switch (this) {
      case TutoringSubject.math:
        return 'Mathematics';
      case TutoringSubject.science:
        return 'Science';
      case TutoringSubject.english:
        return 'English';
      case TutoringSubject.history:
        return 'History';
      case TutoringSubject.computerScience:
        return 'Computer Science';
      case TutoringSubject.bangla:
        return 'Bangla';
      case TutoringSubject.physics:
        return 'Physics';
      case TutoringSubject.chemistry:
        return 'Chemistry';
      case TutoringSubject.biology:
        return 'Biology';
      case TutoringSubject.economics:
        return 'Economics';
      case TutoringSubject.arts:
        return 'Arts';
      case TutoringSubject.music:
        return 'Music';
    }
  }
}

// Education Level Enum
enum EducationLevel {
  elementary,
  middleSchool,
  highSchool,
  undergraduate,
  graduate,
  adultEducation,
}

extension EducationLevelExtension on EducationLevel {
  String get displayName {
    switch (this) {
      case EducationLevel.elementary:
        return 'Elementary School';
      case EducationLevel.middleSchool:
        return 'Middle School';
      case EducationLevel.highSchool:
        return 'High School';
      case EducationLevel.undergraduate:
        return 'Undergraduate';
      case EducationLevel.graduate:
        return 'Graduate';
      case EducationLevel.adultEducation:
        return 'Adult Education';
    }
  }
}

// Sports Type Enum
enum SportsType {
  cricket,
  soccer,
  basketball,
  volleyball,
  badminton,
  tableTennis,
  swimming,
  martialArts,
  yoga,
}

extension SportsTypeExtension on SportsType {
  String get displayName {
    switch (this) {
      case SportsType.cricket:
        return 'Cricket';
      case SportsType.soccer:
        return 'Soccer';
      case SportsType.basketball:
        return 'Basketball';
      case SportsType.volleyball:
        return 'Volleyball';
      case SportsType.badminton:
        return 'Badminton';
      case SportsType.tableTennis:
        return 'Table Tennis';
      case SportsType.swimming:
        return 'Swimming';
      case SportsType.martialArts:
        return 'Martial Arts';
      case SportsType.yoga:
        return 'Yoga';
    }
  }
}

// Teaching Method Enum
enum TeachingMethod {
  inPerson,
  online,
  hybrid,
  group,
  oneOnOne,
}

extension TeachingMethodExtension on TeachingMethod {
  String get displayName {
    switch (this) {
      case TeachingMethod.inPerson:
        return 'In-Person';
      case TeachingMethod.online:
        return 'Online';
      case TeachingMethod.hybrid:
        return 'Hybrid';
      case TeachingMethod.group:
        return 'Group Classes';
      case TeachingMethod.oneOnOne:
        return 'One-on-One';
    }
  }
}

// ====================== HELPER FUNCTIONS ======================

String cleanBase64String(String base64) {
  String cleaned = base64.trim();
  if (cleaned.contains('base64,')) {
    cleaned = cleaned.split('base64,').last;
  }
  cleaned = cleaned.replaceAll(RegExp(r'\s'), '');
  if (cleaned.length % 4 != 0) {
    cleaned = cleaned.padRight(cleaned.length + (4 - cleaned.length % 4), '=');
  }
  return cleaned;
}

// ====================== TUTORING SERVICE MODEL ======================
class TutoringService {
  String? id;
  EducationCategory category;
  String tutorName;
  String? organizationName;
  String email;
  String phone;
  String address;
  String state;
  String city;
  List<TutoringSubject> subjects;
  List<EducationLevel> levels;
  List<TeachingMethod> teachingMethods;
  String description;
  double hourlyRate;
  String? experience;
  String? qualifications;
  String? profileImageBase64;
  List<String>? galleryImagesBase64;
  List<String> availableDays;
  List<String> availableTimes;
  List<String> languagesSpoken;

  String? postedByUserId;
  String? postedByName;
  String? postedByEmail;
  String? postedByProfileImageBase64;

  final double? latitude;
  final double? longitude;

  bool isVerified;
  bool isActive;
  bool isDeleted;
  double rating;
  int totalReviews;
  int totalLikes;
  List<String> likedByUsers;
  
  String createdBy;
  DateTime createdAt;
  DateTime updatedAt;
  
  Map<String, dynamic>? additionalInfo;
  List<String>? certifications;
  String? website;
  String? socialMediaLinks;
  List<String> serviceAreas;
  
  TutoringService({
    this.id,
    this.category = EducationCategory.tutoringHomework,
    required this.tutorName,
    this.organizationName,
    required this.email,
    required this.phone,
    required this.address,
    required this.state,
    required this.city,
    required this.subjects,
    required this.levels,
    required this.teachingMethods,
    required this.description,
    required this.hourlyRate,
    this.experience,
    this.qualifications,
    this.profileImageBase64,
    this.galleryImagesBase64,
    required this.availableDays,
    required this.availableTimes,
    this.languagesSpoken = const ['English', 'Bengali'],
    this.postedByUserId,
    this.postedByName,
    this.postedByEmail,
    this.postedByProfileImageBase64,
    this.latitude,
    this.longitude,
    this.isVerified = false,
    this.isActive = true,
    this.isDeleted = false,
    this.rating = 0.0,
    this.totalReviews = 0,
    this.totalLikes = 0,
    this.likedByUsers = const [],
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.additionalInfo,
    this.certifications,
    this.website,
    this.socialMediaLinks,
    this.serviceAreas = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'category': category.stringValue,
      'categoryName': category.displayName,
      'tutorName': tutorName,
      'organizationName': organizationName ?? '',
      'email': email,
      'phone': phone,
      'address': address,
      'state': state,
      'city': city,
      'subjects': subjects.map((s) => s.toString()).toList(),
      'subjectNames': subjects.map((s) => s.displayName).toList(),
      'levels': levels.map((l) => l.toString()).toList(),
      'levelNames': levels.map((l) => l.displayName).toList(),
      'teachingMethods': teachingMethods.map((m) => m.toString()).toList(),
      'methodNames': teachingMethods.map((m) => m.displayName).toList(),
      'description': description,
      'hourlyRate': hourlyRate,
      'experience': experience ?? '',
      'qualifications': qualifications ?? '',
      'profileImageBase64': profileImageBase64 ?? '',
      'galleryImagesBase64': galleryImagesBase64 ?? [],
      'availableDays': availableDays,
      'availableTimes': availableTimes,
      'languagesSpoken': languagesSpoken,
      'postedByUserId': postedByUserId ?? '',
      'postedByName': postedByName ?? '',
      'postedByEmail': postedByEmail ?? '',
      'postedByProfileImageBase64': postedByProfileImageBase64 ?? '',
      'latitude': latitude,
      'longitude': longitude,
      'isVerified': isVerified,
      'isActive': isActive,
      'isDeleted': isDeleted,
      'rating': rating,
      'totalReviews': totalReviews,
      'totalLikes': totalLikes,
      'likedByUsers': likedByUsers,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'additionalInfo': additionalInfo ?? {},
      'certifications': certifications ?? [],
      'website': website ?? '',
      'socialMediaLinks': socialMediaLinks ?? '',
      'serviceAreas': serviceAreas,
      'searchKeywords': _generateSearchKeywords(),
      'state_city': '${state}_$city',
      'subjects_levels': '${subjects.map((s) => s.toString()).join('_')}_${levels.map((l) => l.toString()).join('_')}',
    };
  }

  factory TutoringService.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    EducationCategory cat;
    try {
      cat = EducationCategory.values.firstWhere(
        (c) => c.stringValue == data['category'],
        orElse: () => EducationCategory.tutoringHomework,
      );
    } catch (e) {
      cat = EducationCategory.tutoringHomework;
    }

    return TutoringService(
      id: doc.id,
      category: cat,
      tutorName: data['tutorName'] ?? '',
      organizationName: data['organizationName'],
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      address: data['address'] ?? '',
      state: data['state'] ?? '',
      city: data['city'] ?? '',
      subjects: (data['subjects'] as List<dynamic>)
          .map((s) => TutoringSubject.values.firstWhere(
                (sub) => sub.toString() == s,
                orElse: () => TutoringSubject.math,
              ))
          .toList(),
      levels: (data['levels'] as List<dynamic>)
          .map((l) => EducationLevel.values.firstWhere(
                (lev) => lev.toString() == l,
                orElse: () => EducationLevel.highSchool,
              ))
          .toList(),
      teachingMethods: (data['teachingMethods'] as List<dynamic>)
          .map((m) => TeachingMethod.values.firstWhere(
                (method) => method.toString() == m,
                orElse: () => TeachingMethod.inPerson,
              ))
          .toList(),
      description: data['description'] ?? '',
      hourlyRate: (data['hourlyRate'] ?? 0).toDouble(),
      experience: data['experience'],
      qualifications: data['qualifications'],
      profileImageBase64: data['profileImageBase64'],
      galleryImagesBase64: List<String>.from(data['galleryImagesBase64'] ?? []),
      availableDays: List<String>.from(data['availableDays'] ?? []),
      availableTimes: List<String>.from(data['availableTimes'] ?? []),
      languagesSpoken: List<String>.from(data['languagesSpoken'] ?? []),
      postedByUserId: data['postedByUserId'] ?? '',
      postedByName: data['postedByName'] ?? '',
      postedByEmail: data['postedByEmail'] ?? '',
      postedByProfileImageBase64: data['postedByProfileImageBase64'] ?? '',
      latitude: data['latitude']?.toDouble(),
      longitude: data['longitude']?.toDouble(),
      isVerified: data['isVerified'] ?? false,
      isActive: data['isActive'] ?? true,
      isDeleted: data['isDeleted'] ?? false,
      rating: (data['rating'] ?? 0).toDouble(),
      totalReviews: data['totalReviews'] ?? 0,
      totalLikes: data['totalLikes'] ?? 0,
      likedByUsers: List<String>.from(data['likedByUsers'] ?? []),
      createdBy: data['createdBy'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      additionalInfo: Map<String, dynamic>.from(data['additionalInfo'] ?? {}),
      certifications: List<String>.from(data['certifications'] ?? []),
      website: data['website'],
      socialMediaLinks: data['socialMediaLinks'],
      serviceAreas: List<String>.from(data['serviceAreas'] ?? []),
    );
  }

  List<String> _generateSearchKeywords() {
    final keywords = <String>[
      tutorName.toLowerCase(),
      organizationName?.toLowerCase() ?? '',
      email.toLowerCase(),
      phone.toLowerCase(),
      address.toLowerCase(),
      state.toLowerCase(),
      city.toLowerCase(),
      description.toLowerCase(),
      ...subjects.map((s) => s.displayName.toLowerCase()),
      ...levels.map((l) => l.displayName.toLowerCase()),
      ...teachingMethods.map((m) => m.displayName.toLowerCase()),
      ...languagesSpoken.map((lang) => lang.toLowerCase()),
      ...serviceAreas.map((area) => area.toLowerCase()),
    ];

    keywords.addAll(tutorName.toLowerCase().split(' '));
    keywords.addAll(description.toLowerCase().split(' '));
    
    return keywords
        .where((keyword) => keyword.isNotEmpty && keyword.length > 2)
        .toSet()
        .toList();
  }

  String get formattedRate {
    return '\$${hourlyRate.toStringAsFixed(2)}/hour';
  }

  Widget getProfileImageWidget({
    double size = 100,
    BoxShape shape = BoxShape.circle,
  }) {
    try {
      if (profileImageBase64 == null || profileImageBase64!.isEmpty) {
        return _buildDefaultProfileImage(size: size, shape: shape);
      }

      final base64String = cleanBase64String(profileImageBase64!);
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
          border: Border.all(color: Colors.grey.shade300, width: 1),
        ),
      );
    } catch (e) {
      return _buildDefaultProfileImage(size: size, shape: shape);
    }
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
        color: category.color.withOpacity(0.1),
        border: Border.all(color: category.color.withOpacity(0.3), width: 1),
      ),
      child: Icon(
        Icons.person,
        size: size * 0.5,
        color: category.color,
      ),
    );
  }

  TutoringService copyWith({
    String? id,
    EducationCategory? category,
    String? tutorName,
    String? organizationName,
    String? email,
    String? phone,
    String? address,
    String? state,
    String? city,
    List<TutoringSubject>? subjects,
    List<EducationLevel>? levels,
    List<TeachingMethod>? teachingMethods,
    String? description,
    double? hourlyRate,
    String? experience,
    String? qualifications,
    String? profileImageBase64,
    List<String>? galleryImagesBase64,
    List<String>? availableDays,
    List<String>? availableTimes,
    List<String>? languagesSpoken,
    String? postedByUserId,
    String? postedByName,
    String? postedByEmail,
    String? postedByProfileImageBase64,
    double? latitude,
    double? longitude,
    bool? isVerified,
    bool? isActive,
    bool? isDeleted,
    double? rating,
    int? totalReviews,
    int? totalLikes,
    List<String>? likedByUsers,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? additionalInfo,
    List<String>? certifications,
    String? website,
    String? socialMediaLinks,
    List<String>? serviceAreas,
  }) {
    return TutoringService(
      id: id ?? this.id,
      category: category ?? this.category,
      tutorName: tutorName ?? this.tutorName,
      organizationName: organizationName ?? this.organizationName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      state: state ?? this.state,
      city: city ?? this.city,
      subjects: subjects ?? this.subjects,
      levels: levels ?? this.levels,
      teachingMethods: teachingMethods ?? this.teachingMethods,
      description: description ?? this.description,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      experience: experience ?? this.experience,
      qualifications: qualifications ?? this.qualifications,
      profileImageBase64: profileImageBase64 ?? this.profileImageBase64,
      galleryImagesBase64: galleryImagesBase64 ?? this.galleryImagesBase64,
      availableDays: availableDays ?? this.availableDays,
      availableTimes: availableTimes ?? this.availableTimes,
      languagesSpoken: languagesSpoken ?? this.languagesSpoken,
      postedByUserId: postedByUserId ?? this.postedByUserId,
      postedByName: postedByName ?? this.postedByName,
      postedByEmail: postedByEmail ?? this.postedByEmail,
      postedByProfileImageBase64: postedByProfileImageBase64 ?? this.postedByProfileImageBase64,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isVerified: isVerified ?? this.isVerified,
      isActive: isActive ?? this.isActive,
      isDeleted: isDeleted ?? this.isDeleted,
      rating: rating ?? this.rating,
      totalReviews: totalReviews ?? this.totalReviews,
      totalLikes: totalLikes ?? this.totalLikes,
      likedByUsers: likedByUsers ?? this.likedByUsers,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      additionalInfo: additionalInfo ?? this.additionalInfo,
      certifications: certifications ?? this.certifications,
      website: website ?? this.website,
      socialMediaLinks: socialMediaLinks ?? this.socialMediaLinks,
      serviceAreas: serviceAreas ?? this.serviceAreas,
    );
  }
}

// ====================== ADMISSIONS GUIDANCE MODEL ======================
class AdmissionsGuidance {
  String? id;
  EducationCategory category;
  String consultantName;
  String? organizationName;
  String email;
  String phone;
  String address;
  String state;
  String city;
  List<String> specializations;
  List<String> countries;
  String description;
  double consultationFee;
  String? experience;
  String? qualifications;
  String? profileImageBase64;
  List<String>? successStories;
  List<String> servicesOffered;
  List<String> languagesSpoken;

  String? postedByUserId;
  String? postedByName;
  String? postedByEmail;
  String? postedByProfileImageBase64;

  final double? latitude;
  final double? longitude;
  
  bool isVerified;
  bool isActive;
  bool isDeleted;
  double rating;
  int totalReviews;
  int totalLikes;
  List<String> likedByUsers;
  
  String createdBy;
  DateTime createdAt;
  DateTime updatedAt;
  
  Map<String, dynamic>? additionalInfo;
  List<String>? certifications;
  String? website;
  String? socialMediaLinks;
  List<String> serviceAreas;
  
  AdmissionsGuidance({
    this.id,
    this.category = EducationCategory.schoolCollegeAdmissions,
    required this.consultantName,
    this.organizationName,
    required this.email,
    required this.phone,
    required this.address,
    required this.state,
    required this.city,
    required this.specializations,
    required this.countries,
    required this.description,
    required this.consultationFee,
    this.experience,
    this.qualifications,
    this.profileImageBase64,
    this.successStories,
    required this.servicesOffered,
    this.languagesSpoken = const ['English', 'Bengali'],
    this.postedByUserId,
    this.postedByName,
    this.postedByEmail,
    this.postedByProfileImageBase64,
    this.latitude,
    this.longitude,
    this.isVerified = false,
    this.isActive = true,
    this.isDeleted = false,
    this.rating = 0.0,
    this.totalReviews = 0,
    this.totalLikes = 0,
    this.likedByUsers = const [],
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.additionalInfo,
    this.certifications,
    this.website,
    this.socialMediaLinks,
    this.serviceAreas = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'category': category.stringValue,
      'categoryName': category.displayName,
      'consultantName': consultantName,
      'organizationName': organizationName ?? '',
      'email': email,
      'phone': phone,
      'address': address,
      'state': state,
      'city': city,
      'specializations': specializations,
      'countries': countries,
      'description': description,
      'consultationFee': consultationFee,
      'experience': experience ?? '',
      'qualifications': qualifications ?? '',
      'profileImageBase64': profileImageBase64 ?? '',
      'successStories': successStories ?? [],
      'servicesOffered': servicesOffered,
      'languagesSpoken': languagesSpoken,
      'postedByUserId': postedByUserId ?? '',
      'postedByName': postedByName ?? '',
      'postedByEmail': postedByEmail ?? '',
      'postedByProfileImageBase64': postedByProfileImageBase64 ?? '',
      'latitude': latitude,
      'longitude': longitude,
      'isVerified': isVerified,
      'isActive': isActive,
      'isDeleted': isDeleted,
      'rating': rating,
      'totalReviews': totalReviews,
      'totalLikes': totalLikes,
      'likedByUsers': likedByUsers,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'additionalInfo': additionalInfo ?? {},
      'certifications': certifications ?? [],
      'website': website ?? '',
      'socialMediaLinks': socialMediaLinks ?? '',
      'serviceAreas': serviceAreas,
      'searchKeywords': _generateSearchKeywords(),
      'state_city': '${state}_$city',
    };
  }

  factory AdmissionsGuidance.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    EducationCategory cat;
    try {
      cat = EducationCategory.values.firstWhere(
        (c) => c.stringValue == data['category'],
        orElse: () => EducationCategory.schoolCollegeAdmissions,
      );
    } catch (e) {
      cat = EducationCategory.schoolCollegeAdmissions;
    }

    return AdmissionsGuidance(
      id: doc.id,
      category: cat,
      consultantName: data['consultantName'] ?? '',
      organizationName: data['organizationName'],
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      address: data['address'] ?? '',
      state: data['state'] ?? '',
      city: data['city'] ?? '',
      specializations: List<String>.from(data['specializations'] ?? []),
      countries: List<String>.from(data['countries'] ?? []),
      description: data['description'] ?? '',
      consultationFee: (data['consultationFee'] ?? 0).toDouble(),
      experience: data['experience'],
      qualifications: data['qualifications'],
      profileImageBase64: data['profileImageBase64'],
      successStories: List<String>.from(data['successStories'] ?? []),
      servicesOffered: List<String>.from(data['servicesOffered'] ?? []),
      languagesSpoken: List<String>.from(data['languagesSpoken'] ?? []),
      postedByUserId: data['postedByUserId'] ?? '',
      postedByName: data['postedByName'] ?? '',
      postedByEmail: data['postedByEmail'] ?? '',
      postedByProfileImageBase64: data['postedByProfileImageBase64'] ?? '',
      latitude: data['latitude']?.toDouble(),
      longitude: data['longitude']?.toDouble(),
      isVerified: data['isVerified'] ?? false,
      isActive: data['isActive'] ?? true,
      isDeleted: data['isDeleted'] ?? false,
      rating: (data['rating'] ?? 0).toDouble(),
      totalReviews: data['totalReviews'] ?? 0,
      totalLikes: data['totalLikes'] ?? 0,
      likedByUsers: List<String>.from(data['likedByUsers'] ?? []),
      createdBy: data['createdBy'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      additionalInfo: Map<String, dynamic>.from(data['additionalInfo'] ?? {}),
      certifications: List<String>.from(data['certifications'] ?? []),
      website: data['website'],
      socialMediaLinks: data['socialMediaLinks'],
      serviceAreas: List<String>.from(data['serviceAreas'] ?? []),
    );
  }

  List<String> _generateSearchKeywords() {
    final keywords = <String>[
      consultantName.toLowerCase(),
      organizationName?.toLowerCase() ?? '',
      email.toLowerCase(),
      phone.toLowerCase(),
      address.toLowerCase(),
      state.toLowerCase(),
      city.toLowerCase(),
      description.toLowerCase(),
      ...specializations.map((s) => s.toLowerCase()),
      ...countries.map((c) => c.toLowerCase()),
      ...servicesOffered.map((s) => s.toLowerCase()),
      ...languagesSpoken.map((lang) => lang.toLowerCase()),
      ...serviceAreas.map((area) => area.toLowerCase()),
    ];

    keywords.addAll(consultantName.toLowerCase().split(' '));
    keywords.addAll(description.toLowerCase().split(' '));
    
    return keywords
        .where((keyword) => keyword.isNotEmpty && keyword.length > 2)
        .toSet()
        .toList();
  }

  String get formattedFee {
    return consultationFee > 0 
        ? '\$${consultationFee.toStringAsFixed(2)}/consultation'
        : 'Free Consultation';
  }

  String cleanBase64String(String base64) {
    String cleaned = base64.trim();
    if (cleaned.contains('base64,')) {
      cleaned = cleaned.split('base64,').last;
    }
    cleaned = cleaned.replaceAll(RegExp(r'\s'), '');
    if (cleaned.length % 4 != 0) {
      cleaned = cleaned.padRight(cleaned.length + (4 - cleaned.length % 4), '=');
    }
    return cleaned;
  }

  Widget getProfileImageWidget({
    double size = 100,
    BoxShape shape = BoxShape.circle,
  }) {
    try {
      if (profileImageBase64 == null || profileImageBase64!.isEmpty) {
        return _buildDefaultProfileImage(size: size, shape: shape);
      }

      final base64String = cleanBase64String(profileImageBase64!);
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
          border: Border.all(color: Colors.grey.shade300, width: 1),
        ),
      );
    } catch (e) {
      return _buildDefaultProfileImage(size: size, shape: shape);
    }
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
        color: category.color.withOpacity(0.1),
        border: Border.all(color: category.color.withOpacity(0.3), width: 1),
      ),
      child: Icon(
        Icons.person,
        size: size * 0.5,
        color: category.color,
      ),
    );
  }

  AdmissionsGuidance copyWith({
    String? id,
    EducationCategory? category,
    String? consultantName,
    String? organizationName,
    String? email,
    String? phone,
    String? address,
    String? state,
    String? city,
    List<String>? specializations,
    List<String>? countries,
    String? description,
    double? consultationFee,
    String? experience,
    String? qualifications,
    String? profileImageBase64,
    List<String>? successStories,
    List<String>? servicesOffered,
    List<String>? languagesSpoken,
    String? postedByUserId,
    String? postedByName,
    String? postedByEmail,
    String? postedByProfileImageBase64,
    double? latitude,
    double? longitude,
    bool? isVerified,
    bool? isActive,
    bool? isDeleted,
    double? rating,
    int? totalReviews,
    int? totalLikes,
    List<String>? likedByUsers,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? additionalInfo,
    List<String>? certifications,
    String? website,
    String? socialMediaLinks,
    List<String>? serviceAreas,
  }) {
    return AdmissionsGuidance(
      id: id ?? this.id,
      category: category ?? this.category,
      consultantName: consultantName ?? this.consultantName,
      organizationName: organizationName ?? this.organizationName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      state: state ?? this.state,
      city: city ?? this.city,
      specializations: specializations ?? this.specializations,
      countries: countries ?? this.countries,
      description: description ?? this.description,
      consultationFee: consultationFee ?? this.consultationFee,
      experience: experience ?? this.experience,
      qualifications: qualifications ?? this.qualifications,
      profileImageBase64: profileImageBase64 ?? this.profileImageBase64,
      successStories: successStories ?? this.successStories,
      servicesOffered: servicesOffered ?? this.servicesOffered,
      languagesSpoken: languagesSpoken ?? this.languagesSpoken,
      postedByUserId: postedByUserId ?? this.postedByUserId,
      postedByName: postedByName ?? this.postedByName,
      postedByEmail: postedByEmail ?? this.postedByEmail,
      postedByProfileImageBase64: postedByProfileImageBase64 ?? this.postedByProfileImageBase64,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isVerified: isVerified ?? this.isVerified,
      isActive: isActive ?? this.isActive,
      isDeleted: isDeleted ?? this.isDeleted,
      rating: rating ?? this.rating,
      totalReviews: totalReviews ?? this.totalReviews,
      totalLikes: totalLikes ?? this.totalLikes,
      likedByUsers: likedByUsers ?? this.likedByUsers,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      additionalInfo: additionalInfo ?? this.additionalInfo,
      certifications: certifications ?? this.certifications,
      website: website ?? this.website,
      socialMediaLinks: socialMediaLinks ?? this.socialMediaLinks,
      serviceAreas: serviceAreas ?? this.serviceAreas,
    );
  }
}

// ====================== BANGLA CLASS MODEL ======================
class BanglaClass {
  String? id;
  EducationCategory category;
  String instructorName;
  String? organizationName;
  String email;
  String phone;
  String address;
  String state;
  String city;
  List<String> classTypes;
  List<TeachingMethod> teachingMethods;
  String description;
  double classFee;
  String? schedule;
  int classDuration;
  int maxStudents;
  String? qualifications;
  String? profileImageBase64;
  List<String>? galleryImagesBase64;
  List<String> languagesSpoken;

  String? postedByUserId;
  String? postedByName;
  String? postedByEmail;
  String? postedByProfileImageBase64;

  final double? latitude;
  final double? longitude;
  
  bool isVerified;
  bool isActive;
  bool isDeleted;
  double rating;
  int totalReviews;
  int totalLikes;
  List<String> likedByUsers;
  int enrolledStudents;
  
  String createdBy;
  DateTime createdAt;
  DateTime updatedAt;
  
  Map<String, dynamic>? additionalInfo;
  List<String>? certifications;
  String? website;
  String? socialMediaLinks;
  List<String> serviceAreas;
  List<String> culturalActivities;
  
  BanglaClass({
    this.id,
    this.category = EducationCategory.banglaLanguageCulture,
    required this.instructorName,
    this.organizationName,
    required this.email,
    required this.phone,
    required this.address,
    required this.state,
    required this.city,
    required this.classTypes,
    required this.teachingMethods,
    required this.description,
    required this.classFee,
    this.schedule,
    required this.classDuration,
    required this.maxStudents,
    this.qualifications,
    this.profileImageBase64,
    this.galleryImagesBase64,
    this.languagesSpoken = const ['English', 'Bengali'],
    this.postedByUserId,
    this.postedByName,
    this.postedByEmail,
    this.postedByProfileImageBase64,
    this.latitude,
    this.longitude,
    this.isVerified = false,
    this.isActive = true,
    this.isDeleted = false,
    this.rating = 0.0,
    this.totalReviews = 0,
    this.totalLikes = 0,
    this.likedByUsers = const [],
    this.enrolledStudents = 0,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.additionalInfo,
    this.certifications,
    this.website,
    this.socialMediaLinks,
    this.serviceAreas = const [],
    this.culturalActivities = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'category': category.stringValue,
      'categoryName': category.displayName,
      'instructorName': instructorName,
      'organizationName': organizationName ?? '',
      'email': email,
      'phone': phone,
      'address': address,
      'state': state,
      'city': city,
      'classTypes': classTypes,
      'teachingMethods': teachingMethods.map((m) => m.toString()).toList(),
      'methodNames': teachingMethods.map((m) => m.displayName).toList(),
      'description': description,
      'classFee': classFee,
      'schedule': schedule ?? '',
      'classDuration': classDuration,
      'maxStudents': maxStudents,
      'qualifications': qualifications ?? '',
      'profileImageBase64': profileImageBase64 ?? '',
      'galleryImagesBase64': galleryImagesBase64 ?? [],
      'languagesSpoken': languagesSpoken,
      'postedByUserId': postedByUserId ?? '',
      'postedByName': postedByName ?? '',
      'postedByEmail': postedByEmail ?? '',
      'postedByProfileImageBase64': postedByProfileImageBase64 ?? '',
      'latitude': latitude,
      'longitude': longitude,
      'isVerified': isVerified,
      'isActive': isActive,
      'isDeleted': isDeleted,
      'rating': rating,
      'totalReviews': totalReviews,
      'totalLikes': totalLikes,
      'likedByUsers': likedByUsers,
      'enrolledStudents': enrolledStudents,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'additionalInfo': additionalInfo ?? {},
      'certifications': certifications ?? [],
      'website': website ?? '',
      'socialMediaLinks': socialMediaLinks ?? '',
      'serviceAreas': serviceAreas,
      'culturalActivities': culturalActivities,
      'searchKeywords': _generateSearchKeywords(),
      'state_city': '${state}_$city',
    };
  }

  factory BanglaClass.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    EducationCategory cat;
    try {
      cat = EducationCategory.values.firstWhere(
        (c) => c.stringValue == data['category'],
        orElse: () => EducationCategory.banglaLanguageCulture,
      );
    } catch (e) {
      cat = EducationCategory.banglaLanguageCulture;
    }

    return BanglaClass(
      id: doc.id,
      category: cat,
      instructorName: data['instructorName'] ?? '',
      organizationName: data['organizationName'],
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      address: data['address'] ?? '',
      state: data['state'] ?? '',
      city: data['city'] ?? '',
      classTypes: List<String>.from(data['classTypes'] ?? []),
      teachingMethods: (data['teachingMethods'] as List<dynamic>)
          .map((m) => TeachingMethod.values.firstWhere(
                (method) => method.toString() == m,
                orElse: () => TeachingMethod.inPerson,
              ))
          .toList(),
      description: data['description'] ?? '',
      classFee: (data['classFee'] ?? 0).toDouble(),
      schedule: data['schedule'],
      classDuration: data['classDuration'] ?? 60,
      maxStudents: data['maxStudents'] ?? 10,
      qualifications: data['qualifications'],
      profileImageBase64: data['profileImageBase64'],
      galleryImagesBase64: List<String>.from(data['galleryImagesBase64'] ?? []),
      languagesSpoken: List<String>.from(data['languagesSpoken'] ?? []),
      postedByUserId: data['postedByUserId'] ?? '',
      postedByName: data['postedByName'] ?? '',
      postedByEmail: data['postedByEmail'] ?? '',
      postedByProfileImageBase64: data['postedByProfileImageBase64'] ?? '',
      latitude: data['latitude']?.toDouble(),
      longitude: data['longitude']?.toDouble(),
      isVerified: data['isVerified'] ?? false,
      isActive: data['isActive'] ?? true,
      isDeleted: data['isDeleted'] ?? false,
      rating: (data['rating'] ?? 0).toDouble(),
      totalReviews: data['totalReviews'] ?? 0,
      totalLikes: data['totalLikes'] ?? 0,
      likedByUsers: List<String>.from(data['likedByUsers'] ?? []),
      enrolledStudents: data['enrolledStudents'] ?? 0,
      createdBy: data['createdBy'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      additionalInfo: Map<String, dynamic>.from(data['additionalInfo'] ?? {}),
      certifications: List<String>.from(data['certifications'] ?? []),
      website: data['website'],
      socialMediaLinks: data['socialMediaLinks'],
      serviceAreas: List<String>.from(data['serviceAreas'] ?? []),
      culturalActivities: List<String>.from(data['culturalActivities'] ?? []),
    );
  }

  List<String> _generateSearchKeywords() {
    final keywords = <String>[
      instructorName.toLowerCase(),
      organizationName?.toLowerCase() ?? '',
      email.toLowerCase(),
      phone.toLowerCase(),
      address.toLowerCase(),
      state.toLowerCase(),
      city.toLowerCase(),
      description.toLowerCase(),
      ...classTypes.map((c) => c.toLowerCase()),
      ...teachingMethods.map((m) => m.displayName.toLowerCase()),
      ...languagesSpoken.map((lang) => lang.toLowerCase()),
      ...culturalActivities.map((activity) => activity.toLowerCase()),
      ...serviceAreas.map((area) => area.toLowerCase()),
    ];

    keywords.addAll(instructorName.toLowerCase().split(' '));
    keywords.addAll(description.toLowerCase().split(' '));
    
    return keywords
        .where((keyword) => keyword.isNotEmpty && keyword.length > 2)
        .toSet()
        .toList();
  }

  String get formattedFee {
    return classFee > 0 
        ? '\$${classFee.toStringAsFixed(2)}/class'
        : 'Free Class';
  }

  String get formattedDuration {
    return '$classDuration minutes';
  }

  String get availabilityStatus {
    if (enrolledStudents >= maxStudents) {
      return 'Full';
    }
    final spotsLeft = maxStudents - enrolledStudents;
    return '$spotsLeft spots left';
  }

  String cleanBase64String(String base64) {
    String cleaned = base64.trim();
    if (cleaned.contains('base64,')) {
      cleaned = cleaned.split('base64,').last;
    }
    cleaned = cleaned.replaceAll(RegExp(r'\s'), '');
    if (cleaned.length % 4 != 0) {
      cleaned = cleaned.padRight(cleaned.length + (4 - cleaned.length % 4), '=');
    }
    return cleaned;
  }

  Widget getProfileImageWidget({
    double size = 100,
    BoxShape shape = BoxShape.circle,
  }) {
    try {
      if (profileImageBase64 == null || profileImageBase64!.isEmpty) {
        return _buildDefaultProfileImage(size: size, shape: shape);
      }

      final base64String = cleanBase64String(profileImageBase64!);
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
          border: Border.all(color: Colors.grey.shade300, width: 1),
        ),
      );
    } catch (e) {
      return _buildDefaultProfileImage(size: size, shape: shape);
    }
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
        color: category.color.withOpacity(0.1),
        border: Border.all(color: category.color.withOpacity(0.3), width: 1),
      ),
      child: Icon(
        Icons.person,
        size: size * 0.5,
        color: category.color,
      ),
    );
  }

  BanglaClass copyWith({
    String? id,
    EducationCategory? category,
    String? instructorName,
    String? organizationName,
    String? email,
    String? phone,
    String? address,
    String? state,
    String? city,
    List<String>? classTypes,
    List<TeachingMethod>? teachingMethods,
    String? description,
    double? classFee,
    String? schedule,
    int? classDuration,
    int? maxStudents,
    String? qualifications,
    String? profileImageBase64,
    List<String>? galleryImagesBase64,
    List<String>? languagesSpoken,
    String? postedByUserId,
    String? postedByName,
    String? postedByEmail,
    String? postedByProfileImageBase64,
    double? latitude,
    double? longitude,
    bool? isVerified,
    bool? isActive,
    bool? isDeleted,
    double? rating,
    int? totalReviews,
    int? totalLikes,
    List<String>? likedByUsers,
    int? enrolledStudents,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? additionalInfo,
    List<String>? certifications,
    String? website,
    String? socialMediaLinks,
    List<String>? serviceAreas,
    List<String>? culturalActivities,
  }) {
    return BanglaClass(
      id: id ?? this.id,
      category: category ?? this.category,
      instructorName: instructorName ?? this.instructorName,
      organizationName: organizationName ?? this.organizationName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      state: state ?? this.state,
      city: city ?? this.city,
      classTypes: classTypes ?? this.classTypes,
      teachingMethods: teachingMethods ?? this.teachingMethods,
      description: description ?? this.description,
      classFee: classFee ?? this.classFee,
      schedule: schedule ?? this.schedule,
      classDuration: classDuration ?? this.classDuration,
      maxStudents: maxStudents ?? this.maxStudents,
      qualifications: qualifications ?? this.qualifications,
      profileImageBase64: profileImageBase64 ?? this.profileImageBase64,
      galleryImagesBase64: galleryImagesBase64 ?? this.galleryImagesBase64,
      languagesSpoken: languagesSpoken ?? this.languagesSpoken,
      postedByUserId: postedByUserId ?? this.postedByUserId,
      postedByName: postedByName ?? this.postedByName,
      postedByEmail: postedByEmail ?? this.postedByEmail,
      postedByProfileImageBase64: postedByProfileImageBase64 ?? this.postedByProfileImageBase64,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isVerified: isVerified ?? this.isVerified,
      isActive: isActive ?? this.isActive,
      isDeleted: isDeleted ?? this.isDeleted,
      rating: rating ?? this.rating,
      totalReviews: totalReviews ?? this.totalReviews,
      totalLikes: totalLikes ?? this.totalLikes,
      likedByUsers: likedByUsers ?? this.likedByUsers,
      enrolledStudents: enrolledStudents ?? this.enrolledStudents,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      additionalInfo: additionalInfo ?? this.additionalInfo,
      certifications: certifications ?? this.certifications,
      website: website ?? this.website,
      socialMediaLinks: socialMediaLinks ?? this.socialMediaLinks,
      serviceAreas: serviceAreas ?? this.serviceAreas,
      culturalActivities: culturalActivities ?? this.culturalActivities,
    );
  }
}

// ====================== SPORTS CLUB MODEL ======================
class SportsClub {
  String? id;
  EducationCategory category;
  String clubName;
  SportsType sportType;
  String? coachName;
  String email;
  String phone;
  String address;
  String state;
  String city;
  String venue;
  String description;
  List<String> ageGroups;
  List<String> skillLevels;
  double membershipFee;
  String? schedule;
  List<String> equipmentProvided;
  String? coachQualifications;
  String? logoImageBase64;
  List<String>? galleryImagesBase64;
  List<String> amenities;

  String? postedByUserId;
  String? postedByName;
  String? postedByEmail;
  String? postedByProfileImageBase64;

  final double? latitude;
  final double? longitude;
  
  bool isVerified;
  bool isActive;
  bool isDeleted;
  double rating;
  int totalReviews;
  int totalLikes;
  List<String> likedByUsers;
  int currentMembers;
  int maxMembers;
  
  String createdBy;
  DateTime createdAt;
  DateTime updatedAt;
  
  Map<String, dynamic>? additionalInfo;
  List<String>? achievements;
  String? website;
  String? socialMediaLinks;
  List<String> tournaments;
  
  SportsClub({
    this.id,
    this.category = EducationCategory.localSports,
    required this.clubName,
    required this.sportType,
    this.coachName,
    required this.email,
    required this.phone,
    required this.address,
    required this.state,
    required this.city,
    required this.venue,
    required this.description,
    required this.ageGroups,
    required this.skillLevels,
    required this.membershipFee,
    this.schedule,
    required this.equipmentProvided,
    this.coachQualifications,
    this.logoImageBase64,
    this.galleryImagesBase64,
    this.amenities = const [],
    this.postedByUserId,
    this.postedByName,
    this.postedByEmail,
    this.postedByProfileImageBase64,
    this.latitude,
    this.longitude,
    this.isVerified = false,
    this.isActive = true,
    this.isDeleted = false,
    this.rating = 0.0,
    this.totalReviews = 0,
    this.totalLikes = 0,
    this.likedByUsers = const [],
    this.currentMembers = 0,
    this.maxMembers = 50,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.additionalInfo,
    this.achievements,
    this.website,
    this.socialMediaLinks,
    this.tournaments = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'category': category.stringValue,
      'categoryName': category.displayName,
      'clubName': clubName,
      'sportType': sportType.toString(),
      'sportTypeName': sportType.displayName,
      'coachName': coachName ?? '',
      'email': email,
      'phone': phone,
      'address': address,
      'state': state,
      'city': city,
      'venue': venue,
      'description': description,
      'ageGroups': ageGroups,
      'skillLevels': skillLevels,
      'membershipFee': membershipFee,
      'schedule': schedule ?? '',
      'equipmentProvided': equipmentProvided,
      'coachQualifications': coachQualifications ?? '',
      'logoImageBase64': logoImageBase64 ?? '',
      'galleryImagesBase64': galleryImagesBase64 ?? [],
      'amenities': amenities,
      'postedByUserId': postedByUserId ?? '',
      'postedByName': postedByName ?? '',
      'postedByEmail': postedByEmail ?? '',
      'postedByProfileImageBase64': postedByProfileImageBase64 ?? '',
      'latitude': latitude,
      'longitude': longitude,
      'isVerified': isVerified,
      'isActive': isActive,
      'isDeleted': isDeleted,
      'rating': rating,
      'totalReviews': totalReviews,
      'totalLikes': totalLikes,
      'likedByUsers': likedByUsers,
      'currentMembers': currentMembers,
      'maxMembers': maxMembers,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'additionalInfo': additionalInfo ?? {},
      'achievements': achievements ?? [],
      'website': website ?? '',
      'socialMediaLinks': socialMediaLinks ?? '',
      'tournaments': tournaments,
      'searchKeywords': _generateSearchKeywords(),
      'state_city': '${state}_$city',
    };
  }

  factory SportsClub.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    EducationCategory cat;
    try {
      cat = EducationCategory.values.firstWhere(
        (c) => c.stringValue == data['category'],
        orElse: () => EducationCategory.localSports,
      );
    } catch (e) {
      cat = EducationCategory.localSports;
    }

    SportsType sport;
    try {
      sport = SportsType.values.firstWhere(
        (s) => s.toString() == data['sportType'],
        orElse: () => SportsType.cricket,
      );
    } catch (e) {
      sport = SportsType.cricket;
    }

    return SportsClub(
      id: doc.id,
      category: cat,
      clubName: data['clubName'] ?? '',
      sportType: sport,
      coachName: data['coachName'],
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      address: data['address'] ?? '',
      state: data['state'] ?? '',
      city: data['city'] ?? '',
      venue: data['venue'] ?? '',
      description: data['description'] ?? '',
      ageGroups: List<String>.from(data['ageGroups'] ?? []),
      skillLevels: List<String>.from(data['skillLevels'] ?? []),
      membershipFee: (data['membershipFee'] ?? 0).toDouble(),
      schedule: data['schedule'],
      equipmentProvided: List<String>.from(data['equipmentProvided'] ?? []),
      coachQualifications: data['coachQualifications'],
      logoImageBase64: data['logoImageBase64'],
      galleryImagesBase64: List<String>.from(data['galleryImagesBase64'] ?? []),
      amenities: List<String>.from(data['amenities'] ?? []),
      postedByUserId: data['postedByUserId'] ?? '',
      postedByName: data['postedByName'] ?? '',
      postedByEmail: data['postedByEmail'] ?? '',
      postedByProfileImageBase64: data['postedByProfileImageBase64'] ?? '',
      latitude: data['latitude']?.toDouble(),
      longitude: data['longitude']?.toDouble(),
      isVerified: data['isVerified'] ?? false,
      isActive: data['isActive'] ?? true,
      isDeleted: data['isDeleted'] ?? false,
      rating: (data['rating'] ?? 0).toDouble(),
      totalReviews: data['totalReviews'] ?? 0,
      totalLikes: data['totalLikes'] ?? 0,
      likedByUsers: List<String>.from(data['likedByUsers'] ?? []),
      currentMembers: data['currentMembers'] ?? 0,
      maxMembers: data['maxMembers'] ?? 50,
      createdBy: data['createdBy'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      additionalInfo: Map<String, dynamic>.from(data['additionalInfo'] ?? {}),
      achievements: List<String>.from(data['achievements'] ?? []),
      website: data['website'],
      socialMediaLinks: data['socialMediaLinks'],
      tournaments: List<String>.from(data['tournaments'] ?? []),
    );
  }

  List<String> _generateSearchKeywords() {
    final keywords = <String>[
      clubName.toLowerCase(),
      coachName?.toLowerCase() ?? '',
      email.toLowerCase(),
      phone.toLowerCase(),
      address.toLowerCase(),
      state.toLowerCase(),
      city.toLowerCase(),
      venue.toLowerCase(),
      description.toLowerCase(),
      sportType.displayName.toLowerCase(),
      ...ageGroups.map((age) => age.toLowerCase()),
      ...skillLevels.map((level) => level.toLowerCase()),
      ...equipmentProvided.map((equipment) => equipment.toLowerCase()),
      ...amenities.map((amenity) => amenity.toLowerCase()),
      ...tournaments.map((tournament) => tournament.toLowerCase()),
    ];

    keywords.addAll(clubName.toLowerCase().split(' '));
    keywords.addAll(description.toLowerCase().split(' '));
    
    return keywords
        .where((keyword) => keyword.isNotEmpty && keyword.length > 2)
        .toSet()
        .toList();
  }

  String get formattedFee {
    return membershipFee > 0 
        ? '\$${membershipFee.toStringAsFixed(2)}/month'
        : 'Free';
  }

  String get membershipStatus {
    if (currentMembers >= maxMembers) {
      return 'Full - Waitlist Available';
    }
    final spotsLeft = maxMembers - currentMembers;
    return '$spotsLeft spots available';
  }

  Widget getLogoImageWidget({
    double size = 100,
    BoxShape shape = BoxShape.circle,
  }) {
    try {
      if (logoImageBase64 == null || logoImageBase64!.isEmpty) {
        return _buildDefaultLogoImage(size: size, shape: shape);
      }

      final base64String = cleanBase64String(logoImageBase64!);
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
          border: Border.all(color: Colors.grey.shade300, width: 1),
        ),
      );
    } catch (e) {
      return _buildDefaultLogoImage(size: size, shape: shape);
    }
  }

  Widget _buildDefaultLogoImage({
    required double size,
    required BoxShape shape,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: shape,
        color: category.color.withOpacity(0.1),
        border: Border.all(color: category.color.withOpacity(0.3), width: 1),
      ),
      child: Icon(
        Icons.sports_rounded,
        size: size * 0.5,
        color: category.color,
      ),
    );
  }

  String cleanBase64String(String base64) {
    String cleaned = base64.trim();
    if (cleaned.contains('base64,')) {
      cleaned = cleaned.split('base64,').last;
    }
    cleaned = cleaned.replaceAll(RegExp(r'\s'), '');
    if (cleaned.length % 4 != 0) {
      cleaned = cleaned.padRight(cleaned.length + (4 - cleaned.length % 4), '=');
    }
    return cleaned;
  }

  SportsClub copyWith({
    String? id,
    EducationCategory? category,
    String? clubName,
    SportsType? sportType,
    String? coachName,
    String? email,
    String? phone,
    String? address,
    String? state,
    String? city,
    String? venue,
    String? description,
    List<String>? ageGroups,
    List<String>? skillLevels,
    double? membershipFee,
    String? schedule,
    List<String>? equipmentProvided,
    String? coachQualifications,
    String? logoImageBase64,
    List<String>? galleryImagesBase64,
    List<String>? amenities,
    String? postedByUserId,
    String? postedByName,
    String? postedByEmail,
    String? postedByProfileImageBase64,
    double? latitude,
    double? longitude,
    bool? isVerified,
    bool? isActive,
    bool? isDeleted,
    double? rating,
    int? totalReviews,
    int? totalLikes,
    List<String>? likedByUsers,
    int? currentMembers,
    int? maxMembers,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? additionalInfo,
    List<String>? achievements,
    String? website,
    String? socialMediaLinks,
    List<String>? tournaments,
  }) {
    return SportsClub(
      id: id ?? this.id,
      category: category ?? this.category,
      clubName: clubName ?? this.clubName,
      sportType: sportType ?? this.sportType,
      coachName: coachName ?? this.coachName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      state: state ?? this.state,
      city: city ?? this.city,
      venue: venue ?? this.venue,
      description: description ?? this.description,
      ageGroups: ageGroups ?? this.ageGroups,
      skillLevels: skillLevels ?? this.skillLevels,
      membershipFee: membershipFee ?? this.membershipFee,
      schedule: schedule ?? this.schedule,
      equipmentProvided: equipmentProvided ?? this.equipmentProvided,
      coachQualifications: coachQualifications ?? this.coachQualifications,
      logoImageBase64: logoImageBase64 ?? this.logoImageBase64,
      galleryImagesBase64: galleryImagesBase64 ?? this.galleryImagesBase64,
      amenities: amenities ?? this.amenities,
      postedByUserId: postedByUserId ?? this.postedByUserId,
      postedByName: postedByName ?? this.postedByName,
      postedByEmail: postedByEmail ?? this.postedByEmail,
      postedByProfileImageBase64: postedByProfileImageBase64 ?? this.postedByProfileImageBase64,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isVerified: isVerified ?? this.isVerified,
      isActive: isActive ?? this.isActive,
      isDeleted: isDeleted ?? this.isDeleted,
      rating: rating ?? this.rating,
      totalReviews: totalReviews ?? this.totalReviews,
      totalLikes: totalLikes ?? this.totalLikes,
      likedByUsers: likedByUsers ?? this.likedByUsers,
      currentMembers: currentMembers ?? this.currentMembers,
      maxMembers: maxMembers ?? this.maxMembers,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      additionalInfo: additionalInfo ?? this.additionalInfo,
      achievements: achievements ?? this.achievements,
      website: website ?? this.website,
      socialMediaLinks: socialMediaLinks ?? this.socialMediaLinks,
      tournaments: tournaments ?? this.tournaments,
    );
  }
}