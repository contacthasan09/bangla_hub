import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:convert';

// ====================== ENUMS & CONSTANTS ======================

// Entrepreneurship Categories Enum
enum EntrepreneurshipCategory {
  networkingBusinessPartner,
  jobPostings,
  smallBusinessPromotion,
  lookingForBusinessPartner,
}

extension EntrepreneurshipCategoryExtension on EntrepreneurshipCategory {
  String get displayName {
    switch (this) {
      case EntrepreneurshipCategory.networkingBusinessPartner:
        return 'Networking Business Partner';
      case EntrepreneurshipCategory.jobPostings:
        return 'Job Postings by Bengali Businesses';
      case EntrepreneurshipCategory.smallBusinessPromotion:
        return 'Small Business Promotion';
      case EntrepreneurshipCategory.lookingForBusinessPartner:
        return 'Looking for Business Partner';
    }
  }

  String get stringValue {
    switch (this) {
      case EntrepreneurshipCategory.networkingBusinessPartner:
        return 'networking_business_partner';
      case EntrepreneurshipCategory.jobPostings:
        return 'job_postings';
      case EntrepreneurshipCategory.smallBusinessPromotion:
        return 'small_business_promotion';
      case EntrepreneurshipCategory.lookingForBusinessPartner:
        return 'looking_for_business_partner';
    }
  }

  IconData get icon {
    switch (this) {
      case EntrepreneurshipCategory.networkingBusinessPartner:
        return Icons.store_rounded;
      case EntrepreneurshipCategory.jobPostings:
        return Icons.monetization_on_rounded;
      case EntrepreneurshipCategory.smallBusinessPromotion:
        return Icons.school_rounded;
      case EntrepreneurshipCategory.lookingForBusinessPartner:
        return Icons.network_check_rounded;
    }
  }

  Color get color {
    switch (this) {
      case EntrepreneurshipCategory.networkingBusinessPartner:
        return Color(0xFF3498db);
      case EntrepreneurshipCategory.jobPostings:
        return Color(0xFF2ecc71);
      case EntrepreneurshipCategory.smallBusinessPromotion:
        return Color(0xFFe74c3c);
      case EntrepreneurshipCategory.lookingForBusinessPartner:
        return Color(0xFF9b59b6);
    }
  }
}

// Job Type Enum
enum JobType {
  fullTime,
  partTime,
  contract,
  temporary,
  internship,
  remote,
}

extension JobTypeExtension on JobType {
  String get displayName {
    switch (this) {
      case JobType.fullTime:
        return 'Full Time';
      case JobType.partTime:
        return 'Part Time';
      case JobType.contract:
        return 'Contract';
      case JobType.temporary:
        return 'Temporary';
      case JobType.internship:
        return 'Internship';
      case JobType.remote:
        return 'Remote';
    }
  }
}

// Experience Level Enum
enum ExperienceLevel {
  entry,
  mid,
  senior,
  executive,
}

extension ExperienceLevelExtension on ExperienceLevel {
  String get displayName {
    switch (this) {
      case ExperienceLevel.entry:
        return 'Entry Level';
      case ExperienceLevel.mid:
        return 'Mid Level';
      case ExperienceLevel.senior:
        return 'Senior Level';
      case ExperienceLevel.executive:
        return 'Executive';
    }
  }
}

// Business Type Enum
enum BusinessType {
  soleProprietorship,
  partnership,
  corporation,
  llc,
  startup,
  freelance,
}

extension BusinessTypeExtension on BusinessType {
  String get displayName {
    switch (this) {
      case BusinessType.soleProprietorship:
        return 'Sole Proprietorship';
      case BusinessType.partnership:
        return 'Partnership';
      case BusinessType.corporation:
        return 'Corporation';
      case BusinessType.llc:
        return 'LLC';
      case BusinessType.startup:
        return 'Startup';
      case BusinessType.freelance:
        return 'Freelance';
    }
  }
}

// Partner Type Enum
enum PartnerType {
  investor,
  technicalPartner,
  marketingPartner,
  operationsPartner,
  silentPartner,
  strategicPartner,
}

extension PartnerTypeExtension on PartnerType {
  String get displayName {
    switch (this) {
      case PartnerType.investor:
        return 'Investor';
      case PartnerType.technicalPartner:
        return 'Technical Partner';
      case PartnerType.marketingPartner:
        return 'Marketing Partner';
      case PartnerType.operationsPartner:
        return 'Operations Partner';
      case PartnerType.silentPartner:
        return 'Silent Partner';
      case PartnerType.strategicPartner:
        return 'Strategic Partner';
    }
  }
}

// ====================== HELPER FUNCTIONS ======================

/// Helper function to clean Base64 strings
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

/// Helper function to check if a string is a URL
bool isUrlString(String str) {
  return str.startsWith('http://') || str.startsWith('https://');
}

/// Helper widget to display profile image (handles both URL and Base64)
Widget buildProfileImageWidget({
  required String? imageData,
  required double size,
  required VoidCallback? onError,
  Color? backgroundColor,
  IconData? fallbackIcon,
}) {
  if (imageData == null || imageData.isEmpty) {
    return _buildDefaultProfileImage(size: size, backgroundColor: backgroundColor, fallbackIcon: fallbackIcon);
  }

  if (isUrlString(imageData)) {
    return _buildNetworkImage(imageData, size);
  } else {
    try {
      final cleanedBase64 = cleanBase64String(imageData);
      final bytes = base64Decode(cleanedBase64);
      return _buildMemoryImage(bytes, size);
    } catch (e) {
      print('Error decoding Base64 image: $e');
      return _buildDefaultProfileImage(size: size, backgroundColor: backgroundColor, fallbackIcon: fallbackIcon);
    }
  }
}

Widget _buildNetworkImage(String url, double size) {
  return Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      image: DecorationImage(
        image: NetworkImage(url),
        fit: BoxFit.cover,
        onError: (exception, stackTrace) {
          print('Error loading network image: $exception');
        },
      ),
    ),
  );
}

Widget _buildMemoryImage(Uint8List bytes, double size) {
  return Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      image: DecorationImage(
        image: MemoryImage(bytes),
        fit: BoxFit.cover,
      ),
    ),
  );
}

Widget _buildDefaultProfileImage({
  required double size,
  Color? backgroundColor,
  IconData? fallbackIcon,
}) {
  return Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: backgroundColor ?? Colors.grey.shade200,
    ),
    child: Center(
      child: Icon(
        fallbackIcon ?? Icons.person_rounded,
        size: size * 0.5,
        color: Colors.grey.shade600,
      ),
    ),
  );
}

// ====================== NETWORKING BUSINESS PARTNER MODEL ======================
class NetworkingBusinessPartner {
  String? id;
  String businessName;
  String ownerName;
  String email;
  String phone;
  String address;
  String state;
  String city;
  BusinessType businessType;
  String industry;
  String description;
  String? website;
  String? licenseNumber;
  String? taxId;
  int yearsInBusiness;
  List<String> servicesOffered;
  List<String> targetMarkets;
  String? logoImageBase64;
  List<String>? galleryImagesBase64;
  List<String> businessHours;
  List<String> languagesSpoken;

  String? postedByUserId;
  String? postedByName;
  String? postedByEmail;
  String? postedByProfileImageBase64;

  double? latitude;
  double? longitude;
  
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
  List<String>? socialMediaLinks;

  NetworkingBusinessPartner({
    this.id,
    required this.businessName,
    required this.ownerName,
    required this.email,
    required this.phone,
    required this.address,
    required this.state,
    required this.city,
    required this.businessType,
    required this.industry,
    required this.description,
    this.website,
    this.licenseNumber,
    this.taxId,
    required this.yearsInBusiness,
    required this.servicesOffered,
    required this.targetMarkets,
    this.logoImageBase64,
    this.galleryImagesBase64,
    required this.businessHours,
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
    this.socialMediaLinks,
  });

  Map<String, dynamic> toMap() {
    return {
      'businessName': businessName,
      'ownerName': ownerName,
      'email': email,
      'phone': phone,
      'address': address,
      'state': state,
      'city': city,
      'businessType': businessType.toString(),
      'businessTypeName': businessType.displayName,
      'industry': industry,
      'description': description,
      'website': website ?? '',
      'licenseNumber': licenseNumber ?? '',
      'taxId': taxId ?? '',
      'yearsInBusiness': yearsInBusiness,
      'servicesOffered': servicesOffered,
      'targetMarkets': targetMarkets,
      'logoImageBase64': logoImageBase64 ?? '',
      'galleryImagesBase64': galleryImagesBase64 ?? [],
      'businessHours': businessHours,
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
      'socialMediaLinks': socialMediaLinks ?? '',
      'searchKeywords': _generateSearchKeywords(),
      'state_city': '${state}_$city',
      'industry_type': '${industry}_${businessType.toString()}',
    };
  }

  factory NetworkingBusinessPartner.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    BusinessType type;
    try {
      type = BusinessType.values.firstWhere(
        (t) => t.toString() == data['businessType'],
        orElse: () => BusinessType.soleProprietorship,
      );
    } catch (e) {
      type = BusinessType.soleProprietorship;
    }

    List<String>? socialMediaList;
    final socialMediaData = data['socialMediaLinks'];
    
    if (socialMediaData is List) {
      socialMediaList = List<String>.from(socialMediaData);
    } else if (socialMediaData is String) {
      if (socialMediaData.isNotEmpty) {
        if (socialMediaData.contains(',')) {
          socialMediaList = socialMediaData
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList();
        } else {
          socialMediaList = [socialMediaData];
        }
      } else {
        socialMediaList = [];
      }
    } else {
      socialMediaList = [];
    }

    return NetworkingBusinessPartner(
      id: doc.id,
      businessName: data['businessName'] ?? '',
      ownerName: data['ownerName'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      address: data['address'] ?? '',
      state: data['state'] ?? '',
      city: data['city'] ?? '',
      businessType: type,
      industry: data['industry'] ?? '',
      description: data['description'] ?? '',
      website: data['website'],
      licenseNumber: data['licenseNumber'],
      taxId: data['taxId'],
      yearsInBusiness: data['yearsInBusiness'] ?? 0,
      servicesOffered: List<String>.from(data['servicesOffered'] ?? []),
      targetMarkets: List<String>.from(data['targetMarkets'] ?? []),
      logoImageBase64: data['logoImageBase64'],
      galleryImagesBase64: List<String>.from(data['galleryImagesBase64'] ?? []),
      businessHours: List<String>.from(data['businessHours'] ?? []),
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
      socialMediaLinks: socialMediaList,
    );
  }

  List<String> _generateSearchKeywords() {
    final keywords = <String>[
      businessName.toLowerCase(),
      ownerName.toLowerCase(),
      email.toLowerCase(),
      phone.toLowerCase(),
      address.toLowerCase(),
      state.toLowerCase(),
      city.toLowerCase(),
      industry.toLowerCase(),
      businessType.displayName.toLowerCase(),
      ...servicesOffered.map((service) => service.toLowerCase()),
      ...targetMarkets.map((market) => market.toLowerCase()),
      ...languagesSpoken.map((lang) => lang.toLowerCase()),
    ];

    keywords.addAll(businessName.toLowerCase().split(' '));
    keywords.addAll(ownerName.toLowerCase().split(' '));
    keywords.addAll(description.toLowerCase().split(' '));
    
    return keywords
        .where((keyword) => keyword.isNotEmpty && keyword.length > 2)
        .toSet()
        .toList();
  }

  Widget getPosterProfileImageWidget({
    double size = 40,
    VoidCallback? onError,
  }) {
    return buildProfileImageWidget(
      imageData: postedByProfileImageBase64,
      size: size,
      onError: onError,
    );
  }

  Widget getLogoImageWidget({
    double size = 100,
    BoxShape shape = BoxShape.circle,
  }) {
    if (logoImageBase64 == null || logoImageBase64!.isEmpty) {
      return _buildDefaultLogoImage(size: size, shape: shape);
    }

    try {
      final cleanedBase64 = cleanBase64String(logoImageBase64!);
      final bytes = base64Decode(cleanedBase64);
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: shape,
          image: DecorationImage(
            image: MemoryImage(bytes),
            fit: BoxFit.cover,
          ),
          border: Border.all(color: Colors.grey.shade300),
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
        color: Colors.grey.shade200,
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Icon(
        Icons.store_rounded,
        size: size * 0.5,
        color: Colors.grey.shade600,
      ),
    );
  }

  NetworkingBusinessPartner copyWith({
    String? id,
    String? businessName,
    String? ownerName,
    String? email,
    String? phone,
    String? address,
    String? state,
    String? city,
    BusinessType? businessType,
    String? industry,
    String? description,
    String? website,
    String? licenseNumber,
    String? taxId,
    int? yearsInBusiness,
    List<String>? servicesOffered,
    List<String>? targetMarkets,
    String? logoImageBase64,
    List<String>? galleryImagesBase64,
    List<String>? businessHours,
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
    List<String>? socialMediaLinks,
  }) {
    return NetworkingBusinessPartner(
      id: id ?? this.id,
      businessName: businessName ?? this.businessName,
      ownerName: ownerName ?? this.ownerName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      state: state ?? this.state,
      city: city ?? this.city,
      businessType: businessType ?? this.businessType,
      industry: industry ?? this.industry,
      description: description ?? this.description,
      website: website ?? this.website,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      taxId: taxId ?? this.taxId,
      yearsInBusiness: yearsInBusiness ?? this.yearsInBusiness,
      servicesOffered: servicesOffered ?? this.servicesOffered,
      targetMarkets: targetMarkets ?? this.targetMarkets,
      logoImageBase64: logoImageBase64 ?? this.logoImageBase64,
      galleryImagesBase64: galleryImagesBase64 ?? this.galleryImagesBase64,
      businessHours: businessHours ?? this.businessHours,
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
      socialMediaLinks: socialMediaLinks ?? this.socialMediaLinks,
    );
  }
}

// ====================== JOB POSTING MODEL ======================
class JobPosting {
  String? id;
  String jobTitle;
  String companyName;
  EntrepreneurshipCategory category;
  String description;
  String requirements;
  String responsibilities;
  JobType jobType;
  ExperienceLevel experienceLevel;
  String location;
  String state;
  String city;
  double? salaryMin;
  double? salaryMax;
  String salaryPeriod;
  List<String> benefits;
  List<String> skillsRequired;
  String contactEmail;
  String contactPhone;
  String? applicationLink;
  DateTime applicationDeadline;
  int numberOfVacancies;

  String? postedByUserId;
  String? postedByName;
  String? postedByEmail;
  String? postedByProfileImageBase64;

  double? latitude;
  double? longitude;
  
  bool isVerified;
  bool isActive;
  bool isDeleted;
  bool isUrgent;
  
  String postedBy;
  DateTime createdAt;
  DateTime updatedAt;
  
  String? companyLogoBase64;
  List<String>? additionalDocumentsBase64;
  Map<String, dynamic>? additionalInfo;
  List<String> preferredQualifications;
  
  JobPosting({
    this.id,
    required this.jobTitle,
    required this.companyName,
    this.category = EntrepreneurshipCategory.jobPostings,
    required this.description,
    required this.requirements,
    required this.responsibilities,
    required this.jobType,
    required this.experienceLevel,
    required this.location,
    required this.state,
    required this.city,
    this.salaryMin,
    this.salaryMax,
    this.salaryPeriod = 'monthly',
    this.benefits = const [],
    required this.skillsRequired,
    required this.contactEmail,
    required this.contactPhone,
    this.applicationLink,
    required this.applicationDeadline,
    this.numberOfVacancies = 1,
    this.postedByUserId,
    this.postedByName,
    this.postedByEmail,
    this.postedByProfileImageBase64,
    this.latitude,
    this.longitude,
    this.isVerified = false,
    this.isActive = true,
    this.isDeleted = false,
    this.isUrgent = false,
    required this.postedBy,
    required this.createdAt,
    required this.updatedAt,
    this.companyLogoBase64,
    this.additionalDocumentsBase64,
    this.additionalInfo,
    this.preferredQualifications = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'jobTitle': jobTitle,
      'companyName': companyName,
      'category': category.stringValue,
      'categoryName': category.displayName,
      'description': description,
      'requirements': requirements,
      'responsibilities': responsibilities,
      'jobType': jobType.toString(),
      'jobTypeName': jobType.displayName,
      'experienceLevel': experienceLevel.toString(),
      'experienceLevelName': experienceLevel.displayName,
      'location': location,
      'state': state,
      'city': city,
      'salaryMin': salaryMin ?? 0,
      'salaryMax': salaryMax ?? 0,
      'salaryPeriod': salaryPeriod,
      'benefits': benefits,
      'skillsRequired': skillsRequired,
      'contactEmail': contactEmail,
      'contactPhone': contactPhone,
      'applicationLink': applicationLink ?? '',
      'applicationDeadline': Timestamp.fromDate(applicationDeadline),
      'numberOfVacancies': numberOfVacancies,
      'postedByUserId': postedByUserId ?? '',
      'postedByName': postedByName ?? '',
      'postedByEmail': postedByEmail ?? '',
      'postedByProfileImageBase64': postedByProfileImageBase64 ?? '',
      'latitude': latitude,
      'longitude': longitude,
      'isVerified': isVerified,
      'isActive': isActive,
      'isDeleted': isDeleted,
      'isUrgent': isUrgent,
      'postedBy': postedBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'companyLogoBase64': companyLogoBase64 ?? '',
      'additionalDocumentsBase64': additionalDocumentsBase64 ?? [],
      'additionalInfo': additionalInfo ?? {},
      'preferredQualifications': preferredQualifications,
      'searchKeywords': _generateSearchKeywords(),
      'state_city': '${state}_$city',
      'jobtype_experience': '${jobType.toString()}_${experienceLevel.toString()}',
    };
  }

  factory JobPosting.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    EntrepreneurshipCategory cat;
    try {
      cat = EntrepreneurshipCategory.values.firstWhere(
        (c) => c.stringValue == data['category'],
        orElse: () => EntrepreneurshipCategory.jobPostings,
      );
    } catch (e) {
      cat = EntrepreneurshipCategory.jobPostings;
    }

    JobType jType;
    try {
      jType = JobType.values.firstWhere(
        (j) => j.toString() == data['jobType'],
        orElse: () => JobType.fullTime,
      );
    } catch (e) {
      jType = JobType.fullTime;
    }

    ExperienceLevel expLevel;
    try {
      expLevel = ExperienceLevel.values.firstWhere(
        (e) => e.toString() == data['experienceLevel'],
        orElse: () => ExperienceLevel.entry,
      );
    } catch (e) {
      expLevel = ExperienceLevel.entry;
    }

    return JobPosting(
      id: doc.id,
      jobTitle: data['jobTitle'] ?? '',
      companyName: data['companyName'] ?? '',
      category: cat,
      description: data['description'] ?? '',
      requirements: data['requirements'] ?? '',
      responsibilities: data['responsibilities'] ?? '',
      jobType: jType,
      experienceLevel: expLevel,
      location: data['location'] ?? '',
      state: data['state'] ?? '',
      city: data['city'] ?? '',
      salaryMin: (data['salaryMin'] ?? 0).toDouble(),
      salaryMax: (data['salaryMax'] ?? 0).toDouble(),
      salaryPeriod: data['salaryPeriod'] ?? 'monthly',
      benefits: List<String>.from(data['benefits'] ?? []),
      skillsRequired: List<String>.from(data['skillsRequired'] ?? []),
      contactEmail: data['contactEmail'] ?? '',
      contactPhone: data['contactPhone'] ?? '',
      applicationLink: data['applicationLink'],
      applicationDeadline: (data['applicationDeadline'] as Timestamp).toDate(),
      numberOfVacancies: data['numberOfVacancies'] ?? 1,
      postedByUserId: data['postedByUserId'] ?? '',
      postedByName: data['postedByName'] ?? '',
      postedByEmail: data['postedByEmail'] ?? '',
      postedByProfileImageBase64: data['postedByProfileImageBase64'] ?? '',
      latitude: data['latitude']?.toDouble(),
      longitude: data['longitude']?.toDouble(),
      isVerified: data['isVerified'] ?? false,
      isActive: data['isActive'] ?? true,
      isDeleted: data['isDeleted'] ?? false,
      isUrgent: data['isUrgent'] ?? false,
      postedBy: data['postedBy'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      companyLogoBase64: data['companyLogoBase64'],
      additionalDocumentsBase64: List<String>.from(data['additionalDocumentsBase64'] ?? []),
      additionalInfo: Map<String, dynamic>.from(data['additionalInfo'] ?? {}),
      preferredQualifications: List<String>.from(data['preferredQualifications'] ?? []),
    );
  }

  List<String> _generateSearchKeywords() {
    final keywords = <String>[
      jobTitle.toLowerCase(),
      companyName.toLowerCase(),
      description.toLowerCase(),
      requirements.toLowerCase(),
      location.toLowerCase(),
      state.toLowerCase(),
      city.toLowerCase(),
      jobType.displayName.toLowerCase(),
      experienceLevel.displayName.toLowerCase(),
      ...skillsRequired.map((skill) => skill.toLowerCase()),
      ...benefits.map((benefit) => benefit.toLowerCase()),
    ];

    keywords.addAll(jobTitle.toLowerCase().split(' '));
    keywords.addAll(companyName.toLowerCase().split(' '));
    keywords.addAll(description.toLowerCase().split(' '));
    
    return keywords
        .where((keyword) => keyword.isNotEmpty && keyword.length > 2)
        .toSet()
        .toList();
  }

  Widget getPosterProfileImageWidget({
    double size = 40,
    VoidCallback? onError,
  }) {
    return buildProfileImageWidget(
      imageData: postedByProfileImageBase64,
      size: size,
      onError: onError,
    );
  }

  String get formattedSalary {
    if (salaryMin == null || salaryMax == null || salaryMin == 0) {
      return 'Negotiable';
    }
    return '\$${salaryMin!.toStringAsFixed(0)} - \$${salaryMax!.toStringAsFixed(0)} per $salaryPeriod';
  }

  bool get isExpired {
    return DateTime.now().isAfter(applicationDeadline);
  }

  Widget get statusBadge {
    if (isDeleted) return _buildBadge('Deleted', Colors.red);
    if (!isActive) return _buildBadge('Inactive', Colors.orange);
    if (isUrgent) return _buildBadge('Urgent', Colors.red);
    if (isVerified) return _buildBadge('Verified', Colors.green);
    if (isExpired) return _buildBadge('Expired', Colors.grey);
    return _buildBadge('Active', Colors.blue);
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  JobPosting copyWith({
    String? id,
    String? jobTitle,
    String? companyName,
    EntrepreneurshipCategory? category,
    String? description,
    String? requirements,
    String? responsibilities,
    JobType? jobType,
    ExperienceLevel? experienceLevel,
    String? location,
    String? state,
    String? city,
    double? salaryMin,
    double? salaryMax,
    String? salaryPeriod,
    List<String>? benefits,
    List<String>? skillsRequired,
    String? contactEmail,
    String? contactPhone,
    String? applicationLink,
    DateTime? applicationDeadline,
    int? numberOfVacancies,
    String? postedByUserId,
    String? postedByName,
    String? postedByEmail,
    String? postedByProfileImageBase64,
    double? latitude,
    double? longitude,
    bool? isVerified,
    bool? isActive,
    bool? isDeleted,
    bool? isUrgent,
    String? postedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? companyLogoBase64,
    List<String>? additionalDocumentsBase64,
    Map<String, dynamic>? additionalInfo,
    List<String>? preferredQualifications,
  }) {
    return JobPosting(
      id: id ?? this.id,
      jobTitle: jobTitle ?? this.jobTitle,
      companyName: companyName ?? this.companyName,
      category: category ?? this.category,
      description: description ?? this.description,
      requirements: requirements ?? this.requirements,
      responsibilities: responsibilities ?? this.responsibilities,
      jobType: jobType ?? this.jobType,
      experienceLevel: experienceLevel ?? this.experienceLevel,
      location: location ?? this.location,
      state: state ?? this.state,
      city: city ?? this.city,
      salaryMin: salaryMin ?? this.salaryMin,
      salaryMax: salaryMax ?? this.salaryMax,
      salaryPeriod: salaryPeriod ?? this.salaryPeriod,
      benefits: benefits ?? this.benefits,
      skillsRequired: skillsRequired ?? this.skillsRequired,
      contactEmail: contactEmail ?? this.contactEmail,
      contactPhone: contactPhone ?? this.contactPhone,
      applicationLink: applicationLink ?? this.applicationLink,
      applicationDeadline: applicationDeadline ?? this.applicationDeadline,
      numberOfVacancies: numberOfVacancies ?? this.numberOfVacancies,
      postedByUserId: postedByUserId ?? this.postedByUserId,
      postedByName: postedByName ?? this.postedByName,
      postedByEmail: postedByEmail ?? this.postedByEmail,
      postedByProfileImageBase64: postedByProfileImageBase64 ?? this.postedByProfileImageBase64,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isVerified: isVerified ?? this.isVerified,
      isActive: isActive ?? this.isActive,
      isDeleted: isDeleted ?? this.isDeleted,
      isUrgent: isUrgent ?? this.isUrgent,
      postedBy: postedBy ?? this.postedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      companyLogoBase64: companyLogoBase64 ?? this.companyLogoBase64,
      additionalDocumentsBase64: additionalDocumentsBase64 ?? this.additionalDocumentsBase64,
      additionalInfo: additionalInfo ?? this.additionalInfo,
      preferredQualifications: preferredQualifications ?? this.preferredQualifications,
    );
  }
}

// ====================== SMALL BUSINESS PROMOTION MODEL ======================
class SmallBusinessPromotion {
  String? id;
  String businessName;
  String ownerName;
  String description;
  String uniqueSellingPoints;
  List<String> productsServices;
  String targetAudience;
  String location;
  String state;
  String city;
  String contactEmail;
  String contactPhone;
  String? website;
  String? socialMediaLinks;
  String? promoVideoLink;
  String? logoImageBase64;
  List<String>? galleryImagesBase64;
  List<String> businessHours;
  double? specialOfferDiscount;
  String? offerValidity;
  List<String> paymentMethods;

  String? postedByUserId;
  String? postedByName;
  String? postedByEmail;
  String? postedByProfileImageBase64;

  double? latitude;
  double? longitude;
  
  bool isVerified;
  bool isActive;
  bool isDeleted;
  bool isFeatured;
  int totalViews;
  int totalShares;
  
  String createdBy;
  DateTime createdAt;
  DateTime updatedAt;
  
  EntrepreneurshipCategory category;
  List<String> businessTags;
  
  SmallBusinessPromotion({
    this.id,
    required this.businessName,
    required this.ownerName,
    required this.description,
    required this.uniqueSellingPoints,
    required this.productsServices,
    required this.targetAudience,
    required this.location,
    required this.state,
    required this.city,
    required this.contactEmail,
    required this.contactPhone,
    this.website,
    this.socialMediaLinks,
    this.promoVideoLink,
    this.logoImageBase64,
    this.galleryImagesBase64,
    this.businessHours = const [],
    this.specialOfferDiscount,
    this.offerValidity,
    this.paymentMethods = const [],
    this.postedByUserId,
    this.postedByName,
    this.postedByEmail,
    this.postedByProfileImageBase64,
    this.latitude,
    this.longitude,
    this.isVerified = false,
    this.isActive = true,
    this.isDeleted = false,
    this.isFeatured = false,
    this.totalViews = 0,
    this.totalShares = 0,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.category = EntrepreneurshipCategory.smallBusinessPromotion,
    this.businessTags = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'businessName': businessName,
      'ownerName': ownerName,
      'description': description,
      'uniqueSellingPoints': uniqueSellingPoints,
      'productsServices': productsServices,
      'targetAudience': targetAudience,
      'location': location,
      'state': state,
      'city': city,
      'contactEmail': contactEmail,
      'contactPhone': contactPhone,
      'website': website ?? '',
      'socialMediaLinks': socialMediaLinks ?? '',
      'promoVideoLink': promoVideoLink ?? '',
      'logoImageBase64': logoImageBase64 ?? '',
      'galleryImagesBase64': galleryImagesBase64 ?? [],
      'businessHours': businessHours,
      'specialOfferDiscount': specialOfferDiscount ?? 0,
      'offerValidity': offerValidity ?? '',
      'paymentMethods': paymentMethods,
      'postedByUserId': postedByUserId ?? '',
      'postedByName': postedByName ?? '',
      'postedByEmail': postedByEmail ?? '',
      'postedByProfileImageBase64': postedByProfileImageBase64 ?? '',
      'latitude': latitude,
      'longitude': longitude,
      'isVerified': isVerified,
      'isActive': isActive,
      'isDeleted': isDeleted,
      'isFeatured': isFeatured,
      'totalViews': totalViews,
      'totalShares': totalShares,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'category': category.stringValue,
      'categoryName': category.displayName,
      'businessTags': businessTags,
      'searchKeywords': _generateSearchKeywords(),
    };
  }

  factory SmallBusinessPromotion.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    EntrepreneurshipCategory cat;
    try {
      cat = EntrepreneurshipCategory.values.firstWhere(
        (c) => c.stringValue == data['category'],
        orElse: () => EntrepreneurshipCategory.smallBusinessPromotion,
      );
    } catch (e) {
      cat = EntrepreneurshipCategory.smallBusinessPromotion;
    }

    return SmallBusinessPromotion(
      id: doc.id,
      businessName: data['businessName'] ?? '',
      ownerName: data['ownerName'] ?? '',
      description: data['description'] ?? '',
      uniqueSellingPoints: data['uniqueSellingPoints'] ?? '',
      productsServices: List<String>.from(data['productsServices'] ?? []),
      targetAudience: data['targetAudience'] ?? '',
      location: data['location'] ?? '',
      state: data['state'] ?? '',
      city: data['city'] ?? '',
      contactEmail: data['contactEmail'] ?? '',
      contactPhone: data['contactPhone'] ?? '',
      website: data['website'],
      socialMediaLinks: data['socialMediaLinks'],
      promoVideoLink: data['promoVideoLink'],
      logoImageBase64: data['logoImageBase64'],
      galleryImagesBase64: List<String>.from(data['galleryImagesBase64'] ?? []),
      businessHours: List<String>.from(data['businessHours'] ?? []),
      specialOfferDiscount: (data['specialOfferDiscount'] ?? 0).toDouble(),
      offerValidity: data['offerValidity'],
      paymentMethods: List<String>.from(data['paymentMethods'] ?? []),
      postedByUserId: data['postedByUserId'] ?? '',
      postedByName: data['postedByName'] ?? '',
      postedByEmail: data['postedByEmail'] ?? '',
      postedByProfileImageBase64: data['postedByProfileImageBase64'] ?? '',
      latitude: data['latitude']?.toDouble(),
      longitude: data['longitude']?.toDouble(),
      isVerified: data['isVerified'] ?? false,
      isActive: data['isActive'] ?? true,
      isDeleted: data['isDeleted'] ?? false,
      isFeatured: data['isFeatured'] ?? false,
      totalViews: data['totalViews'] ?? 0,
      totalShares: data['totalShares'] ?? 0,
      createdBy: data['createdBy'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      category: cat,
      businessTags: List<String>.from(data['businessTags'] ?? []),
    );
  }

  List<String> _generateSearchKeywords() {
    final keywords = <String>[
      businessName.toLowerCase(),
      ownerName.toLowerCase(),
      description.toLowerCase(),
      uniqueSellingPoints.toLowerCase(),
      targetAudience.toLowerCase(),
      location.toLowerCase(),
      state.toLowerCase(),
      city.toLowerCase(),
      ...productsServices.map((product) => product.toLowerCase()),
      ...businessTags.map((tag) => tag.toLowerCase()),
    ];

    keywords.addAll(businessName.toLowerCase().split(' '));
    keywords.addAll(description.toLowerCase().split(' '));
    keywords.addAll(uniqueSellingPoints.toLowerCase().split(' '));
    
    return keywords
        .where((keyword) => keyword.isNotEmpty && keyword.length > 2)
        .toSet()
        .toList();
  }

  Widget getPosterProfileImageWidget({
    double size = 40,
    VoidCallback? onError,
  }) {
    return buildProfileImageWidget(
      imageData: postedByProfileImageBase64,
      size: size,
      onError: onError,
    );
  }

  static String cleanBase64String(String base64) {
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

  Widget getLogoImageWidget({
    double size = 100,
    BoxShape shape = BoxShape.circle,
  }) {
    if (logoImageBase64 == null || logoImageBase64!.isEmpty) {
      return _buildDefaultLogoImage(size: size, shape: shape);
    }

    try {
      final cleanedBase64 = cleanBase64String(logoImageBase64!);
      final bytes = base64Decode(cleanedBase64);
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: shape,
          image: DecorationImage(
            image: MemoryImage(bytes),
            fit: BoxFit.cover,
          ),
          border: Border.all(color: Colors.grey.shade300),
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
        color: Colors.grey.shade200,
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Icon(
        Icons.business_rounded,
        size: size * 0.5,
        color: Colors.grey.shade600,
      ),
    );
  }

  String get formattedOffer {
    if (specialOfferDiscount == null) return 'No current offers';
    return '$specialOfferDiscount% OFF - Valid until $offerValidity';
  }

  SmallBusinessPromotion copyWith({
    String? id,
    String? businessName,
    String? ownerName,
    String? description,
    String? uniqueSellingPoints,
    List<String>? productsServices,
    String? targetAudience,
    String? location,
    String? state,
    String? city,
    String? contactEmail,
    String? contactPhone,
    String? website,
    String? socialMediaLinks,
    String? promoVideoLink,
    String? logoImageBase64,
    List<String>? galleryImagesBase64,
    List<String>? businessHours,
    double? specialOfferDiscount,
    String? offerValidity,
    List<String>? paymentMethods,
    String? postedByUserId,
    String? postedByName,
    String? postedByEmail,
    String? postedByProfileImageBase64,
    double? latitude,
    double? longitude,
    bool? isVerified,
    bool? isActive,
    bool? isDeleted,
    bool? isFeatured,
    int? totalViews,
    int? totalShares,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    EntrepreneurshipCategory? category,
    List<String>? businessTags,
  }) {
    return SmallBusinessPromotion(
      id: id ?? this.id,
      businessName: businessName ?? this.businessName,
      ownerName: ownerName ?? this.ownerName,
      description: description ?? this.description,
      uniqueSellingPoints: uniqueSellingPoints ?? this.uniqueSellingPoints,
      productsServices: productsServices ?? this.productsServices,
      targetAudience: targetAudience ?? this.targetAudience,
      location: location ?? this.location,
      state: state ?? this.state,
      city: city ?? this.city,
      contactEmail: contactEmail ?? this.contactEmail,
      contactPhone: contactPhone ?? this.contactPhone,
      website: website ?? this.website,
      socialMediaLinks: socialMediaLinks ?? this.socialMediaLinks,
      promoVideoLink: promoVideoLink ?? this.promoVideoLink,
      logoImageBase64: logoImageBase64 ?? this.logoImageBase64,
      galleryImagesBase64: galleryImagesBase64 ?? this.galleryImagesBase64,
      businessHours: businessHours ?? this.businessHours,
      specialOfferDiscount: specialOfferDiscount ?? this.specialOfferDiscount,
      offerValidity: offerValidity ?? this.offerValidity,
      paymentMethods: paymentMethods ?? this.paymentMethods,
      postedByUserId: postedByUserId ?? this.postedByUserId,
      postedByName: postedByName ?? this.postedByName,
      postedByEmail: postedByEmail ?? this.postedByEmail,
      postedByProfileImageBase64: postedByProfileImageBase64 ?? this.postedByProfileImageBase64,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isVerified: isVerified ?? this.isVerified,
      isActive: isActive ?? this.isActive,
      isDeleted: isDeleted ?? this.isDeleted,
      isFeatured: isFeatured ?? this.isFeatured,
      totalViews: totalViews ?? this.totalViews,
      totalShares: totalShares ?? this.totalShares,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      category: category ?? this.category,
      businessTags: businessTags ?? this.businessTags,
    );
  }
}

// ====================== LOOKING FOR BUSINESS PARTNER MODEL ======================
class BusinessPartnerRequest {
  String? id;
  String title;
  String description;
  PartnerType partnerType;
  BusinessType businessType;
  String industry;
  String location;
  String state;
  String city;
  double budgetMin;
  double budgetMax;
  String investmentDuration;
  List<String> skillsRequired;
  List<String> responsibilities;
  String contactName;
  String contactEmail;
  String contactPhone;
  String? preferredMeetingMethod;
  List<String>? additionalDocumentsBase64;

  String? postedByUserId;
  String? postedByName;
  String? postedByEmail;
  String? postedByProfileImageBase64;

  double? latitude;
  double? longitude;
  
  bool isVerified;
  bool isActive;
  bool isDeleted;
  bool isUrgent;
  int totalViews;
  int totalResponses;
  
  String createdBy;
  DateTime createdAt;
  DateTime updatedAt;
  
  EntrepreneurshipCategory category;
  List<String> tags;
  Map<String, dynamic>? additionalInfo;
  
  BusinessPartnerRequest({
    this.id,
    required this.title,
    required this.description,
    required this.partnerType,
    required this.businessType,
    required this.industry,
    required this.location,
    required this.state,
    required this.city,
    required this.budgetMin,
    required this.budgetMax,
    required this.investmentDuration,
    required this.skillsRequired,
    required this.responsibilities,
    required this.contactName,
    required this.contactEmail,
    required this.contactPhone,
    this.preferredMeetingMethod,
    this.additionalDocumentsBase64,
    this.postedByUserId,
    this.postedByName,
    this.postedByEmail,
    this.postedByProfileImageBase64,
    this.latitude,
    this.longitude,
    this.isVerified = false,
    this.isActive = true,
    this.isDeleted = false,
    this.isUrgent = false,
    this.totalViews = 0,
    this.totalResponses = 0,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.category = EntrepreneurshipCategory.lookingForBusinessPartner,
    this.tags = const [],
    this.additionalInfo,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'partnerType': partnerType.toString(),
      'partnerTypeName': partnerType.displayName,
      'businessType': businessType.toString(),
      'businessTypeName': businessType.displayName,
      'industry': industry,
      'location': location,
      'state': state,
      'city': city,
      'budgetMin': budgetMin,
      'budgetMax': budgetMax,
      'investmentDuration': investmentDuration,
      'skillsRequired': skillsRequired,
      'responsibilities': responsibilities,
      'contactName': contactName,
      'contactEmail': contactEmail,
      'contactPhone': contactPhone,
      'preferredMeetingMethod': preferredMeetingMethod ?? '',
      'additionalDocumentsBase64': additionalDocumentsBase64 ?? [],
      'postedByUserId': postedByUserId ?? '',
      'postedByName': postedByName ?? '',
      'postedByEmail': postedByEmail ?? '',
      'postedByProfileImageBase64': postedByProfileImageBase64 ?? '',
      'latitude': latitude,
      'longitude': longitude,
      'isVerified': isVerified,
      'isActive': isActive,
      'isDeleted': isDeleted,
      'isUrgent': isUrgent,
      'totalViews': totalViews,
      'totalResponses': totalResponses,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'category': category.stringValue,
      'categoryName': category.displayName,
      'tags': tags,
      'additionalInfo': additionalInfo ?? {},
      'searchKeywords': _generateSearchKeywords(),
    };
  }

  factory BusinessPartnerRequest.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    PartnerType pType;
    try {
      pType = PartnerType.values.firstWhere(
        (p) => p.toString() == data['partnerType'],
        orElse: () => PartnerType.investor,
      );
    } catch (e) {
      pType = PartnerType.investor;
    }

    BusinessType bType;
    try {
      bType = BusinessType.values.firstWhere(
        (b) => b.toString() == data['businessType'],
        orElse: () => BusinessType.startup,
      );
    } catch (e) {
      bType = BusinessType.startup;
    }

    EntrepreneurshipCategory cat;
    try {
      cat = EntrepreneurshipCategory.values.firstWhere(
        (c) => c.stringValue == data['category'],
        orElse: () => EntrepreneurshipCategory.lookingForBusinessPartner,
      );
    } catch (e) {
      cat = EntrepreneurshipCategory.lookingForBusinessPartner;
    }

    return BusinessPartnerRequest(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      partnerType: pType,
      businessType: bType,
      industry: data['industry'] ?? '',
      location: data['location'] ?? '',
      state: data['state'] ?? '',
      city: data['city'] ?? '',
      budgetMin: (data['budgetMin'] ?? 0).toDouble(),
      budgetMax: (data['budgetMax'] ?? 0).toDouble(),
      investmentDuration: data['investmentDuration'] ?? '',
      skillsRequired: List<String>.from(data['skillsRequired'] ?? []),
      responsibilities: List<String>.from(data['responsibilities'] ?? []),
      contactName: data['contactName'] ?? '',
      contactEmail: data['contactEmail'] ?? '',
      contactPhone: data['contactPhone'] ?? '',
      preferredMeetingMethod: data['preferredMeetingMethod'],
      additionalDocumentsBase64: List<String>.from(data['additionalDocumentsBase64'] ?? []),
      isVerified: data['isVerified'] ?? false,
      postedByUserId: data['postedByUserId'] ?? '',
      postedByName: data['postedByName'] ?? '',
      postedByEmail: data['postedByEmail'] ?? '',
      postedByProfileImageBase64: data['postedByProfileImageBase64'] ?? '',
      latitude: data['latitude']?.toDouble(),
      longitude: data['longitude']?.toDouble(),
      isActive: data['isActive'] ?? true,
      isDeleted: data['isDeleted'] ?? false,
      isUrgent: data['isUrgent'] ?? false,
      totalViews: data['totalViews'] ?? 0,
      totalResponses: data['totalResponses'] ?? 0,
      createdBy: data['createdBy'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      category: cat,
      tags: List<String>.from(data['tags'] ?? []),
      additionalInfo: Map<String, dynamic>.from(data['additionalInfo'] ?? {}),
    );
  }

  List<String> _generateSearchKeywords() {
    final keywords = <String>[
      title.toLowerCase(),
      description.toLowerCase(),
      industry.toLowerCase(),
      location.toLowerCase(),
      state.toLowerCase(),
      city.toLowerCase(),
      partnerType.displayName.toLowerCase(),
      businessType.displayName.toLowerCase(),
      ...skillsRequired.map((skill) => skill.toLowerCase()),
      ...responsibilities.map((resp) => resp.toLowerCase()),
      ...tags.map((tag) => tag.toLowerCase()),
    ];

    keywords.addAll(title.toLowerCase().split(' '));
    keywords.addAll(description.toLowerCase().split(' '));
    keywords.addAll(industry.toLowerCase().split(' '));
    
    return keywords
        .where((keyword) => keyword.isNotEmpty && keyword.length > 2)
        .toSet()
        .toList();
  }

  Widget getPosterProfileImageWidget({
    double size = 40,
    VoidCallback? onError,
  }) {
    return buildProfileImageWidget(
      imageData: postedByProfileImageBase64,
      size: size,
      onError: onError,
    );
  }

  String get formattedBudget {
    return '\$${budgetMin.toStringAsFixed(0)} - \$${budgetMax.toStringAsFixed(0)}';
  }

  Widget get urgencyBadge {
    if (!isActive) return _buildBadge('Closed', Colors.grey);
    if (isUrgent) return _buildBadge('Urgent', Colors.red);
    if (isVerified) return _buildBadge('Verified', Colors.green);
    return _buildBadge('Open', Colors.blue);
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  BusinessPartnerRequest copyWith({
    String? id,
    String? title,
    String? description,
    PartnerType? partnerType,
    BusinessType? businessType,
    String? industry,
    String? location,
    String? state,
    String? city,
    double? budgetMin,
    double? budgetMax,
    String? investmentDuration,
    List<String>? skillsRequired,
    List<String>? responsibilities,
    String? contactName,
    String? contactEmail,
    String? contactPhone,
    String? preferredMeetingMethod,
    List<String>? additionalDocumentsBase64,
    String? postedByUserId,
    String? postedByName,
    String? postedByEmail,
    String? postedByProfileImageBase64,
    double? latitude,
    double? longitude,
    bool? isVerified,
    bool? isActive,
    bool? isDeleted,
    bool? isUrgent,
    int? totalViews,
    int? totalResponses,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    EntrepreneurshipCategory? category,
    List<String>? tags,
    Map<String, dynamic>? additionalInfo,
  }) {
    return BusinessPartnerRequest(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      partnerType: partnerType ?? this.partnerType,
      businessType: businessType ?? this.businessType,
      industry: industry ?? this.industry,
      location: location ?? this.location,
      state: state ?? this.state,
      city: city ?? this.city,
      budgetMin: budgetMin ?? this.budgetMin,
      budgetMax: budgetMax ?? this.budgetMax,
      investmentDuration: investmentDuration ?? this.investmentDuration,
      skillsRequired: skillsRequired ?? this.skillsRequired,
      responsibilities: responsibilities ?? this.responsibilities,
      contactName: contactName ?? this.contactName,
      contactEmail: contactEmail ?? this.contactEmail,
      contactPhone: contactPhone ?? this.contactPhone,
      preferredMeetingMethod: preferredMeetingMethod ?? this.preferredMeetingMethod,
      additionalDocumentsBase64: additionalDocumentsBase64 ?? this.additionalDocumentsBase64,
      postedByUserId: postedByUserId ?? this.postedByUserId,
      postedByName: postedByName ?? this.postedByName,
      postedByEmail: postedByEmail ?? this.postedByEmail,
      postedByProfileImageBase64: postedByProfileImageBase64 ?? this.postedByProfileImageBase64,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isVerified: isVerified ?? this.isVerified,
      isActive: isActive ?? this.isActive,
      isDeleted: isDeleted ?? this.isDeleted,
      isUrgent: isUrgent ?? this.isUrgent,
      totalViews: totalViews ?? this.totalViews,
      totalResponses: totalResponses ?? this.totalResponses,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      additionalInfo: additionalInfo ?? this.additionalInfo,
    );
  }
}