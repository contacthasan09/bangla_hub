// models/event_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:bangla_hub/services/cloudinary_service.dart';

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
  final String? contactEmail;  // ✅ Made nullable
  final String contactPhone;
  final DateTime eventDate;
  final DateTime? endDate;
  final TimeOfDay? startTime;
  final TimeOfDay? endTime;
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
  
  final String category;
  final String status;
  final int totalInterested;
  
  EventModel({
    required this.id,
    required this.title,
    required this.organizer,
    required this.contactPerson,
    this.contactEmail,  // ✅ Made nullable
    required this.contactPhone,
    required this.eventDate,
    this.endDate,
    this.startTime,
    this.endTime,
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

  // Helper properties
  bool get isMultiDay => endDate != null && endDate != eventDate;
  bool get hasTime => startTime != null;
  bool get isPast => eventDate.isBefore(DateTime.now());
  bool get isUpcoming => !isPast;
  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isSuspended => status == 'suspended';
  bool get isDeleted => status == 'deleted';
  
  String get interestedCountText {
    if (totalInterested == 0) return 'No one interested yet';
    if (totalInterested == 1) return '1 person interested';
    return '$totalInterested people interested';
  }
  
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

  // Cloudinary URL helpers
  bool get isCloudinaryUrl {
    return bannerImageUrl != null && bannerImageUrl!.contains('cloudinary.com');
  }
  
  // Get optimized URL for different sizes
  String getOptimizedBannerUrl({int width = 800, int height = 400, String crop = 'fill'}) {
    if (bannerImageUrl == null || bannerImageUrl!.isEmpty) return '';
    
    if (isCloudinaryUrl) {
      return CloudinaryService.getOptimizedUrl(
        bannerImageUrl!,
        width: width,
        height: height,
        crop: crop,
      );
    }
    
    return bannerImageUrl!;
  }
  
  // Thumbnail for list items (200x150)
  String get thumbnailUrl {
    if (bannerImageUrl == null || bannerImageUrl!.isEmpty) return '';
    if (isCloudinaryUrl) {
      return CloudinaryService.getThumbnailUrl(bannerImageUrl!);
    }
    return bannerImageUrl!;
  }
  
  // Card image for carousel (400x250)
  String get cardUrl {
    if (bannerImageUrl == null || bannerImageUrl!.isEmpty) return '';
    if (isCloudinaryUrl) {
      return CloudinaryService.getCardUrl(bannerImageUrl!);
    }
    return bannerImageUrl!;
  }
  
  // Full quality for details screen (1200x600)
  String get fullQualityUrl {
    if (bannerImageUrl == null || bannerImageUrl!.isEmpty) return '';
    if (isCloudinaryUrl) {
      return CloudinaryService.getFullQualityUrl(bannerImageUrl!);
    }
    return bannerImageUrl!;
  }
  
  // Small thumbnail for chat/notifications (100x75)
  String get smallThumbnailUrl {
    if (bannerImageUrl == null || bannerImageUrl!.isEmpty) return '';
    if (isCloudinaryUrl) {
      return CloudinaryService.getOptimizedUrl(bannerImageUrl!, width: 100, height: 75, crop: 'thumb');
    }
    return bannerImageUrl!;
  }

  // Formatted date strings
  String get formattedDateRange {
    if (isMultiDay && endDate != null) {
      return '${DateFormat('MMM d').format(eventDate)} - ${DateFormat('MMM d, y').format(endDate!)}';
    }
    return DateFormat('MMM d, y').format(eventDate);
  }

  String get formattedDateRangeLong {
    if (isMultiDay && endDate != null) {
      return '${DateFormat('EEEE, MMMM d').format(eventDate)} - ${DateFormat('EEEE, MMMM d, y').format(endDate!)}';
    }
    return DateFormat('EEEE, MMMM d, y').format(eventDate);
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  String get formattedTimeRange {
    if (startTime != null && endTime != null) {
      return '${_formatTimeOfDay(startTime!)} - ${_formatTimeOfDay(endTime!)}';
    } else if (startTime != null) {
      return '${_formatTimeOfDay(startTime!)}';
    }
    return 'Time TBA';
  }

  String get fullFormattedDateTime {
    String result = '';
    
    if (isMultiDay && endDate != null) {
      result = formattedDateRangeLong;
      if (startTime != null) {
        result += ' • ${_formatTimeOfDay(startTime!)}';
        if (endTime != null) {
          result += ' - ${_formatTimeOfDay(endTime!)}';
        }
      }
    } else {
      result = DateFormat('EEEE, MMMM d, y').format(eventDate);
      if (startTime != null) {
        result += ' at ${_formatTimeOfDay(startTime!)}';
        if (endTime != null) {
          result += ' - ${_formatTimeOfDay(endTime!)}';
        }
      }
    }
    
    return result;
  }

  String get compactFormattedDateTime {
    String result = '';
    
    if (isMultiDay && endDate != null) {
      result = formattedDateRange;
      if (startTime != null) {
        result += ' • ${_formatTimeOfDay(startTime!)}';
        if (endTime != null) {
          result += ' - ${_formatTimeOfDay(endTime!)}';
        }
      }
    } else {
      result = DateFormat('MMM d, y').format(eventDate);
      if (startTime != null) {
        result += ' • ${_formatTimeOfDay(startTime!)}';
        if (endTime != null) {
          result += ' - ${_formatTimeOfDay(endTime!)}';
        }
      }
    }
    
    return result;
  }

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

  // Base64 image detection
  bool get isBase64Image {
    if (bannerImageUrl == null || bannerImageUrl!.isEmpty) return false;
    
    final String image = bannerImageUrl!;
    final cleanedImage = image.trim();
    
    if (cleanedImage.startsWith('data:image/')) {
      return true;
    }
    
    if (cleanedImage.startsWith('/9j/') ||
        cleanedImage.startsWith('iVBORw0KGgo') ||
        cleanedImage.startsWith('R0lGODlh') ||
        cleanedImage.startsWith('UklGR') ||
        cleanedImage.startsWith('PHN2Zy') ||
        cleanedImage.startsWith('PD94bW')) {
      return true;
    }
    
    try {
      String potentialBase64 = cleanedImage;
      if (potentialBase64.contains('base64,')) {
        potentialBase64 = potentialBase64.split('base64,').last;
      }
      base64Decode(potentialBase64);
      return true;
    } catch (e) {
      return false;
    }
  }

  bool get isNetworkImage {
    if (bannerImageUrl == null || bannerImageUrl!.isEmpty) return false;
    
    final cleanedUrl = bannerImageUrl!.trim();
    
    if (cleanedUrl.startsWith('http://') || 
        cleanedUrl.startsWith('https://') ||
        cleanedUrl.startsWith('www.')) {
      return true;
    }
    
    try {
      final uri = Uri.tryParse(cleanedUrl);
      return uri != null && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }


  // Add this getter to your EventModel class (after the existing getters)

// Check if event has an image (either Cloudinary, network, or base64)
bool get isImageAvailable {
  if (bannerImageUrl == null || bannerImageUrl!.isEmpty) {
    return false;
  }
  
  final url = bannerImageUrl!.trim();
  
  // Check if it's a valid Cloudinary URL
  if (url.contains('cloudinary.com') && url.contains('/upload/')) {
    return true;
  }
  
  // Check if it's a valid network URL
  if (url.startsWith('http://') || url.startsWith('https://')) {
    return true;
  }
  
  // Check if it's a base64 image
  if (url.startsWith('data:image/') || 
      url.startsWith('/9j/') || 
      url.startsWith('iVBORw0KGgo')) {
    return true;
  }
  
  return false;
}

// Get appropriate image URL for display
String get displayImageUrl {
  if (!isImageAvailable) return '';
  
  final url = bannerImageUrl!.trim();
  
  // Use optimized thumbnail for Cloudinary images
  if (isCloudinaryUrl) {
    return thumbnailUrl;
  }
  
  return url;
}

  // Image widget builder
  Widget get bannerImageWidget {
    try {
      if (bannerImageUrl == null || bannerImageUrl!.isEmpty) {
        return _buildDefaultImage();
      }
      
      final String imageUrl = bannerImageUrl!.trim();
      
      if (isBase64Image) {
        String base64String = imageUrl;
        if (base64String.contains('base64,')) {
          base64String = base64String.split('base64,').last;
        }
        base64String = base64String.replaceAll(RegExp(r'\s'), '');
        
        try {
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
        // Use optimized Cloudinary URL if applicable
        final displayUrl = isCloudinaryUrl ? cardUrl : imageUrl;
        return Image.network(
          displayUrl,
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
        base64String = base64String.replaceAll(RegExp(r'\s'), '');
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
        final displayUrl = isCloudinaryUrl ? thumbnailUrl : imageUrl;
        return NetworkImage(displayUrl);
      }
      return null;
    } catch (e) {
      print('❌ Error getting image provider: $e');
      return null;
    }
  }

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
            const SizedBox(height: 8),
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

  // Convert to Firestore map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'organizer': organizer,
      'contactPerson': contactPerson,
      'contactEmail': contactEmail,  // ✅ Now nullable, can be null
      'contactPhone': contactPhone,
      'eventDate': Timestamp.fromDate(eventDate),
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'startTimeHour': startTime?.hour,
      'startTimeMinute': startTime?.minute,
      'endTimeHour': endTime?.hour,
      'endTimeMinute': endTime?.minute,
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

  // Create from Firestore map
  static EventModel fromMap(Map<String, dynamic> map, String id) {
    TimeOfDay? startTime;
    if (map['startTimeHour'] != null && map['startTimeMinute'] != null) {
      startTime = TimeOfDay(
        hour: map['startTimeHour'],
        minute: map['startTimeMinute'],
      );
    }
    
    TimeOfDay? endTime;
    if (map['endTimeHour'] != null && map['endTimeMinute'] != null) {
      endTime = TimeOfDay(
        hour: map['endTimeHour'],
        minute: map['endTimeMinute'],
      );
    }
    
    return EventModel(
      id: id,
      title: map['title'] ?? '',
      organizer: map['organizer'] ?? '',
      contactPerson: map['contactPerson'] ?? '',
      contactEmail: map['contactEmail'],  // ✅ Can be null
      contactPhone: map['contactPhone'] ?? '',
      eventDate: (map['eventDate'] as Timestamp).toDate(),
      endDate: map['endDate'] != null ? (map['endDate'] as Timestamp).toDate() : null,
      startTime: startTime,
      endTime: endTime,
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

  // Copy with method
  EventModel copyWith({
    String? id,
    String? title,
    String? organizer,
    String? contactPerson,
    String? contactEmail,  // ✅ Made nullable
    String? contactPhone,
    DateTime? eventDate,
    DateTime? endDate,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
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
      contactEmail: contactEmail ?? this.contactEmail,  // ✅ Now nullable
      contactPhone: contactPhone ?? this.contactPhone,
      eventDate: eventDate ?? this.eventDate,
      endDate: endDate ?? this.endDate,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
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

// Extension methods for enums
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