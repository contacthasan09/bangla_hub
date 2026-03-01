// lib/models/job_sites_browse_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum JobSiteCategory {
  general,
  tech,
  healthcare,
  education,
  remote,
  freelance,
  entryLevel,
  executive,
}

extension JobSiteCategoryExtension on JobSiteCategory {
  String get displayName {
    switch (this) {
      case JobSiteCategory.general:
        return 'General Job Sites';
      case JobSiteCategory.tech:
        return 'Tech & IT';
      case JobSiteCategory.healthcare:
        return 'Healthcare';
      case JobSiteCategory.education:
        return 'Education';
      case JobSiteCategory.remote:
        return 'Remote Work';
      case JobSiteCategory.freelance:
        return 'Freelance';
      case JobSiteCategory.entryLevel:
        return 'Entry Level';
      case JobSiteCategory.executive:
        return 'Executive';
    }
  }

  IconData get icon {
    switch (this) {
      case JobSiteCategory.general:
        return Icons.work_rounded;
      case JobSiteCategory.tech:
        return Icons.computer_rounded;
      case JobSiteCategory.healthcare:
        return Icons.medical_services_rounded;
      case JobSiteCategory.education:
        return Icons.school_rounded;
      case JobSiteCategory.remote:
        return Icons.wifi_rounded;
      case JobSiteCategory.freelance:
        return Icons.brush_rounded;
      case JobSiteCategory.entryLevel:
        return Icons.trending_up_rounded;
      case JobSiteCategory.executive:
        return Icons.leaderboard_rounded;
    }
  }

  Color get color {
    switch (this) {
      case JobSiteCategory.general:
        return Color(0xFF2196F3); // Blue
      case JobSiteCategory.tech:
        return Color(0xFF4CAF50); // Green
      case JobSiteCategory.healthcare:
        return Color(0xFFF44336); // Red
      case JobSiteCategory.education:
        return Color(0xFFFF9800); // Orange
      case JobSiteCategory.remote:
        return Color(0xFF9C27B0); // Purple
      case JobSiteCategory.freelance:
        return Color(0xFF00BCD4); // Cyan
      case JobSiteCategory.entryLevel:
        return Color(0xFF009688); // Teal
      case JobSiteCategory.executive:
        return Color(0xFF3F51B5); // Indigo
    }
  }
}

class JobSite {
  String? id;
  String name;
  String url;
  String description;
  JobSiteCategory category;
  String? logoBase64;
  String? logoUrl; // New field for logo URL (optional)
  List<String> features;
  bool isActive;
  bool isDeleted;
  int visitCount;
  int clickCount;
  DateTime createdAt;
  DateTime updatedAt;

  JobSite({
    this.id,
    required this.name,
    required this.url,
    required this.description,
    required this.category,
    this.logoBase64,
    this.logoUrl,
    this.features = const [],
    this.isActive = true,
    this.isDeleted = false,
    this.visitCount = 0,
    this.clickCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'url': url,
      'description': description,
      'category': category.index,
      'categoryName': category.displayName,
      'logoBase64': logoBase64 ?? '',
      'logoUrl': logoUrl ?? '',
      'features': features,
      'isActive': isActive,
      'isDeleted': isDeleted,
      'visitCount': visitCount,
      'clickCount': clickCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory JobSite.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    JobSiteCategory cat = JobSiteCategory.general;
    if (data['category'] != null) {
      cat = JobSiteCategory.values[data['category'] as int];
    }

    // Handle null timestamps safely
    DateTime parseCreatedAt() {
      if (data['createdAt'] == null) return DateTime.now();
      if (data['createdAt'] is Timestamp) {
        return (data['createdAt'] as Timestamp).toDate();
      }
      return DateTime.now();
    }

    DateTime parseUpdatedAt() {
      if (data['updatedAt'] == null) return DateTime.now();
      if (data['updatedAt'] is Timestamp) {
        return (data['updatedAt'] as Timestamp).toDate();
      }
      return DateTime.now();
    }

    return JobSite(
      id: doc.id,
      name: data['name'] ?? '',
      url: data['url'] ?? '',
      description: data['description'] ?? '',
      category: cat,
      logoBase64: data['logoBase64'],
      logoUrl: data['logoUrl'], // Make sure to read this field
      features: List<String>.from(data['features'] ?? []),
      isActive: data['isActive'] ?? true,
      isDeleted: data['isDeleted'] ?? false,
      visitCount: data['visitCount'] ?? 0,
      clickCount: data['clickCount'] ?? 0,
      createdAt: parseCreatedAt(),
      updatedAt: parseUpdatedAt(),
    );
  }

  String get domain {
    try {
      final uri = Uri.parse(url);
      return uri.host.replaceAll('www.', '');
    } catch (e) {
      print('Error parsing URL: $e');
      return url;
    }
  }
}

// Predefined job sites with logo URLs
class JobSitesData {
  static List<JobSite> getDefaultSites() {
    final now = DateTime.now();
    return [
      JobSite(
        name: 'Glassdoor',
        url: 'https://www.glassdoor.com',
        description: 'Find jobs with company reviews, salaries, and interview insights',
        category: JobSiteCategory.general,
        logoUrl: 'assets/images/glassdoor.png',
        features: ['Company Reviews', 'Salary Calculator', 'Interview Questions'],
        createdAt: now,
        updatedAt: now,
      ), 
      JobSite(
        name: 'ZipRecruiter',
        url: 'https://www.ziprecruiter.com',
        description: 'Smart job matching technology that connects you with top employers',
        category: JobSiteCategory.general,
        logoUrl: 'assets/images/ziprecruiter.png',
        features: ['Job Alerts', 'One-Click Apply', 'Employer Matches'],
        createdAt: now,
        updatedAt: now,
      ),
      JobSite(
        name: 'Monster',
        url: 'https://www.monster.com',
        description: 'Find jobs, create resumes, and access career resources',
        category: JobSiteCategory.general,
        logoUrl: 'assets/images/monster.png',
        features: ['Resume Upload', 'Career Advice', 'Job Search'],
        createdAt: now,
        updatedAt: now,
      ),
      JobSite(
        name: 'Indeed',
        url: 'https://www.indeed.com',
        description: 'World\'s #1 job site with millions of jobs',
        category: JobSiteCategory.general,
        logoUrl: 'assets/images/indeed.png',
        features: ['Job Search', 'Company Reviews', 'Salary Search'],
        createdAt: now,
        updatedAt: now,
      ),
      JobSite(
        name: 'LinkedIn',
        url: 'https://www.linkedin.com/jobs',
        description: 'Professional network with job listings and networking',
        category: JobSiteCategory.general,
        logoUrl: 'assets/images/linkedin.jpeg',
        features: ['Network', 'Easy Apply', 'Job Alerts'],
        createdAt: now,
        updatedAt: now,
      ),
      JobSite(
        name: 'Dice',
        url: 'https://www.dice.com',
        description: 'Tech jobs and IT career opportunities',
        category: JobSiteCategory.tech,
        logoUrl: 'assets/images/dice.jpeg',
        features: ['Tech Focus', 'Skill Matching', 'Tech News'],
        createdAt: now,
        updatedAt: now,
      ),
      JobSite(
        name: 'Upwork',
        url: 'https://www.upwork.com',
        description: 'Freelance platform for remote work opportunities',
        category: JobSiteCategory.freelance,
        logoUrl: 'assets/images/upwork.png',
        features: ['Freelance', 'Remote', 'Project-Based'],
        createdAt: now,
        updatedAt: now,
      ),
      JobSite(
        name: 'SimplyHired',
        url: 'https://www.simplyhired.com',
        description: 'Job search engine with salary estimates',
        category: JobSiteCategory.general,
        logoUrl: 'assets/images/simplyHired.jpeg',
        features: ['Salary Estimates', 'Company Info', 'Job Alerts'],
        createdAt: now,
        updatedAt: now,
      ),
    ];
  }
}