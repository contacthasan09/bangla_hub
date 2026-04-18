import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String? phoneNumber;
  final String? location;
  final String? profileImageUrl;
  final String role; // 'user', 'admin'
  final bool isEmailVerified;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? country;
  final String? countryCode;
  final double? latitude;
  final double? longitude;
  final DateTime? lastActiveAt;


  UserModel({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.phoneNumber,
    this.location,
    this.profileImageUrl,
    required this.role,
    this.isEmailVerified = false,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.country,
    this.countryCode,
    this.latitude,
    this.longitude,
    this.lastActiveAt,

  });

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      id: id,
      email: map['email'] ?? '',
      firstName: map['firstName'] ?? '',
      lastName: map['lastName'] ?? '',
      phoneNumber: map['phoneNumber'],
      location: map['location'],
      profileImageUrl: map['profileImageUrl'],
      role: map['role'] ?? 'user',
      isEmailVerified: map['isEmailVerified'] ?? false,
      isActive: map['isActive'] ?? true,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
      country: map['country'],
      countryCode: map['countryCode'],
      latitude: map['latitude']?.toDouble(),
      longitude: map['longitude']?.toDouble(),
      lastActiveAt: map['lastActiveAt'] != null
          ? (map['lastActiveAt'] as Timestamp).toDate()
          : null,

    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'phoneNumber': phoneNumber,
      'location': location,
      'profileImageUrl': profileImageUrl,
      'role': role,
      'isEmailVerified': isEmailVerified,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
      'country': country,
      'countryCode': countryCode,
      'latitude': latitude,
      'longitude': longitude,
      'lastActiveAt': lastActiveAt != null
       ? Timestamp.fromDate(lastActiveAt!)
       : null,

    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? location,
    String? profileImageUrl,
    String? role,
    bool? isEmailVerified,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? country,
    String? countryCode,
    double? latitude,
    double? longitude,
    DateTime? lastActiveAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      location: location ?? this.location,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      role: role ?? this.role,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      country: country ?? this.country,
      countryCode: countryCode ?? this.countryCode,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
    );
  }


  // models/user_model.dart - Add this method

UserModel copyWithProfileImage(String? profileImageUrl) {
  return UserModel(
    id: id,
    email: email,
    firstName: firstName,
    lastName: lastName,
    phoneNumber: phoneNumber,
    location: location,
    profileImageUrl: profileImageUrl,
    role: role,
    isEmailVerified: isEmailVerified,
    isActive: isActive,
    createdAt: createdAt,
    updatedAt: DateTime.now(),
    country: country,
    countryCode: countryCode,
    latitude: latitude,
    longitude: longitude,
    lastActiveAt: lastActiveAt,
  );
}

  bool get isAdmin => role == 'admin';
  bool get isUser => role == 'user';
  
  String get fullName => '$firstName $lastName';
}