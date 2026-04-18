// lib/screens/user_app/entrepreneurship/my_business/my_business_screen.dart
import 'dart:convert';
import 'package:bangla_hub/screens/user_app/entrepreneurship/business_partner_request/partner_request_details_screen.dart';
import 'package:bangla_hub/screens/user_app/entrepreneurship/job_posting/job_details_screen.dart';
import 'package:bangla_hub/screens/user_app/entrepreneurship/my_business/edit_screens/dit_business_promotion_dialog.dart';
import 'package:bangla_hub/screens/user_app/entrepreneurship/my_business/edit_screens/edit_business_partner_dialog.dart';
import 'package:bangla_hub/screens/user_app/entrepreneurship/my_business/edit_screens/edit_job_posting_dialog.dart';
import 'package:bangla_hub/screens/user_app/entrepreneurship/networing_partner/premium_partner_details_screen.dart';
import 'package:bangla_hub/screens/user_app/entrepreneurship/small_business_promotion/business_promotion_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:bangla_hub/models/entrepreneurship_models.dart';
import 'package:bangla_hub/providers/auth_provider.dart';
import 'package:bangla_hub/providers/entrepreneurship_provider.dart';

class MyBusinessScreen extends StatefulWidget {
  final VoidCallback? onBack;
  
  const MyBusinessScreen({Key? key, this.onBack}) : super(key: key);

  @override
  State<MyBusinessScreen> createState() => _MyBusinessScreenState();
}

class _MyBusinessScreenState extends State<MyBusinessScreen> with TickerProviderStateMixin {
  late final TabController _tabController;
  
  final Color _primaryGreen = const Color(0xFF006A4E);
  final Color _primaryRed = const Color(0xFFF42A41);
  final Color _goldAccent = const Color(0xFFFFD700);
  final Color _darkGreen = const Color(0xFF004D38);
  final Color _lightGreen = const Color(0xFFE8F5E9);
  final Color _coralRed = const Color(0xFFFF6B6B);
  final Color _emeraldGreen = const Color(0xFF2ECC71);
  final Color _sapphireBlue = const Color(0xFF3498DB);
  final Color _amethystPurple = const Color(0xFF9B59B6);
  final Color _textPrimary = const Color(0xFF1A1A2E);
  final Color _textSecondary = const Color(0xFF4A4A4A);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserBusinessData();
    });
  }

  Future<void> _loadUserBusinessData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?.id;
    
    if (userId != null) {
      final entrepreneurshipProvider = Provider.of<EntrepreneurshipProvider>(context, listen: false);
      
      await Future.wait([
        entrepreneurshipProvider.loadBusinessPartners(),
        entrepreneurshipProvider.loadJobPostings(),
        entrepreneurshipProvider.loadBusinessPromotions(),
        entrepreneurshipProvider.loadPartnerRequests(),
      ]);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width >= 600;
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: Colors.white,
            size: isTablet ? 28 : 24,
          ),
          onPressed: () {
            if (widget.onBack != null) {
              widget.onBack!();
            }
          },
        ),
        title: Text(
          'My Business',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize: isTablet ? 24 : 20,
            color: Colors.white,
          ),
        ),
        backgroundColor: _primaryGreen,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: _goldAccent,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'Approved'),
            Tab(text: 'Pending'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _ApprovedBusinessList(),
          _PendingBusinessList(),
        ],
      ),
    );
  }
}

// Helper function to decode Base64 image
Widget _buildImageFromBase64(String? base64String, {double size = 70}) {
  if (base64String == null || base64String.isEmpty) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(Icons.image_outlined, color: Colors.grey[400], size: size * 0.4),
    );
  }

  try {
    String cleaned = base64String;
    if (cleaned.contains('base64,')) {
      cleaned = cleaned.split('base64,').last;
    }
    cleaned = cleaned.replaceAll(RegExp(r'\s'), '');
    while (cleaned.length % 4 != 0) cleaned += '=';
    
    final bytes = base64Decode(cleaned);
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.memory(
        bytes,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.broken_image, color: Colors.grey[400], size: size * 0.4),
          );
        },
      ),
    );
  } catch (e) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(Icons.broken_image, color: Colors.grey[400], size: size * 0.4),
    );
  }
}

// ====================== APPROVED BUSINESS LIST ======================
class _ApprovedBusinessList extends StatelessWidget {
  const _ApprovedBusinessList();

  Future<void> _showDeleteConfirmationDialog(BuildContext context, MyBusinessItem item) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete ${_getTypeName(item.type)}',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: const Color(0xFFF42A41)),
        ),
        content: Text(
          'Are you sure you want to delete "${item.title}"? This action cannot be undone.',
          style: GoogleFonts.inter(),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: const TextStyle(color: Color(0xFFF42A41), fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    
    if (shouldDelete == true) {
      final entrepreneurshipProvider = Provider.of<EntrepreneurshipProvider>(context, listen: false);
      bool success = false;
      
      switch (item.type) {
        case MyBusinessType.networkingPartner:
          success = await entrepreneurshipProvider.deleteBusinessPartner(item.id);
          break;
        case MyBusinessType.jobPosting:
          success = await entrepreneurshipProvider.deleteJobPosting(item.id);
          break;
        case MyBusinessType.businessPromotion:
          success = await entrepreneurshipProvider.deleteBusinessPromotion(item.id);
          break;
        case MyBusinessType.partnerRequest:
          success = await entrepreneurshipProvider.deletePartnerRequest(item.id);
          break;
      }
      
      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_getTypeName(item.type)} deleted successfully'),
            backgroundColor: const Color(0xFF006A4E),
            behavior: SnackBarBehavior.floating,
          ),
        );
        // Refresh the list
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final userId = authProvider.user?.id;
        if (userId != null) {
          await Future.wait([
            entrepreneurshipProvider.loadBusinessPartners(),
            entrepreneurshipProvider.loadJobPostings(),
            entrepreneurshipProvider.loadBusinessPromotions(),
            entrepreneurshipProvider.loadPartnerRequests(),
          ]);
        }
      }
    }
  }

  String _getTypeName(MyBusinessType type) {
    switch (type) {
      case MyBusinessType.networkingPartner:
        return 'Business Partner';
      case MyBusinessType.jobPosting:
        return 'Job Posting';
      case MyBusinessType.businessPromotion:
        return 'Business Promotion';
      case MyBusinessType.partnerRequest:
        return 'Partner Request';
    }
  }

  @override
  Widget build(BuildContext context) {
    final entrepreneurshipProvider = Provider.of<EntrepreneurshipProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final userId = authProvider.user?.id;
    
    final approvedBusinessPartners = entrepreneurshipProvider.businessPartners
        .where((item) => item.createdBy == userId && item.isVerified && !item.isDeleted)
        .toList();
    
    final approvedJobPostings = entrepreneurshipProvider.jobPostings
        .where((item) => item.postedBy == userId && item.isVerified && !item.isDeleted)
        .toList();
    
    final approvedBusinessPromotions = entrepreneurshipProvider.businessPromotions
        .where((item) => item.createdBy == userId && item.isVerified && !item.isDeleted)
        .toList();
    
    final approvedPartnerRequests = entrepreneurshipProvider.partnerRequests
        .where((item) => item.createdBy == userId && item.isVerified && !item.isDeleted)
        .toList();
    
    final allApprovedItems = <MyBusinessItem>[
      ...approvedBusinessPartners.map((item) => MyBusinessItem(
        id: item.id!,
        title: item.businessName,
        subtitle: '${item.businessType.displayName} • ${item.city}, ${item.state}',
        type: MyBusinessType.networkingPartner,
        status: 'approved',
        imageUrl: item.logoImageBase64,
        rawItem: item,
      )),
      ...approvedJobPostings.map((item) => MyBusinessItem(
        id: item.id!,
        title: item.jobTitle,
        subtitle: '${item.companyName} • ${item.location}',
        type: MyBusinessType.jobPosting,
        status: 'approved',
        imageUrl: item.companyLogoBase64,
        rawItem: item,
      )),
      ...approvedBusinessPromotions.map((item) => MyBusinessItem(
        id: item.id!,
        title: item.businessName,
        subtitle: '${item.productsServices.length} products • ${item.city}, ${item.state}',
        type: MyBusinessType.businessPromotion,
        status: 'approved',
        imageUrl: item.logoImageBase64,
        rawItem: item,
      )),
      ...approvedPartnerRequests.map((item) => MyBusinessItem(
        id: item.id!,
        title: item.title,
        subtitle: '${item.partnerType.displayName} • Budget: ${item.formattedBudget}',
        type: MyBusinessType.partnerRequest,
        status: 'approved',
        imageUrl: null,
        rawItem: item,
      )),
    ];
    
    if (allApprovedItems.isEmpty) {
      return _buildEmptyState(
        context,
        icon: Icons.business_center_rounded,
        title: 'No Approved Business',
        message: 'Your approved business listings will appear here',
      );
    }
    
    return RefreshIndicator(
      onRefresh: () async {
        final entrepreneurshipProvider = Provider.of<EntrepreneurshipProvider>(context, listen: false);
        await Future.wait([
          entrepreneurshipProvider.loadBusinessPartners(),
          entrepreneurshipProvider.loadJobPostings(),
          entrepreneurshipProvider.loadBusinessPromotions(),
          entrepreneurshipProvider.loadPartnerRequests(),
        ]);
      },
      child: ListView.builder(
        padding: EdgeInsets.all(12),
        itemCount: allApprovedItems.length,
        itemBuilder: (context, index) {
          return _buildBusinessCard(
            context, 
            allApprovedItems[index],
            onEdit: () => _showEditDialog(context, allApprovedItems[index]),
            onDelete: () => _showDeleteConfirmationDialog(context, allApprovedItems[index]),
          );
        },
      ),
    );
  }
}

// ====================== PENDING BUSINESS LIST ======================
class _PendingBusinessList extends StatelessWidget {
  const _PendingBusinessList();

  Future<void> _showDeleteConfirmationDialog(BuildContext context, MyBusinessItem item) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete ${_getTypeName(item.type)}',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: const Color(0xFFF42A41)),
        ),
        content: Text(
          'Are you sure you want to delete "${item.title}"? This action cannot be undone.',
          style: GoogleFonts.inter(),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: const TextStyle(color: Color(0xFFF42A41), fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    
    if (shouldDelete == true) {
      final entrepreneurshipProvider = Provider.of<EntrepreneurshipProvider>(context, listen: false);
      bool success = false;
      
      switch (item.type) {
        case MyBusinessType.networkingPartner:
          success = await entrepreneurshipProvider.deleteBusinessPartner(item.id);
          break;
        case MyBusinessType.jobPosting:
          success = await entrepreneurshipProvider.deleteJobPosting(item.id);
          break;
        case MyBusinessType.businessPromotion:
          success = await entrepreneurshipProvider.deleteBusinessPromotion(item.id);
          break;
        case MyBusinessType.partnerRequest:
          success = await entrepreneurshipProvider.deletePartnerRequest(item.id);
          break;
      }
      
      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_getTypeName(item.type)} deleted successfully'),
            backgroundColor: const Color(0xFF006A4E),
            behavior: SnackBarBehavior.floating,
          ),
        );
        // Refresh the list
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final userId = authProvider.user?.id;
        if (userId != null) {
          await Future.wait([
            entrepreneurshipProvider.loadBusinessPartners(),
            entrepreneurshipProvider.loadJobPostings(),
            entrepreneurshipProvider.loadBusinessPromotions(),
            entrepreneurshipProvider.loadPartnerRequests(),
          ]);
        }
      }
    }
  }

  String _getTypeName(MyBusinessType type) {
    switch (type) {
      case MyBusinessType.networkingPartner:
        return 'Business Partner';
      case MyBusinessType.jobPosting:
        return 'Job Posting';
      case MyBusinessType.businessPromotion:
        return 'Business Promotion';
      case MyBusinessType.partnerRequest:
        return 'Partner Request';
    }
  }

  @override
  Widget build(BuildContext context) {
    final entrepreneurshipProvider = Provider.of<EntrepreneurshipProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final userId = authProvider.user?.id;
    
    final pendingBusinessPartners = entrepreneurshipProvider.businessPartners
        .where((item) => item.createdBy == userId && !item.isVerified && !item.isDeleted)
        .toList();
    
    final pendingJobPostings = entrepreneurshipProvider.jobPostings
        .where((item) => item.postedBy == userId && !item.isVerified && !item.isDeleted)
        .toList();
    
    final pendingBusinessPromotions = entrepreneurshipProvider.businessPromotions
        .where((item) => item.createdBy == userId && !item.isVerified && !item.isDeleted)
        .toList();
    
    final pendingPartnerRequests = entrepreneurshipProvider.partnerRequests
        .where((item) => item.createdBy == userId && !item.isVerified && !item.isDeleted)
        .toList();
    
    final allPendingItems = <MyBusinessItem>[
      ...pendingBusinessPartners.map((item) => MyBusinessItem(
        id: item.id!,
        title: item.businessName,
        subtitle: '${item.businessType.displayName} • ${item.city}, ${item.state}',
        type: MyBusinessType.networkingPartner,
        status: 'pending',
        imageUrl: item.logoImageBase64,
        rawItem: item,
      )),
      ...pendingJobPostings.map((item) => MyBusinessItem(
        id: item.id!,
        title: item.jobTitle,
        subtitle: '${item.companyName} • ${item.location}',
        type: MyBusinessType.jobPosting,
        status: 'pending',
        imageUrl: item.companyLogoBase64,
        rawItem: item,
      )),
      ...pendingBusinessPromotions.map((item) => MyBusinessItem(
        id: item.id!,
        title: item.businessName,
        subtitle: '${item.productsServices.length} products • ${item.city}, ${item.state}',
        type: MyBusinessType.businessPromotion,
        status: 'pending',
        imageUrl: item.logoImageBase64,
        rawItem: item,
      )),
      ...pendingPartnerRequests.map((item) => MyBusinessItem(
        id: item.id!,
        title: item.title,
        subtitle: '${item.partnerType.displayName} • Budget: ${item.formattedBudget}',
        type: MyBusinessType.partnerRequest,
        status: 'pending',
        imageUrl: null,
        rawItem: item,
      )),
    ];
    
    if (allPendingItems.isEmpty) {
      return _buildEmptyState(
        context,
        icon: Icons.hourglass_empty_rounded,
        title: 'No Pending Business',
        message: 'Your submitted business listings waiting for approval will appear here',
      );
    }
    
    return RefreshIndicator(
      onRefresh: () async {
        final entrepreneurshipProvider = Provider.of<EntrepreneurshipProvider>(context, listen: false);
        await Future.wait([
          entrepreneurshipProvider.loadBusinessPartners(),
          entrepreneurshipProvider.loadJobPostings(),
          entrepreneurshipProvider.loadBusinessPromotions(),
          entrepreneurshipProvider.loadPartnerRequests(),
        ]);
      },
      child: ListView.builder(
        padding: EdgeInsets.all(12),
        itemCount: allPendingItems.length,
        itemBuilder: (context, index) {
          return _buildBusinessCard(
            context, 
            allPendingItems[index],
            onEdit: () => _showEditDialog(context, allPendingItems[index]),
            onDelete: () => _showDeleteConfirmationDialog(context, allPendingItems[index]),
          );
        },
      ),
    );
  }
}

// ====================== EDIT DIALOGS ======================

// Add this inside _MyBusinessScreenState class
Future<void> _refreshData(BuildContext context) async {
  final authProvider = Provider.of<AuthProvider>(context, listen: false);
  final userId = authProvider.user?.id;
  if (userId != null) {
    final entrepreneurshipProvider = Provider.of<EntrepreneurshipProvider>(context, listen: false);
    await Future.wait([
      entrepreneurshipProvider.loadBusinessPartners(),
      entrepreneurshipProvider.loadJobPostings(),
      entrepreneurshipProvider.loadBusinessPromotions(),
      entrepreneurshipProvider.loadPartnerRequests(),
    ]);
  }
}

void _showEditDialog(BuildContext context, MyBusinessItem item) {
  switch (item.type) {
    case MyBusinessType.networkingPartner:
      showDialog(
        context: context,
        builder: (context) => EditBusinessPartnerDialog(
          partner: item.rawItem as NetworkingBusinessPartner,
          onUpdate: () => _refreshData(context),
        ),
      );
      break;
    case MyBusinessType.jobPosting:
      showDialog(
        context: context,
        builder: (context) => EditJobPostingDialog(
          job: item.rawItem as JobPosting,
          onUpdate: () => _refreshData(context),
        ),
      );
      break;
    case MyBusinessType.businessPromotion:
      showDialog(
        context: context,
        builder: (context) => EditBusinessPromotionDialog(
          promotion: item.rawItem as SmallBusinessPromotion,
          onUpdate: () => _refreshData(context),
        ),
      );
      break;
    case MyBusinessType.partnerRequest:
      // Show edit dialog for partner request (implement similarly)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Edit for Partner Request coming soon'), duration: Duration(seconds: 2)),
      );
      break;
  }
}

void _showEditBusinessPartnerDialog(BuildContext context, MyBusinessItem item) {
  final partner = item.rawItem as NetworkingBusinessPartner;
  
  // Show a simple edit dialog or navigate to edit screen
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Edit Business Partner', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
      content: Text('Edit functionality for ${partner.businessName} will be available soon.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Close'),
        ),
      ],
    ),
  );
}

void _showEditJobPostingDialog(BuildContext context, MyBusinessItem item) {
  final job = item.rawItem as JobPosting;
  
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Edit Job Posting', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
      content: Text('Edit functionality for ${job.jobTitle} will be available soon.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Close'),
        ),
      ],
    ),
  );
}

void _showEditBusinessPromotionDialog(BuildContext context, MyBusinessItem item) {
  final promotion = item.rawItem as SmallBusinessPromotion;
  
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Edit Business Promotion', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
      content: Text('Edit functionality for ${promotion.businessName} will be available soon.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Close'),
        ),
      ],
    ),
  );
}

void _showEditPartnerRequestDialog(BuildContext context, MyBusinessItem item) {
  final request = item.rawItem as BusinessPartnerRequest;
  
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Edit Partner Request', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
      content: Text('Edit functionality for ${request.title} will be available soon.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Close'),
        ),
      ],
    ),
  );
}

// ====================== BUSINESS CARD WIDGET ======================
Widget _buildBusinessCard(BuildContext context, MyBusinessItem item, {VoidCallback? onEdit, VoidCallback? onDelete}) {
  final isTablet = MediaQuery.of(context).size.width >= 600;
  
  Color getTypeColor() {
    switch (item.type) {
      case MyBusinessType.networkingPartner:
        return const Color(0xFF3498DB);
      case MyBusinessType.jobPosting:
        return const Color(0xFF2ECC71);
      case MyBusinessType.businessPromotion:
        return const Color(0xFFE74C3C);
      case MyBusinessType.partnerRequest:
        return const Color(0xFF9B59B6);
    }
  }
  
  IconData getTypeIcon() {
    switch (item.type) {
      case MyBusinessType.networkingPartner:
        return Icons.business_rounded;
      case MyBusinessType.jobPosting:
        return Icons.work_rounded;
      case MyBusinessType.businessPromotion:
        return Icons.local_offer_rounded;
      case MyBusinessType.partnerRequest:
        return Icons.people_rounded;
    }
  }
  
  String getTypeLabel() {
    switch (item.type) {
      case MyBusinessType.networkingPartner:
        return 'Networking Partner';
      case MyBusinessType.jobPosting:
        return 'Job Posting';
      case MyBusinessType.businessPromotion:
        return 'Business Promotion';
      case MyBusinessType.partnerRequest:
        return 'Partner Request';
    }
  }
  
  return Container(
    margin: EdgeInsets.symmetric(
      horizontal: isTablet ? 16 : 12,
      vertical: 8,
    ),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 15,
          offset: const Offset(0, 4),
          spreadRadius: -2,
        ),
      ],
    ),
    child: Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: () => _navigateToDetails(context, item),
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Type Badge with Edit/Delete buttons
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 12 : 10,
                vertical: isTablet ? 6 : 4,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [getTypeColor(), getTypeColor().withOpacity(0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(getTypeIcon(), color: Colors.white, size: isTablet ? 16 : 14),
                  const SizedBox(width: 6),
                  Text(
                    getTypeLabel(),
                    style: GoogleFonts.poppins(
                      fontSize: isTablet ? 12 : 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  // Edit Button
                  if (onEdit != null)
                    GestureDetector(
                      onTap: onEdit,
                      child: Container(
                        padding: EdgeInsets.all(4),
                        margin: EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.edit_rounded, color: Colors.white, size: isTablet ? 14 : 12),
                      ),
                    ),
                  // Delete Button
                  if (onDelete != null)
                    GestureDetector(
                      onTap: onDelete,
                      child: Container(
                        padding: EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.delete_rounded, color: Colors.white, size: isTablet ? 14 : 12),
                      ),
                    ),
                ],
              ),
            ),
            
            Padding(
              padding: EdgeInsets.all(isTablet ? 16 : 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image (Logo/Banner)
                  _buildImageFromBase64(item.imageUrl, size: isTablet ? 80 : 70),
                  
                  const SizedBox(width: 12),
                  
                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: GoogleFonts.poppins(
                            fontSize: isTablet ? 16 : 14,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1A1A2E),
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        
                        const SizedBox(height: 4),
                        
                        Text(
                          item.subtitle,
                          style: GoogleFonts.inter(
                            fontSize: isTablet ? 12 : 11,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF4A4A4A),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        
                        const SizedBox(height: 8),
                        
                        // Status Badge
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: item.status == 'approved' 
                                ? const Color(0xFF2ECC71).withOpacity(0.1)
                                : const Color(0xFFFF9800).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: item.status == 'approved' 
                                  ? const Color(0xFF2ECC71).withOpacity(0.3)
                                  : const Color(0xFFFF9800).withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            item.status == 'approved' ? 'Approved' : 'Pending',
                            style: GoogleFonts.inter(
                              fontSize: isTablet ? 10 : 9,
                              fontWeight: FontWeight.w600,
                              color: item.status == 'approved' 
                                  ? const Color(0xFF2ECC71)
                                  : const Color(0xFFFF9800),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Arrow Icon
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: isTablet ? 16 : 14,
                    color: Colors.grey[400],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

// ====================== EMPTY STATE ======================
Widget _buildEmptyState(BuildContext context, {
  required IconData icon,
  required String title,
  required String message,
}) {
  final isTablet = MediaQuery.of(context).size.width >= 600;
  
  return Center(
    child: Padding(
      padding: EdgeInsets.all(isTablet ? 32 : 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: isTablet ? 80 : 60, color: Colors.grey[400]),
          const SizedBox(height: 20),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: isTablet ? 20 : 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            message,
            style: GoogleFonts.inter(
              fontSize: isTablet ? 14 : 12,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}

// ====================== NAVIGATION HELPER ======================
void _navigateToDetails(BuildContext context, MyBusinessItem item) {
  switch (item.type) {
    case MyBusinessType.networkingPartner:
      final partner = item.rawItem as NetworkingBusinessPartner;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PremiumPartnerDetailsScreen(
            partner: partner,
            scrollController: ScrollController(),
            onLaunchPhone: (phone) {},
            onLaunchEmail: (email) {},
            onLaunchUrl: (url) {},
            primaryGreen: const Color(0xFF006A4E),
            secondaryGold: const Color(0xFFFFD700),
            accentRed: const Color(0xFFF42A41),
            lightGreen: const Color(0xFFE8F5E9),
          ),
        ),
      );
      break;
      
    case MyBusinessType.jobPosting:
      final job = item.rawItem as JobPosting;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => JobDetailsScreen(
            job: job,
            scrollController: ScrollController(),
            onLaunchPhone: (phone) {},
            onLaunchEmail: (email) {},
            onLaunchUrl: (url) {},
            primaryRed: const Color(0xFFE74C3C),
            goldAccent: const Color(0xFFFFD700),
            purpleAccent: const Color(0xFF9B59B6),
            tealAccent: const Color(0xFF00897B),
          ),
        ),
      );
      break;
      
    case MyBusinessType.businessPromotion:
      final promotion = item.rawItem as SmallBusinessPromotion;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BusinessPromotionDetailsScreen(
            promotion: promotion,
            scrollController: ScrollController(),
            onLaunchPhone: (phone) {},
            onLaunchEmail: (email) {},
            onLaunchUrl: (url) {},
            primaryOrange: const Color(0xFFFF9800),
            redAccent: const Color(0xFFE74C3C),
            greenAccent: const Color(0xFF2ECC71),
            goldAccent: const Color(0xFFFFD700),
          ),
        ),
      );
      break;
      
    case MyBusinessType.partnerRequest:
      final request = item.rawItem as BusinessPartnerRequest;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PartnerRequestDetailsScreen(
            request: request,
            scrollController: ScrollController(),
            onLaunchPhone: (phone) {},
            onLaunchEmail: (email) {},
            primaryGreen: const Color(0xFF006A4E),
            secondaryGold: const Color(0xFFFFD700),
            softGreen: const Color(0xFF98D8C8),
            lightGreen: const Color(0xFFE8F5E9),
          ),
        ),
      );
      break;
  }
}

// ====================== HELPER CLASSES ======================
enum MyBusinessType {
  networkingPartner,
  jobPosting,
  businessPromotion,
  partnerRequest,
}

class MyBusinessItem {
  final String id;
  final String title;
  final String subtitle;
  final MyBusinessType type;
  final String status;
  final String? imageUrl;
  final dynamic rawItem;

  MyBusinessItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.type,
    required this.status,
    this.imageUrl,
    required this.rawItem,
  });
}