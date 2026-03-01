// lib/services/job_sites_browse_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bangla_hub/models/job_sites_browse_model.dart';

class JobSitesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'job_sites';

  // Initialize default job sites if none exist
  Future<void> initializeDefaultSites() async {
    try {
      final snapshot = await _firestore.collection(_collection).limit(1).get();
      
      if (snapshot.docs.isEmpty) {
        print('No job sites found, adding default sites...');
        final defaultSites = JobSitesData.getDefaultSites();
        
        for (var site in defaultSites) {
          await _firestore.collection(_collection).add(site.toMap());
        }
        print('Added ${defaultSites.length} default job sites');
      } else {
        print('Job sites already exist in Firestore');
        // After confirming sites exist, update them with logos if needed
        await _updateExistingSitesWithLogos();
      }
    } catch (e) {
      print('Error initializing default sites: $e');
    }
  }

  // NEW: Update existing sites with logo URLs - FIXED VERSION
  Future<void> _updateExistingSitesWithLogos() async {
    try {
      final snapshot = await _firestore.collection(_collection).get();
      final defaultSites = JobSitesData.getDefaultSites();
      int updatedCount = 0;
      
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final siteName = data['name'];
        
        // Check if logoUrl already exists
        if (data.containsKey('logoUrl') && data['logoUrl'] != null && data['logoUrl'].toString().isNotEmpty) {
          continue; // Skip if already has logoUrl
        }
        
        // Find matching default site - FIXED: Properly handle orElse
        JobSite? defaultSite;
        try {
          defaultSite = defaultSites.firstWhere(
            (site) => site.name == siteName,
          );
        } catch (e) {
          // No match found, skip this document
          print('ℹ️ No default logo found for $siteName');
          continue;
        }
        
        if (defaultSite != null && defaultSite.logoUrl != null) {
          // Update the document with logoUrl
          await doc.reference.update({
            'logoUrl': defaultSite.logoUrl,
          });
          updatedCount++;
          print('✅ Updated logo for $siteName: ${defaultSite.logoUrl}');
        }
      }
      
      if (updatedCount > 0) {
        print('✅ Updated $updatedCount sites with logo URLs');
      } else {
        print('✅ All sites already have logo URLs');
      }
    } catch (e) {
      print('❌ Error updating sites with logos: $e');
    }
  }

  // Get all job sites as stream (for real-time updates)
  Stream<List<JobSite>> getAllJobSitesStream({bool includeInactive = false}) {
    try {
      Query query = _firestore.collection(_collection);
      
      if (!includeInactive) {
        query = query.where('isDeleted', isEqualTo: false)
                     .where('isActive', isEqualTo: true);
      }
      
      query = query.orderBy('name');
      
      return query.snapshots().map((snapshot) {
        print('🔥 Firestore snapshot received: ${snapshot.docs.length} docs');
        
        return snapshot.docs
            .map((doc) => JobSite.fromFirestore(doc))
            .toList();
      });
    } catch (e) {
      print('Error getting job sites stream: $e');
      return Stream.value([]);
    }
  }

  // Get all job sites (one-time fetch)
  Future<List<JobSite>> getAllJobSites({bool includeInactive = false}) async {
    try {
      Query query = _firestore.collection(_collection);
      
      if (!includeInactive) {
        query = query.where('isDeleted', isEqualTo: false)
                     .where('isActive', isEqualTo: true);
      }
      
      query = query.orderBy('name');
      
      final snapshot = await query.get();
      print('Fetched ${snapshot.docs.length} job sites from Firestore');
      
      return snapshot.docs
          .map((doc) => JobSite.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting job sites: $e');
      return [];
    }
  }

  // Get sites by category
  Future<List<JobSite>> getSitesByCategory(JobSiteCategory category) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('category', isEqualTo: category.index)
          .where('isDeleted', isEqualTo: false)
          .where('isActive', isEqualTo: true)
          .orderBy('name')
          .get();
      
      return snapshot.docs
          .map((doc) => JobSite.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting sites by category: $e');
      return [];
    }
  }

  // Add or update job site
  Future<void> saveJobSite(JobSite site) async {
    try {
      if (site.id == null) {
        // Add new site
        await _firestore.collection(_collection).add(site.toMap());
        print('Added new job site: ${site.name}');
      } else {
        // Update existing site
        await _firestore.collection(_collection).doc(site.id).update(site.toMap());
        print('Updated job site: ${site.name}');
      }
    } catch (e) {
      print('Error saving job site: $e');
      rethrow;
    }
  }

  // Delete job site (soft delete)
  Future<void> deleteJobSite(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).update({
        'isDeleted': true,
        'isActive': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('Soft deleted job site with ID: $id');
    } catch (e) {
      print('Error deleting job site: $e');
      rethrow;
    }
  }

  // Permanently remove job site
  Future<void> permanentDeleteJobSite(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).delete();
      print('Permanently deleted job site with ID: $id');
    } catch (e) {
      print('Error permanently deleting job site: $e');
      rethrow;
    }
  }

  // Record site click
  Future<void> recordSiteClick(String siteId, String siteName) async {
    try {
      await _firestore.collection(_collection).doc(siteId).update({
        'clickCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('Recorded click for site: $siteName');
    } catch (e) {
      print('Error recording site click: $e');
    }
  }

  // Get click statistics
  Future<Map<String, dynamic>> getClickStatistics() async {
    try {
      final snapshot = await _firestore.collection(_collection).get();
      
      int totalClicks = 0;
      final siteClicks = <String, int>{};
      final categoryClicks = <String, int>{};
      
      for (var doc in snapshot.docs) {
        try {
          final site = JobSite.fromFirestore(doc);
          totalClicks += site.clickCount;
          siteClicks[site.name] = site.clickCount;
          
          final categoryName = site.category.displayName;
          categoryClicks[categoryName] = (categoryClicks[categoryName] ?? 0) + site.clickCount;
        } catch (e) {
          print('Error processing document ${doc.id}: $e');
          continue;
        }
      }
      
      return {
        'totalClicks': totalClicks,
        'siteClicks': siteClicks,
        'categoryClicks': categoryClicks,
        'totalSites': snapshot.docs.length,
      };
    } catch (e) {
      print('Error getting click statistics: $e');
      return {
        'totalClicks': 0,
        'siteClicks': {},
        'categoryClicks': {},
        'totalSites': 0,
      };
    }
  }

  // Reset all job sites to default (delete all and add defaults)
  Future<void> resetToDefault() async {
    try {
      // Delete all existing sites
      final snapshot = await _firestore.collection(_collection).get();
      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }
      
      // Add default sites
      final defaultSites = JobSitesData.getDefaultSites();
      for (var site in defaultSites) {
        await _firestore.collection(_collection).add(site.toMap());
      }
      
      print('Reset to default sites');
    } catch (e) {
      print('Error resetting to default: $e');
      rethrow;
    }
  }

  // Public method to force update logos (can be called from admin)
  Future<void> forceUpdateLogos() async {
    await _updateExistingSitesWithLogos();
  }
}