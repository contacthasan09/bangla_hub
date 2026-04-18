// lib/screens/user_app/community_services/my_services/my_services_screen.dart
import 'package:bangla_hub/screens/user_app/community_services/my_services/widgets/edit_service_dialog.dart';
import 'package:bangla_hub/screens/user_app/community_services/my_services/widgets/service_card.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:bangla_hub/models/community_services_models.dart';
import 'package:bangla_hub/providers/auth_provider.dart';
import 'package:bangla_hub/providers/service_provider_provider.dart';
import 'package:bangla_hub/screens/user_app/community_services/service_provider_detail_screen.dart';

class MyServicesScreen extends StatefulWidget {
  final VoidCallback? onBack;
  
  const MyServicesScreen({Key? key, this.onBack}) : super(key: key);

  @override
  State<MyServicesScreen> createState() => _MyServicesScreenState();
}

class _MyServicesScreenState extends State<MyServicesScreen> with TickerProviderStateMixin {
  late final TabController _tabController;
  
  final Color _primaryGreen = const Color(0xFF006A4E);
  final Color _primaryRed = const Color(0xFFF42A41);
  final Color _goldAccent = const Color(0xFFFFD700);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserServices();
    });
  }

  Future<void> _loadUserServices() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final serviceProvider = Provider.of<ServiceProviderProvider>(context, listen: false);
    
    if (authProvider.user != null) {
      print('👤 Loading services for user: ${authProvider.user!.id}');
      await serviceProvider.loadUserServices(authProvider.user!.id);
    }
  }

  Future<void> _refreshData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final serviceProvider = Provider.of<ServiceProviderProvider>(context, listen: false);
    
    if (authProvider.user != null) {
      await serviceProvider.loadUserServices(authProvider.user!.id);
    }
  }

  Future<void> _showDeleteConfirmationDialog(ServiceProviderModel service) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Service',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: _primaryRed),
        ),
        content: Text(
          'Are you sure you want to delete "${service.companyName}"? This action cannot be undone.',
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
      final serviceProvider = Provider.of<ServiceProviderProvider>(context, listen: false);
      final success = await serviceProvider.deleteUserService(service.id!);
      
      if (mounted && success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Service deleted successfully'),
            backgroundColor: _primaryGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
        await _refreshData();
      }
    }
  }

  void _showEditDialog(ServiceProviderModel service) {
    showDialog(
      context: context,
      builder: (context) => EditServiceDialog(
        service: service,
        onUpdate: _refreshData,
      ),
    );
  }

  void _showServiceDetails(ServiceProviderModel service) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ServiceProviderDetailScreen(
          providerId: service.id!,
        ),
      ),
    );
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
          'My Services',
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
            Tab(text: 'My Services'),
            Tab(text: 'Pending'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _MyServicesList(
            onEdit: _showEditDialog,
            onDelete: _showDeleteConfirmationDialog,
            onTap: _showServiceDetails,
            onRefresh: _refreshData,
          ),
          _PendingServicesList(
            onEdit: _showEditDialog,
            onDelete: _showDeleteConfirmationDialog,
            onTap: _showServiceDetails,
            onRefresh: _refreshData,
          ),
        ],
      ),
    );
  }
}

class _MyServicesList extends StatelessWidget {
  final Function(ServiceProviderModel) onEdit;
  final Function(ServiceProviderModel) onDelete;
  final Function(ServiceProviderModel) onTap;
  final Future<void> Function() onRefresh;

  const _MyServicesList({
    required this.onEdit,
    required this.onDelete,
    required this.onTap,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final serviceProvider = Provider.of<ServiceProviderProvider>(context);
    final services = serviceProvider.myApprovedServices;
    final isLoading = serviceProvider.isLoading;
    
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (services.isEmpty) {
      return _buildEmptyState(
        context: context,
        icon: Icons.miscellaneous_services_rounded,
        title: 'No Services Yet',
        message: 'Services you create will be shown here after approval',
      );
    }
    
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: EdgeInsets.all(12),
        itemCount: services.length,
        itemBuilder: (context, index) {
          final service = services[index];
          return ServiceCard(
            service: service,
            onTap: () => onTap(service),
            onEdit: () => onEdit(service),
            onDelete: () => onDelete(service),
            showActions: true,
          );
        },
      ),
    );
  }

  Widget _buildEmptyState({required IconData icon, required BuildContext context, required String title, required String message}) {
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
}

class _PendingServicesList extends StatelessWidget {
  final Function(ServiceProviderModel) onEdit;
  final Function(ServiceProviderModel) onDelete;
  final Function(ServiceProviderModel) onTap;
  final Future<void> Function() onRefresh;

  const _PendingServicesList({
    required this.onEdit,
    required this.onDelete,
    required this.onTap,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final serviceProvider = Provider.of<ServiceProviderProvider>(context);
    final services = serviceProvider.myPendingServices;
    final isLoading = serviceProvider.isLoading;
    
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (services.isEmpty) {
      return _buildEmptyState(
        context: context,
        icon: Icons.hourglass_empty_rounded,
        title: 'No Pending Services',
        message: 'Services waiting for approval will appear here',
      );
    }
    
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: EdgeInsets.all(12),
        itemCount: services.length,
        itemBuilder: (context, index) {
          final service = services[index];
          return ServiceCard(
            service: service,
            onTap: () => onTap(service),
            onEdit: () => onEdit(service),
            onDelete: () => onDelete(service),
            showActions: true,
          );
        },
      ),
    );
  }

  Widget _buildEmptyState({required IconData icon, required BuildContext context, required String title, required String message}) {
    final isTablet = MediaQuery.of(context).size.width >= 600;
    
    return Center(
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 32 : 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: isTablet ? 80 : 60, color: Colors.orange[400]),
            const SizedBox(height: 20),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: isTablet ? 20 : 16,
                fontWeight: FontWeight.w600,
                color: Colors.orange[700],
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
}