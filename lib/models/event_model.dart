import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';

// Event Status Enum
enum EventStatus {
  pending,
  approved,
  suspended,
  deleted,
}

// Event Category Enum
enum EventCategory {
  all,
  sports,
  religious,
  business,
  educational,
  social,
}

class EventModel {
  final String id;
  final String title;
  final String organizer;
  final String contactPerson;
  final String contactEmail;
  final String contactPhone;
  final DateTime eventDate;
  final String location;
  final String description;
  final String? bannerImageUrl;
  final bool isFree;
  final Map<String, double>? ticketPrices;
  final String? paymentInfo;
  final String createdBy;
  final DateTime createdAt;
  final DateTime? updatedAt;

  final double? latitude;
  final double? longitude;
  final String? state;
  final String? city;
  
  // New fields
  final String category;
  final String status; // 'pending', 'approved', 'suspended', 'deleted'
  final int totalInterested; // Count of interested users
  
  EventModel({
    required this.id,
    required this.title,
    required this.organizer,
    required this.contactPerson,
    required this.contactEmail,
    required this.contactPhone,
    required this.eventDate,
    required this.location,
    required this.description,
    this.bannerImageUrl,
    required this.isFree,
    this.ticketPrices,
    this.paymentInfo,
    required this.createdBy,
    required this.createdAt,
    this.updatedAt,
    required this.category,
    this.status = 'pending',
    this.totalInterested = 0,

    this.latitude,
    this.longitude,
    this.state,
    this.city,
  });

  // Helper method to check if image is base64
  bool get isBase64Image {
    if (bannerImageUrl == null || bannerImageUrl!.isEmpty) return false;
    
    final String image = bannerImageUrl!;
    
    // Clean the string - remove any whitespace
    final cleanedImage = image.trim();
    
    // Check for data URL format
    if (cleanedImage.startsWith('data:image/')) {
      return true;
    }
    
    // Check for common base64 image signatures
    if (cleanedImage.startsWith('/9j/') || // JPEG
        cleanedImage.startsWith('iVBORw0KGgo') || // PNG
        cleanedImage.startsWith('R0lGODlh') || // GIF
        cleanedImage.startsWith('UklGR') || // WebP
        cleanedImage.startsWith('PHN2Zy') || // SVG in base64
        cleanedImage.startsWith('PD94bW')) { // PDF in base64 (just in case)
      return true;
    }
    
    // Try to validate as base64
    try {
      // Remove any data URL prefix
      String potentialBase64 = cleanedImage;
      if (potentialBase64.contains('base64,')) {
        potentialBase64 = potentialBase64.split('base64,').last;
      }
      
      // Decode to check if it's valid base64
      base64Decode(potentialBase64);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Helper method to check if image is a URL
  bool get isNetworkImage {
    if (bannerImageUrl == null || bannerImageUrl!.isEmpty) return false;
    
    final cleanedUrl = bannerImageUrl!.trim();
    
    // Check for common URL patterns
    if (cleanedUrl.startsWith('http://') || 
        cleanedUrl.startsWith('https://') ||
        cleanedUrl.startsWith('www.')) {
      return true;
    }
    
    // Try to parse as URI
    try {
      final uri = Uri.tryParse(cleanedUrl);
      return uri != null && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }

  // Method to safely get Image widget
  Widget get bannerImageWidget {
    try {
      if (bannerImageUrl == null || bannerImageUrl!.isEmpty) {
        return _buildDefaultImage();
      }
      
      final String imageUrl = bannerImageUrl!.trim();
      
      if (isBase64Image) {
        // Handle base64 image
        String base64String = imageUrl;
        
        // Remove data URL prefix if present
        if (base64String.contains('base64,')) {
          base64String = base64String.split('base64,').last;
        }
        
        // Clean the base64 string - remove any whitespace
        base64String = base64String.replaceAll(RegExp(r'\s'), '');
        
        try {
          // Decode base64 with padding if needed
          if (base64String.length % 4 != 0) {
            base64String = base64String.padRight(base64String.length + (4 - base64String.length % 4), '=');
          }
          
          final bytes = base64Decode(base64String);
          
          return Image.memory(
            bytes,
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              print('❌ Error decoding base64 image: $error');
              return _buildDefaultImage();
            },
          );
        } catch (decodeError) {
          print('❌ Base64 decode error: $decodeError');
          return _buildDefaultImage();
        }
      } else if (isNetworkImage) {
        // Handle network image
        return Image.network(
          imageUrl,
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.green,
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            print('❌ Error loading network image: $error');
            return _buildDefaultImage();
          },
        );
      } else {
        return _buildDefaultImage();
      }
    } catch (e) {
      print('❌ Error creating image widget: $e');
      return _buildDefaultImage();
    }
  }

  // Safe method to get ImageProvider
  ImageProvider? get bannerImageProvider {
    try {
      if (bannerImageUrl == null || bannerImageUrl!.isEmpty) {
        return null;
      }
      
      final String imageUrl = bannerImageUrl!.trim();
      
      if (isBase64Image) {
        String base64String = imageUrl;
        if (base64String.contains('base64,')) {
          base64String = base64String.split('base64,').last;
        }
        
        // Clean the base64 string
        base64String = base64String.replaceAll(RegExp(r'\s'), '');
        
        // Add padding if needed
        if (base64String.length % 4 != 0) {
          base64String = base64String.padRight(base64String.length + (4 - base64String.length % 4), '=');
        }
        
        try {
          final bytes = base64Decode(base64String);
          return MemoryImage(bytes);
        } catch (e) {
          print('❌ Error creating MemoryImage: $e');
          return null;
        }
      } else if (isNetworkImage) {
        return NetworkImage(imageUrl);
      }
      return null;
    } catch (e) {
      print('❌ Error getting image provider: $e');
      return null;
    }
  }

  // Helper method for min
  int min(int a, int b) => a < b ? a : b;

  Widget _buildDefaultImage() {
    return Container(
      color: Colors.green,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_rounded,
              size: 80,
              color: Colors.white.withOpacity(0.3),
            ),
            SizedBox(height: 8),
            Text(
              'Event Image',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Formatted date for display
  String get formattedDate {
    final now = DateTime.now();
    final difference = eventDate.difference(now);
    
    if (difference.inDays == 0) {
      return 'Today at ${DateFormat('h:mm a').format(eventDate)}';
    } else if (difference.inDays == 1) {
      return 'Tomorrow at ${DateFormat('h:mm a').format(eventDate)}';
    } else if (difference.inDays < 7) {
      return DateFormat('EEEE, MMM d').format(eventDate);
    } else {
      return DateFormat('MMM d, y').format(eventDate);
    }
  }

  String get fullFormattedDate {
    return DateFormat('EEEE, MMMM d, y - h:mm a').format(eventDate);
  }

  bool get isPast => eventDate.isBefore(DateTime.now());
  bool get isUpcoming => !isPast;
  
  // Helper getters for status
  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isSuspended => status == 'suspended';
  bool get isDeleted => status == 'deleted';
  
  // Helper for displaying interested count
  String get interestedCountText {
    if (totalInterested == 0) return 'No one interested yet';
    if (totalInterested == 1) return '1 person interested';
    return '$totalInterested people interested';
  }
  
  // Status color helper
  Color get statusColor {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'suspended':
        return Colors.red;
      case 'deleted':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }
  
  // Status text helper
  String get statusText {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'approved':
        return 'Approved';
      case 'suspended':
        return 'Suspended';
      case 'deleted':
        return 'Deleted';
      default:
        return 'Unknown';
    }
  }
  
  // Category text helper
  String get categoryText {
    switch (category) {
      case 'all':
        return 'All';
      case 'sports':
        return 'Sports';
      case 'religious':
        return 'Religious';
      case 'business':
        return 'Business';
      case 'educational':
        return 'Educational';
      case 'social':
        return 'Social';
      default:
        return category;
    }
  }
  
  // Icon for category
  IconData get categoryIcon {
    switch (category) {
      case 'all':
        return Icons.apps_rounded;
      case 'sports':
        return Icons.sports_soccer_rounded;
      case 'religious':
        return Icons.mosque_rounded;
      case 'business':
        return Icons.business_rounded;
      case 'educational':
        return Icons.school_rounded;
      case 'social':
        return Icons.groups_rounded;
      default:
        return Icons.event_rounded;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'organizer': organizer,
      'contactPerson': contactPerson,
      'contactEmail': contactEmail,
      'contactPhone': contactPhone,
      'eventDate': Timestamp.fromDate(eventDate),
      'location': location,
      'description': description,
      'bannerImageUrl': bannerImageUrl,
      'isFree': isFree,
      'ticketPrices': ticketPrices,
      'paymentInfo': paymentInfo,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'category': category,
      'status': status,
      'totalInterested': totalInterested,

      'latitude': latitude,
      'longitude': longitude,
      'state': state,
      'city': city,
    };
  }

  static EventModel fromMap(Map<String, dynamic> map, String id) {
    return EventModel(
      id: id,
      title: map['title'] ?? '',
      organizer: map['organizer'] ?? '',
      contactPerson: map['contactPerson'] ?? '',
      contactEmail: map['contactEmail'] ?? '',
      contactPhone: map['contactPhone'] ?? '',
      eventDate: (map['eventDate'] as Timestamp).toDate(),
      location: map['location'] ?? '',
      description: map['description'] ?? '',
      bannerImageUrl: map['bannerImageUrl'],
      isFree: map['isFree'] ?? true,
      ticketPrices: map['ticketPrices'] != null 
          ? Map<String, double>.from(map['ticketPrices'])
          : null,
      paymentInfo: map['paymentInfo'],
      createdBy: map['createdBy'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: map['updatedAt'] != null 
          ? (map['updatedAt'] as Timestamp).toDate()
          : null,
      category: map['category'] ?? 'social',
      status: map['status'] ?? 'pending',
      totalInterested: (map['totalInterested'] as int?) ?? 0,

      latitude: map['latitude']?.toDouble(),
      longitude: map['longitude']?.toDouble(),
      state: map['state'],
      city: map['city'],
    );
  }

  EventModel copyWith({
    String? id,
    String? title,
    String? organizer,
    String? contactPerson,
    String? contactEmail,
    String? contactPhone,
    DateTime? eventDate,
    String? location,
    String? description,
    String? bannerImageUrl,
    bool? isFree,
    Map<String, double>? ticketPrices,
    String? paymentInfo,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? category,
    String? status,
    int? totalInterested,
    double? latitude,
    double? longitude,
    String? state,
    String? city,
  }) {
    return EventModel(
      id: id ?? this.id,
      title: title ?? this.title,
      organizer: organizer ?? this.organizer,
      contactPerson: contactPerson ?? this.contactPerson,
      contactEmail: contactEmail ?? this.contactEmail,
      contactPhone: contactPhone ?? this.contactPhone,
      eventDate: eventDate ?? this.eventDate,
      location: location ?? this.location,
      description: description ?? this.description,
      bannerImageUrl: bannerImageUrl ?? this.bannerImageUrl,
      isFree: isFree ?? this.isFree,
      ticketPrices: ticketPrices ?? this.ticketPrices,
      paymentInfo: paymentInfo ?? this.paymentInfo,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      category: category ?? this.category,
      status: status ?? this.status,
      totalInterested: totalInterested ?? this.totalInterested,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      state: state ?? this.state,
      city: city ?? this.city,
    );
  }
}

// Helper extension for EventStatus
extension EventStatusExtension on EventStatus {
  String get displayName {
    switch (this) {
      case EventStatus.pending:
        return 'Pending';
      case EventStatus.approved:
        return 'Approved';
      case EventStatus.suspended:
        return 'Suspended';
      case EventStatus.deleted:
        return 'Deleted';
    }
  }
  
  // Get string value from enum
  String get stringValue {
    switch (this) {
      case EventStatus.pending:
        return 'pending';
      case EventStatus.approved:
        return 'approved';
      case EventStatus.suspended:
        return 'suspended';
      case EventStatus.deleted:
        return 'deleted';
    }
  }
  
  // Convert string to EventStatus
  static EventStatus fromString(String status) {
    switch (status) {
      case 'pending':
        return EventStatus.pending;
      case 'approved':
        return EventStatus.approved;
      case 'suspended':
        return EventStatus.suspended;
      case 'deleted':
        return EventStatus.deleted;
      default:
        return EventStatus.pending;
    }
  }
}

// Helper extension for EventCategory
extension EventCategoryExtension on EventCategory {
  String get displayName {
    switch (this) {
      case EventCategory.all:
        return 'All';
      case EventCategory.sports:
        return 'Sports';
      case EventCategory.religious:
        return 'Religious';
      case EventCategory.business:
        return 'Business';
      case EventCategory.educational:
        return 'Educational';
      case EventCategory.social:
        return 'Social';
    }
  }
  
  IconData get iconData {
    switch (this) {
      case EventCategory.all:
        return Icons.apps_rounded;
      case EventCategory.sports:
        return Icons.sports_soccer_rounded;
      case EventCategory.religious:
        return Icons.mosque_rounded;
      case EventCategory.business:
        return Icons.business_rounded;
      case EventCategory.educational:
        return Icons.school_rounded;
      case EventCategory.social:
        return Icons.groups_rounded;
    }
  }
  
  // Get string value from enum
  String get stringValue {
    switch (this) {
      case EventCategory.all:
        return 'all';
      case EventCategory.sports:
        return 'sports';
      case EventCategory.religious:
        return 'religious';
      case EventCategory.business:
        return 'business';
      case EventCategory.educational:
        return 'educational';
      case EventCategory.social:
        return 'social';
    }
  }
  
  // Convert string to EventCategory
  static EventCategory fromString(String category) {
    switch (category) {
      case 'all':
        return EventCategory.all;
      case 'sports':
        return EventCategory.sports;
      case 'religious':
        return EventCategory.religious;
      case 'business':
        return EventCategory.business;
      case 'educational':
        return EventCategory.educational;
      case 'social':
        return EventCategory.social;
      default:
        return EventCategory.social;
    }
  }
  
  // Get all categories except 'all'
  static List<EventCategory> get filterCategories {
    return [
      EventCategory.sports,
      EventCategory.religious,
      EventCategory.business,
      EventCategory.educational,
      EventCategory.social,
    ];
  }
}