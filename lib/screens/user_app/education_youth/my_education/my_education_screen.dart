// lib/screens/user_app/education_youth/my_education/my_education_screen.dart
import 'package:bangla_hub/screens/user_app/education_youth/admissions_guidance/admissions_guidance_details_screen.dart';
import 'package:bangla_hub/screens/user_app/education_youth/bangla_classes/bangla_class_details_screen.dart';
import 'package:bangla_hub/screens/user_app/education_youth/my_education/edit_screen/edit_admissions_dialog.dart';
import 'package:bangla_hub/screens/user_app/education_youth/my_education/edit_screen/edit_bangla_class_dialog.dart';
import 'package:bangla_hub/screens/user_app/education_youth/my_education/edit_screen/edit_sports_club_dialog.dart';
import 'package:bangla_hub/screens/user_app/education_youth/my_education/edit_screen/edit_tutoring_dialog.dart';
import 'package:bangla_hub/screens/user_app/education_youth/sports_clubs/sports_club_details_screen.dart';
import 'package:bangla_hub/screens/user_app/education_youth/tutoring/tutoring_details_screen.dart';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:bangla_hub/models/education_models.dart';
import 'package:bangla_hub/providers/auth_provider.dart';
import 'package:bangla_hub/providers/education_provider.dart';

class MyEducationScreen extends StatefulWidget {
  final VoidCallback? onBack;
  
  const MyEducationScreen({Key? key, this.onBack}) : super(key: key);

  @override
  State<MyEducationScreen> createState() => _MyEducationScreenState();
}

class _MyEducationScreenState extends State<MyEducationScreen> with TickerProviderStateMixin {
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
  final Color _orangeAccent = const Color(0xFFFF9800);
  final Color _textPrimary = const Color(0xFF1A1A2E);
  final Color _textSecondary = const Color(0xFF4A4A4A);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserEducationData();
    });
  }

  Future<void> _loadUserEducationData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?.id;
    
    if (userId != null) {
      final educationProvider = Provider.of<EducationProvider>(context, listen: false);
      
      await Future.wait([
        educationProvider.loadTutoringServices(),
        educationProvider.loadAdmissionsGuidance(),
        educationProvider.loadBanglaClasses(),
        educationProvider.loadSportsClubs(),
      ]);
    }
  }

  Future<void> _refreshData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?.id;
    if (userId != null) {
      final educationProvider = Provider.of<EducationProvider>(context, listen: false);
      await Future.wait([
        educationProvider.loadTutoringServices(),
        educationProvider.loadAdmissionsGuidance(),
        educationProvider.loadBanglaClasses(),
        educationProvider.loadSportsClubs(),
      ]);
    }
  }

  Future<void> _showDeleteConfirmationDialog(BuildContext context, MyEducationItem item) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete ${_getTypeName(item.type)}',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: _primaryRed),
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
            child: Text('Delete', style: TextStyle(color: _primaryRed, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    
    if (shouldDelete == true) {
      final educationProvider = Provider.of<EducationProvider>(context, listen: false);
      bool success = false;
      
      switch (item.type) {
        case MyEducationType.tutoringService:
          success = await educationProvider.deleteTutoringService(item.id);
          break;
        case MyEducationType.admissionsGuidance:
          success = await educationProvider.deleteAdmissionsGuidance(item.id);
          break;
        case MyEducationType.banglaClass:
          success = await educationProvider.deleteBanglaClass(item.id);
          break;
        case MyEducationType.sportsClub:
          success = await educationProvider.deleteSportsClub(item.id);
          break;
      }
      
      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_getTypeName(item.type)} deleted successfully'),
            backgroundColor: _primaryGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
        await _refreshData();
      }
    }
  }

  String _getTypeName(MyEducationType type) {
    switch (type) {
      case MyEducationType.tutoringService:
        return 'Tutoring Service';
      case MyEducationType.admissionsGuidance:
        return 'Admissions Guidance';
      case MyEducationType.banglaClass:
        return 'Bangla Class';
      case MyEducationType.sportsClub:
        return 'Sports Club';
    }
  }

  void _showEditDialog(BuildContext context, MyEducationItem item) {
    switch (item.type) {
      case MyEducationType.tutoringService:
        showDialog(
          context: context,
          builder: (context) => EditTutoringDialog(
            service: item.rawItem as TutoringService,
            onUpdate: () => _refreshData(),
          ),
        );
        break;
      case MyEducationType.admissionsGuidance:
        showDialog(
          context: context,
          builder: (context) => EditAdmissionsDialog(
            guidance: item.rawItem as AdmissionsGuidance,
            onUpdate: () => _refreshData(),
          ),
        );
        break;
      case MyEducationType.banglaClass:
        showDialog(
          context: context,
          builder: (context) => EditBanglaClassDialog(
            banglaClass: item.rawItem as BanglaClass,
            onUpdate: () => _refreshData(),
          ),
        );
        break;
      case MyEducationType.sportsClub:
        showDialog(
          context: context,
          builder: (context) => EditSportsClubDialog(
            club: item.rawItem as SportsClub,
            onUpdate: () => _refreshData(),
          ),
        );
        break;
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
          'My Education',
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
          _ApprovedEducationList(
            onEdit: _showEditDialog,
            onDelete: _showDeleteConfirmationDialog,
          ),
          _PendingEducationList(
            onEdit: _showEditDialog,
            onDelete: _showDeleteConfirmationDialog,
          ),
        ],
      ),
    );
  }
}

// ====================== APPROVED EDUCATION LIST ======================
class _ApprovedEducationList extends StatelessWidget {
  final Function(BuildContext, MyEducationItem) onEdit;
  final Function(BuildContext, MyEducationItem) onDelete;

  const _ApprovedEducationList({
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final educationProvider = Provider.of<EducationProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final userId = authProvider.user?.id;
    
    final approvedTutoring = educationProvider.tutoringServices
        .where((item) => item.createdBy == userId && item.isVerified && !item.isDeleted)
        .toList();
    
    final approvedAdmissions = educationProvider.admissionsGuidance
        .where((item) => item.createdBy == userId && item.isVerified && !item.isDeleted)
        .toList();
    
    final approvedBanglaClasses = educationProvider.banglaClasses
        .where((item) => item.createdBy == userId && item.isVerified && !item.isDeleted)
        .toList();
    
    final approvedSportsClubs = educationProvider.sportsClubs
        .where((item) => item.createdBy == userId && item.isVerified && !item.isDeleted)
        .toList();
    
    final allApprovedItems = <MyEducationItem>[
      ...approvedTutoring.map((item) => MyEducationItem(
        id: item.id!,
        title: item.tutorName,
        subtitle: '${item.subjects.length} subjects • ${item.city}, ${item.state}',
        type: MyEducationType.tutoringService,
        status: 'approved',
        imageUrl: item.profileImageBase64,
        rawItem: item,
      )),
      ...approvedAdmissions.map((item) => MyEducationItem(
        id: item.id!,
        title: item.consultantName,
        subtitle: '${item.specializations.length} specializations • ${item.city}, ${item.state}',
        type: MyEducationType.admissionsGuidance,
        status: 'approved',
        imageUrl: item.profileImageBase64,
        rawItem: item,
      )),
      ...approvedBanglaClasses.map((item) => MyEducationItem(
        id: item.id!,
        title: item.instructorName,
        subtitle: '${item.classTypes.length} class types • ${item.city}, ${item.state}',
        type: MyEducationType.banglaClass,
        status: 'approved',
        imageUrl: item.profileImageBase64,
        rawItem: item,
      )),
      ...approvedSportsClubs.map((item) => MyEducationItem(
        id: item.id!,
        title: item.clubName,
        subtitle: '${item.sportType.displayName} • ${item.city}, ${item.state}',
        type: MyEducationType.sportsClub,
        status: 'approved',
        imageUrl: item.logoImageBase64,
        rawItem: item,
      )),
    ];
    
    if (allApprovedItems.isEmpty) {
      return _buildEmptyState(
        context,
        icon: Icons.school_rounded,
        title: 'No Approved Education Content',
        message: 'Your approved educational content will appear here',
      );
    }
    
    return RefreshIndicator(
      onRefresh: () async {
        final educationProvider = Provider.of<EducationProvider>(context, listen: false);
        await Future.wait([
          educationProvider.loadTutoringServices(),
          educationProvider.loadAdmissionsGuidance(),
          educationProvider.loadBanglaClasses(),
          educationProvider.loadSportsClubs(),
        ]);
      },
      child: ListView.builder(
        padding: EdgeInsets.all(12),
        itemCount: allApprovedItems.length,
        itemBuilder: (context, index) {
          return _buildEducationCard(
            context, 
            allApprovedItems[index],
            onEdit: () => onEdit(context, allApprovedItems[index]),
            onDelete: () => onDelete(context, allApprovedItems[index]),
          );
        },
      ),
    );
  }
}

// ====================== PENDING EDUCATION LIST ======================
class _PendingEducationList extends StatelessWidget {
  final Function(BuildContext, MyEducationItem) onEdit;
  final Function(BuildContext, MyEducationItem) onDelete;

  const _PendingEducationList({
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final educationProvider = Provider.of<EducationProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final userId = authProvider.user?.id;
    
    final pendingTutoring = educationProvider.tutoringServices
        .where((item) => item.createdBy == userId && !item.isVerified && !item.isDeleted)
        .toList();
    
    final pendingAdmissions = educationProvider.admissionsGuidance
        .where((item) => item.createdBy == userId && !item.isVerified && !item.isDeleted)
        .toList();
    
    final pendingBanglaClasses = educationProvider.banglaClasses
        .where((item) => item.createdBy == userId && !item.isVerified && !item.isDeleted)
        .toList();
    
    final pendingSportsClubs = educationProvider.sportsClubs
        .where((item) => item.createdBy == userId && !item.isVerified && !item.isDeleted)
        .toList();
    
    final allPendingItems = <MyEducationItem>[
      ...pendingTutoring.map((item) => MyEducationItem(
        id: item.id!,
        title: item.tutorName,
        subtitle: '${item.subjects.length} subjects • ${item.city}, ${item.state}',
        type: MyEducationType.tutoringService,
        status: 'pending',
        imageUrl: item.profileImageBase64,
        rawItem: item,
      )),
      ...pendingAdmissions.map((item) => MyEducationItem(
        id: item.id!,
        title: item.consultantName,
        subtitle: '${item.specializations.length} specializations • ${item.city}, ${item.state}',
        type: MyEducationType.admissionsGuidance,
        status: 'pending',
        imageUrl: item.profileImageBase64,
        rawItem: item,
      )),
      ...pendingBanglaClasses.map((item) => MyEducationItem(
        id: item.id!,
        title: item.instructorName,
        subtitle: '${item.classTypes.length} class types • ${item.city}, ${item.state}',
        type: MyEducationType.banglaClass,
        status: 'pending',
        imageUrl: item.profileImageBase64,
        rawItem: item,
      )),
      ...pendingSportsClubs.map((item) => MyEducationItem(
        id: item.id!,
        title: item.clubName,
        subtitle: '${item.sportType.displayName} • ${item.city}, ${item.state}',
        type: MyEducationType.sportsClub,
        status: 'pending',
        imageUrl: item.logoImageBase64,
        rawItem: item,
      )),
    ];
    
    if (allPendingItems.isEmpty) {
      return _buildEmptyState(
        context,
        icon: Icons.hourglass_empty_rounded,
        title: 'No Pending Education Content',
        message: 'Your submitted educational content waiting for approval will appear here',
      );
    }
    
    return RefreshIndicator(
      onRefresh: () async {
        final educationProvider = Provider.of<EducationProvider>(context, listen: false);
        await Future.wait([
          educationProvider.loadTutoringServices(),
          educationProvider.loadAdmissionsGuidance(),
          educationProvider.loadBanglaClasses(),
          educationProvider.loadSportsClubs(),
        ]);
      },
      child: ListView.builder(
        padding: EdgeInsets.all(12),
        itemCount: allPendingItems.length,
        itemBuilder: (context, index) {
          return _buildEducationCard(
            context, 
            allPendingItems[index],
            onEdit: () => onEdit(context, allPendingItems[index]),
            onDelete: () => onDelete(context, allPendingItems[index]),
          );
        },
      ),
    );
  }
}

// ====================== EDUCATION CARD WIDGET ======================
Widget _buildEducationCard(BuildContext context, MyEducationItem item, {VoidCallback? onEdit, VoidCallback? onDelete}) {
  final isTablet = MediaQuery.of(context).size.width >= 600;
  
  Color getTypeColor() {
    switch (item.type) {
      case MyEducationType.tutoringService:
        return const Color(0xFF2196F3);
      case MyEducationType.admissionsGuidance:
        return const Color(0xFF4CAF50);
      case MyEducationType.banglaClass:
        return const Color(0xFFFF9800);
      case MyEducationType.sportsClub:
        return const Color(0xFFF44336);
    }
  }
  
  IconData getTypeIcon() {
    switch (item.type) {
      case MyEducationType.tutoringService:
        return Icons.school_rounded;
      case MyEducationType.admissionsGuidance:
        return Icons.business_center_rounded;
      case MyEducationType.banglaClass:
        return Icons.language_rounded;
      case MyEducationType.sportsClub:
        return Icons.sports_rounded;
    }
  }
  
  String getTypeLabel() {
    switch (item.type) {
      case MyEducationType.tutoringService:
        return 'Tutoring Service';
      case MyEducationType.admissionsGuidance:
        return 'Admissions Guidance';
      case MyEducationType.banglaClass:
        return 'Bangla Class';
      case MyEducationType.sportsClub:
        return 'Sports Club';
    }
  }
  
  return Container(
    margin: EdgeInsets.symmetric(horizontal: isTablet ? 16 : 12, vertical: 8),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(20),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 15, offset: const Offset(0, 4), spreadRadius: -2)],
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
              padding: EdgeInsets.symmetric(horizontal: isTablet ? 12 : 10, vertical: isTablet ? 6 : 4),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [getTypeColor(), getTypeColor().withOpacity(0.7)]),
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), bottomRight: Radius.circular(12)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(getTypeIcon(), color: Colors.white, size: isTablet ? 16 : 14),
                  const SizedBox(width: 6),
                  Text(getTypeLabel(), style: GoogleFonts.poppins(fontSize: isTablet ? 12 : 10, fontWeight: FontWeight.w600, color: Colors.white)),
                  const Spacer(),
                  if (onEdit != null)
                    GestureDetector(
                      onTap: onEdit,
                      child: Container(padding: EdgeInsets.all(4), margin: EdgeInsets.only(right: 8), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(8)), child: Icon(Icons.edit_rounded, color: Colors.white, size: isTablet ? 14 : 12)),
                    ),
                  if (onDelete != null)
                    GestureDetector(
                      onTap: onDelete,
                      child: Container(padding: EdgeInsets.all(4), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(8)), child: Icon(Icons.delete_rounded, color: Colors.white, size: isTablet ? 14 : 12)),
                    ),
                ],
              ),
            ),
            
            Padding(
              padding: EdgeInsets.all(isTablet ? 16 : 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image
                  Container(
                    width: isTablet ? 80 : 70,
                    height: isTablet ? 80 : 70,
                    decoration: BoxDecoration(
                      color: getTypeColor().withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: getTypeColor().withOpacity(0.2)),
                    ),
                    child: Center(child: Icon(getTypeIcon(), size: isTablet ? 32 : 28, color: getTypeColor())),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.title, style: GoogleFonts.poppins(fontSize: isTablet ? 16 : 14, fontWeight: FontWeight.w700, color: const Color(0xFF1A1A2E), height: 1.2), maxLines: 2, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Text(item.subtitle, style: GoogleFonts.inter(fontSize: isTablet ? 12 : 11, fontWeight: FontWeight.w500, color: const Color(0xFF4A4A4A)), maxLines: 2, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 8),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: item.status == 'approved' ? const Color(0xFF2ECC71).withOpacity(0.1) : const Color(0xFFFF9800).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: item.status == 'approved' ? const Color(0xFF2ECC71).withOpacity(0.3) : const Color(0xFFFF9800).withOpacity(0.3)),
                          ),
                          child: Text(item.status == 'approved' ? 'Approved' : 'Pending', style: GoogleFonts.inter(fontSize: isTablet ? 10 : 9, fontWeight: FontWeight.w600, color: item.status == 'approved' ? const Color(0xFF2ECC71) : const Color(0xFFFF9800))),
                        ),
                      ],
                    ),
                  ),
                  
                  Icon(Icons.arrow_forward_ios_rounded, size: isTablet ? 16 : 14, color: Colors.grey[400]),
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
Widget _buildEmptyState(BuildContext context, {required IconData icon, required String title, required String message}) {
  final isTablet = MediaQuery.of(context).size.width >= 600;
  
  return Center(
    child: Padding(
      padding: EdgeInsets.all(isTablet ? 32 : 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: isTablet ? 80 : 60, color: Colors.grey[400]),
          const SizedBox(height: 20),
          Text(title, style: GoogleFonts.poppins(fontSize: isTablet ? 20 : 16, fontWeight: FontWeight.w600, color: Colors.grey[600])),
          const SizedBox(height: 10),
          Text(message, style: GoogleFonts.inter(fontSize: isTablet ? 14 : 12, color: Colors.grey[500]), textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}

// ====================== NAVIGATION HELPER ======================
void _navigateToDetails(BuildContext context, MyEducationItem item) {
  switch (item.type) {
    case MyEducationType.tutoringService:
      final service = item.rawItem as TutoringService;
      Navigator.push(context, MaterialPageRoute(builder: (context) => TutoringDetailsScreen(
        service: service,
        scrollController: ScrollController(),
        primaryBlue: const Color(0xFF2196F3),
        successGreen: const Color(0xFF4CAF50),
        warningOrange: const Color(0xFFFF9800),
        tealAccent: const Color(0xFF00897B),
        purpleAccent: const Color(0xFF9B59B6),
        goldAccent: const Color(0xFFFFD700),
        lightBlue: const Color(0xFFE3F2FD),
      )));
      break;
      
    case MyEducationType.admissionsGuidance:
      final guidance = item.rawItem as AdmissionsGuidance;
      Navigator.push(context, MaterialPageRoute(builder: (context) => AdmissionsGuidanceDetailsScreen(
        service: guidance,
        scrollController: ScrollController(),
        primaryGreen: const Color(0xFF4CAF50),
        successGreen: const Color(0xFF2ECC71),
        warningOrange: const Color(0xFFFF9800),
        infoBlue: const Color(0xFF2196F3),
        purpleAccent: const Color(0xFF9B59B6),
        goldAccent: const Color(0xFFFFD700),
        lightGreen: const Color(0xFFE8F5E9),
      )));
      break;
      
    case MyEducationType.banglaClass:
      final banglaClass = item.rawItem as BanglaClass;
      Navigator.push(context, MaterialPageRoute(builder: (context) => BanglaClassDetailsScreen(
        banglaClass: banglaClass,
        scrollController: ScrollController(),
        primaryOrange: const Color(0xFFFF9800),
        successGreen: const Color(0xFF2ECC71),
        redAccent: const Color(0xFFE53935),
        greenAccent: const Color(0xFF43A047),
        tealAccent: const Color(0xFF00897B),
        purpleAccent: const Color(0xFF9B59B6),
        goldAccent: const Color(0xFFFFD700),
        lightOrange: const Color(0xFFFFF3E0),
      )));
      break;
      
    case MyEducationType.sportsClub:
      final club = item.rawItem as SportsClub;
      Navigator.push(context, MaterialPageRoute(builder: (context) => SportsClubDetailsScreen(
        club: club,
        scrollController: ScrollController(),
        primaryRed: const Color(0xFFF44336),
        successGreen: const Color(0xFF4CAF50),
        warningOrange: const Color(0xFFFF9800),
        infoBlue: const Color(0xFF2196F3),
        purpleAccent: const Color(0xFF9B59B6),
        goldAccent: const Color(0xFFFFD700),
        tealAccent: const Color(0xFF00897B),
        lightRed: const Color(0xFFFFEBEE),
      )));
      break;
  }
}

// ====================== HELPER CLASSES ======================
enum MyEducationType {
  tutoringService,
  admissionsGuidance,
  banglaClass,
  sportsClub,
}

class MyEducationItem {
  final String id;
  final String title;
  final String subtitle;
  final MyEducationType type;
  final String status;
  final String? imageUrl;
  final dynamic rawItem;

  MyEducationItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.type,
    required this.status,
    this.imageUrl,
    required this.rawItem,
  });
}