// screens/admin/service_management_screen.dart
import 'dart:io';
import 'dart:convert';
import 'package:bangla_hub/models/community_services_models.dart';
import 'package:bangla_hub/providers/service_provider_provider.dart';
import 'package:bangla_hub/screens/admin_app/screens/community_service_management/service_provider_admin_detail_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class ServiceManagementScreen extends StatefulWidget {
  const ServiceManagementScreen({super.key});

  @override
  State<ServiceManagementScreen> createState() => _ServiceManagementScreenState();
}

class _ServiceManagementScreenState extends State<ServiceManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _filterType = 'all';
  bool _showStatistics = true;

  // Premium Color Palette - Bangladesh Flag Inspired
  final Color _primaryRed = Color(0xFFE03C32); // Bangladesh flag red
  final Color _primaryGreen = Color(0xFF006A4E); // Bangladesh flag green
  final Color _darkGreen = Color(0xFF00432D);
  final Color _lightGreen = Color(0xFFE8F5E9);
  final Color _goldAccent = Color(0xFFFFD700);
  final Color _deepRed = Color(0xFFC62828);
  final Color _bgGradient1 = Color(0xFF0A2F1D);
  final Color _bgGradient2 = Color(0xFF004D38);
  final Color _cardColor = Color(0x1AFFFFFF);
  final Color _borderColor = Color(0x33FFFFFF);
  final Color _textWhite = Color(0xFFFFFFFF);
  final Color _textLight = Color(0xFFE0E0E0);
  final Color _textMuted = Color(0xFFAAAAAA);
  final Color _offWhite = Color(0xFFF8F8F8);
  final Color _successGreen = Color(0xFF4CAF50);
  final Color _warningOrange = Color(0xFFFF9800);
  final Color _infoBlue = Color(0xFF2196F3);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<ServiceProviderProvider>(context, listen: false);
      provider.loadServiceProviders(adminView: true);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Premium Add Service Dialog
  void _showPremiumAddServiceDialog(BuildContext context) {
    print('➕ Showing add service dialog');
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final mediaQuery = MediaQuery.of(context);
          final isKeyboardVisible = mediaQuery.viewInsets.bottom > 0;
          final screenWidth = MediaQuery.of(context).size.width;
          final isTablet = screenWidth >= 600;
          
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: EdgeInsets.symmetric(
              horizontal: isTablet ? 40 : 20,
              vertical: isKeyboardVisible ? (isTablet ? 20 : 10) : (isTablet ? 40 : 20),
            ),
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + (isTablet ? 20 : 10),
              ),
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: 600,
                  minWidth: 300,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_bgGradient1, _bgGradient2],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(isTablet ? 35 : 25),
                  border: Border.all(color: _borderColor, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.4),
                      blurRadius: 40,
                      offset: Offset(0, 20),
                    ),
                  ],
                ),
                child: _AddServiceDialogContent(
                  primaryRed: _primaryRed,
                  primaryGreen: _primaryGreen,
                  darkGreen: _darkGreen,
                  deepRed: _deepRed,
                  bgGradient1: _bgGradient1,
                  bgGradient2: _bgGradient2,
                  borderColor: _borderColor,
                  textWhite: _textWhite,
                  textMuted: _textMuted,
                  textLight: _textLight,
                  offWhite: _offWhite,
                  successGreen: _successGreen,
                  warningOrange: _warningOrange,
                  infoBlue: _infoBlue,
                  lightGreen: _lightGreen,
                  goldAccent: _goldAccent,
                  isTablet: isTablet,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

/*  Widget _buildServiceProviderCard(ServiceProviderModel provider, BuildContext context, bool isTablet) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isTablet ? 24 : 16,
        vertical: isTablet ? 8 : 6,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ServiceProviderAdminDetailScreen(providerId: provider.id!),
              ),
            );
          },
          borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
          child: Padding(
            padding: EdgeInsets.all(isTablet ? 20 : 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Image with Status Indicator
                Stack(
                  children: [
                    provider.getProfileImageWidget(size: isTablet ? 80 : 60),
                    
                    // Status Badges
                    if (provider.isDeleted)
                      Positioned(
                        top: 0,
                        left: 0,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isTablet ? 8 : 6,
                            vertical: isTablet ? 4 : 3,
                          ),
                          decoration: BoxDecoration(
                            color: _deepRed,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(isTablet ? 12 : 8),
                              bottomRight: Radius.circular(isTablet ? 12 : 8),
                            ),
                          ),
                          child: Text(
                            'DELETED',
                            style: GoogleFonts.inter(
                              fontSize: isTablet ? 10 : 8,
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    
                    if (!provider.isAvailable)
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Container(
                          padding: EdgeInsets.all(isTablet ? 6 : 4),
                          decoration: BoxDecoration(
                            color: _warningOrange,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.block,
                            size: isTablet ? 14 : 10,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    
                    if (!provider.isVerified)
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isTablet ? 8 : 6,
                            vertical: isTablet ? 4 : 3,
                          ),
                          decoration: BoxDecoration(
                            color: _warningOrange,
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(isTablet ? 12 : 8),
                              bottomRight: Radius.circular(isTablet ? 12 : 8),
                            ),
                          ),
                          child: Text(
                            'PENDING',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: isTablet ? 10 : 8,
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    
                    if (provider.isVerified)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: EdgeInsets.all(isTablet ? 4 : 3),
                          decoration: BoxDecoration(
                            color: _successGreen,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.verified,
                            size: isTablet ? 14 : 10,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),

                SizedBox(width: isTablet ? 20 : 16),

                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name and Status
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  provider.fullName,
                                  style: GoogleFonts.poppins(
                                    fontSize: isTablet ? 20 : 16,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.black87,
                                    height: 1.2,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: 2),
                                Text(
                                  provider.companyName,
                                  style: GoogleFonts.inter(
                                    fontSize: isTablet ? 14 : 12,
                                    color: Colors.grey.shade700,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          
                          // Quick Status Indicator
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isTablet ? 12 : 8,
                              vertical: isTablet ? 6 : 4,
                            ),
                            decoration: BoxDecoration(
                              color: provider.isAvailable && !provider.isDeleted
                                ? _successGreen.withOpacity(0.1)
                                : _warningOrange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(isTablet ? 10 : 8),
                              border: Border.all(
                                color: provider.isAvailable && !provider.isDeleted
                                  ? _successGreen
                                  : _warningOrange,
                                width: 1,
                              ),
                            ),
                            child: Text(
                              provider.isDeleted ? 'Deleted' : 
                              provider.isAvailable ? 'Active' : 'Inactive',
                              style: GoogleFonts.inter(
                                fontSize: isTablet ? 12 : 10,
                                fontWeight: FontWeight.w700,
                                color: provider.isAvailable && !provider.isDeleted
                                  ? _successGreen
                                  : _warningOrange,
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: isTablet ? 12 : 8),

                      // Service Type
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isTablet ? 10 : 8,
                              vertical: isTablet ? 6 : 4,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [_primaryRed.withOpacity(0.1), _primaryGreen.withOpacity(0.1)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(isTablet ? 10 : 8),
                              border: Border.all(color: _primaryRed.withOpacity(0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  provider.serviceCategory.icon,
                                  size: isTablet ? 16 : 14,
                                  color: _primaryRed,
                                ),
                                SizedBox(width: isTablet ? 6 : 4),
                                Flexible(
                                  child: Text(
                                    provider.serviceCategory.displayName,
                                    style: GoogleFonts.inter(
                                      fontSize: isTablet ? 13 : 11,
                                      fontWeight: FontWeight.w600,
                                      color: _primaryRed,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: isTablet ? 8 : 6),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isTablet ? 10 : 8,
                              vertical: isTablet ? 6 : 4,
                            ),
                            decoration: BoxDecoration(
                              color: _lightGreen,
                              borderRadius: BorderRadius.circular(isTablet ? 10 : 8),
                              border: Border.all(color: _primaryGreen.withOpacity(0.3)),
                            ),
                            child: Flexible(
                              child: Text(
                                provider.serviceProvider,
                                style: GoogleFonts.inter(
                                  fontSize: isTablet ? 13 : 11,
                                  fontWeight: FontWeight.w600,
                                  color: _primaryGreen,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: isTablet ? 12 : 8),

                      // Location
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_rounded,
                            size: isTablet ? 18 : 14,
                            color: Colors.grey.shade600,
                          ),
                          SizedBox(width: isTablet ? 8 : 6),
                          Expanded(
                            child: Text(
                              '${provider.city}, ${provider.state}',
                              style: GoogleFonts.inter(
                                fontSize: isTablet ? 14 : 12,
                                color: Colors.grey.shade700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: isTablet ? 12 : 8),

                      // Stats Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Likes
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isTablet ? 12 : 8,
                              vertical: isTablet ? 6 : 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(isTablet ? 8 : 6),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.favorite_rounded,
                                  size: isTablet ? 16 : 12,
                                  color: Colors.red,
                                ),
                                SizedBox(width: isTablet ? 6 : 4),
                                Text(
                                  '${provider.totalLikes}',
                                  style: GoogleFonts.inter(
                                    fontSize: isTablet ? 14 : 12,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Rating
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isTablet ? 12 : 8,
                              vertical: isTablet ? 6 : 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(isTablet ? 8 : 6),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.star_rounded,
                                  size: isTablet ? 16 : 12,
                                  color: Colors.amber,
                                ),
                                SizedBox(width: isTablet ? 6 : 4),
                                Text(
                                  provider.rating.toStringAsFixed(1),
                                  style: GoogleFonts.inter(
                                    fontSize: isTablet ? 14 : 12,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.amber.shade800,
                                  ),
                                ),
                                SizedBox(width: isTablet ? 4 : 2),
                                Text(
                                  '(${provider.totalReviews})',
                                  style: GoogleFonts.inter(
                                    fontSize: isTablet ? 12 : 10,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: isTablet ? 12 : 8),

                      // Quick Actions
                      Row(
                        children: [
                          Expanded(
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  final providerProvider = Provider.of<ServiceProviderProvider>(context, listen: false);
                                  providerProvider.toggleAvailability(provider.id!, !provider.isAvailable);
                                },
                                borderRadius: BorderRadius.circular(isTablet ? 10 : 8),
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    vertical: isTablet ? 10 : 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: provider.isAvailable
                                      ? _successGreen.withOpacity(0.1)
                                      : _warningOrange.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(isTablet ? 10 : 8),
                                    border: Border.all(
                                      color: provider.isAvailable
                                        ? _successGreen
                                        : _warningOrange,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Center(
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          provider.isAvailable ? Icons.check_circle_rounded : Icons.remove_circle_rounded,
                                          size: isTablet ? 18 : 14,
                                          color: provider.isAvailable
                                            ? _successGreen
                                            : _warningOrange,
                                        ),
                                        SizedBox(width: isTablet ? 8 : 6),
                                        Text(
                                          provider.isAvailable ? 'Active' : 'Inactive',
                                          style: GoogleFonts.inter(
                                            fontSize: isTablet ? 14 : 12,
                                            fontWeight: FontWeight.w700,
                                            color: provider.isAvailable
                                              ? _successGreen
                                              : _warningOrange,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: isTablet ? 12 : 8),
                          Expanded(
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  final providerProvider = Provider.of<ServiceProviderProvider>(context, listen: false);
                                  providerProvider.toggleVerification(provider.id!, !provider.isVerified);
                                },
                                borderRadius: BorderRadius.circular(isTablet ? 10 : 8),
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    vertical: isTablet ? 10 : 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: provider.isVerified
                                      ? _infoBlue.withOpacity(0.1)
                                      : _warningOrange.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(isTablet ? 10 : 8),
                                    border: Border.all(
                                      color: provider.isVerified
                                        ? _infoBlue
                                        : _warningOrange,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Center(
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          provider.isVerified ? Icons.verified_rounded : Icons.pending_rounded,
                                          size: isTablet ? 18 : 14,
                                          color: provider.isVerified
                                            ? _infoBlue
                                            : _warningOrange,
                                        ),
                                        SizedBox(width: isTablet ? 8 : 6),
                                        Text(
                                          provider.isVerified ? 'Verified' : 'Verify',
                                          style: GoogleFonts.inter(
                                            fontSize: isTablet ? 14 : 12,
                                            fontWeight: FontWeight.w700,
                                            color: provider.isVerified
                                              ? _infoBlue
                                              : _warningOrange,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
    */

Widget _buildServiceProviderCard(ServiceProviderModel provider, BuildContext context, bool isTablet) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isTablet ? 24 : 16,
        vertical: isTablet ? 8 : 6,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ServiceProviderAdminDetailScreen(providerId: provider.id!),
              ),
            );
          },
          borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
          child: Padding(
            padding: EdgeInsets.all(isTablet ? 24 : 18), // Increased padding for better spacing
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Image with Status Indicator
                Stack(
                  children: [
                    provider.getProfileImageWidget(size: isTablet ? 90 : 70), // Slightly increased size
                    
                    // Status Badges
                    if (provider.isDeleted)
                      Positioned(
                        top: 0,
                        left: 0,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isTablet ? 8 : 6,
                            vertical: isTablet ? 4 : 3,
                          ),
                          decoration: BoxDecoration(
                            color: _deepRed,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(isTablet ? 12 : 8),
                              bottomRight: Radius.circular(isTablet ? 12 : 8),
                            ),
                          ),
                          child: Text(
                            'DELETED',
                            style: GoogleFonts.inter(
                              fontSize: isTablet ? 10 : 8,
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    
                    if (!provider.isAvailable)
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Container(
                          padding: EdgeInsets.all(isTablet ? 6 : 4),
                          decoration: BoxDecoration(
                            color: _warningOrange,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.block,
                            size: isTablet ? 14 : 10,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    
                    if (!provider.isVerified)
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isTablet ? 8 : 6,
                            vertical: isTablet ? 4 : 3,
                          ),
                          decoration: BoxDecoration(
                            color: _warningOrange,
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(isTablet ? 12 : 8),
                              bottomRight: Radius.circular(isTablet ? 12 : 8),
                            ),
                          ),
                          child: Text(
                            'PENDING',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: isTablet ? 10 : 8,
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    
                    if (provider.isVerified)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: EdgeInsets.all(isTablet ? 4 : 3),
                          decoration: BoxDecoration(
                            color: _successGreen,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.verified,
                            size: isTablet ? 14 : 10,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),

                SizedBox(width: isTablet ? 20 : 16),

                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name and Status
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  provider.fullName,
                                  style: GoogleFonts.poppins(
                                    fontSize: isTablet ? 20 : 16,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.black87,
                                    height: 1.2,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: 2),
                                Text(
                                  provider.companyName ?? 'Not Provided',
                                  style: GoogleFonts.inter(
                                    fontSize: isTablet ? 14 : 12,
                                    color: Colors.grey.shade700,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          
                          // Quick Status Indicator
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isTablet ? 12 : 8,
                              vertical: isTablet ? 6 : 4,
                            ),
                            decoration: BoxDecoration(
                              color: provider.isAvailable && !provider.isDeleted
                                ? _successGreen.withOpacity(0.1)
                                : _warningOrange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(isTablet ? 10 : 8),
                              border: Border.all(
                                color: provider.isAvailable && !provider.isDeleted
                                  ? _successGreen
                                  : _warningOrange,
                                width: 1,
                              ),
                            ),
                            child: Text(
                              provider.isDeleted ? 'Deleted' : 
                              provider.isAvailable ? 'Active' : 'Inactive',
                              style: GoogleFonts.inter(
                                fontSize: isTablet ? 12 : 10,
                                fontWeight: FontWeight.w700,
                                color: provider.isAvailable && !provider.isDeleted
                                  ? _successGreen
                                  : _warningOrange,
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: isTablet ? 12 : 8),

                      // Service Type and Provider - Changed from Row to Column
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Service Category
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isTablet ? 10 : 8,
                              vertical: isTablet ? 6 : 4,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [_primaryRed.withOpacity(0.1), _primaryGreen.withOpacity(0.1)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(isTablet ? 10 : 8),
                              border: Border.all(color: _primaryRed.withOpacity(0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  provider.serviceCategory.icon,
                                  size: isTablet ? 16 : 14,
                                  color: _primaryRed,
                                ),
                                SizedBox(width: isTablet ? 6 : 4),
                                Flexible(
                                  child: Text(
                                    provider.serviceCategory.displayName,
                                    style: GoogleFonts.inter(
                                      fontSize: isTablet ? 13 : 11,
                                      fontWeight: FontWeight.w600,
                                      color: _primaryRed,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: isTablet ? 8 : 6), // Added spacing between the two
                          
                          // Service Provider
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isTablet ? 10 : 8,
                              vertical: isTablet ? 6 : 4,
                            ),
                            decoration: BoxDecoration(
                              color: _lightGreen,
                              borderRadius: BorderRadius.circular(isTablet ? 10 : 8),
                              border: Border.all(color: _primaryGreen.withOpacity(0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    provider.serviceProvider,
                                    style: GoogleFonts.inter(
                                      fontSize: isTablet ? 13 : 11,
                                      fontWeight: FontWeight.w600,
                                      color: _primaryGreen,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: isTablet ? 12 : 8),

                      // Location
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_rounded,
                            size: isTablet ? 18 : 14,
                            color: Colors.grey.shade600,
                          ),
                          SizedBox(width: isTablet ? 8 : 6),
                          Expanded(
                            child: Text(
                              '${provider.city}, ${provider.state}',
                              style: GoogleFonts.inter(
                                fontSize: isTablet ? 14 : 12,
                                color: Colors.grey.shade700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: isTablet ? 12 : 8),

                      // Stats Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Likes
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isTablet ? 12 : 8,
                              vertical: isTablet ? 6 : 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(isTablet ? 8 : 6),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.favorite_rounded,
                                  size: isTablet ? 16 : 12,
                                  color: Colors.red,
                                ),
                                SizedBox(width: isTablet ? 6 : 4),
                                Text(
                                  '${provider.totalLikes}',
                                  style: GoogleFonts.inter(
                                    fontSize: isTablet ? 14 : 12,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Rating
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isTablet ? 12 : 8,
                              vertical: isTablet ? 6 : 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(isTablet ? 8 : 6),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.star_rounded,
                                  size: isTablet ? 16 : 12,
                                  color: Colors.amber,
                                ),
                                SizedBox(width: isTablet ? 6 : 4),
                                Text(
                                  provider.rating.toStringAsFixed(1),
                                  style: GoogleFonts.inter(
                                    fontSize: isTablet ? 14 : 12,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.amber.shade800,
                                  ),
                                ),
                                SizedBox(width: isTablet ? 4 : 2),
                                Text(
                                  '(${provider.totalReviews})',
                                  style: GoogleFonts.inter(
                                    fontSize: isTablet ? 12 : 10,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: isTablet ? 12 : 8),

                      // Quick Actions
                      Row(
                        children: [
                          Expanded(
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  final providerProvider = Provider.of<ServiceProviderProvider>(context, listen: false);
                                  providerProvider.toggleAvailability(provider.id!, !provider.isAvailable);
                                },
                                borderRadius: BorderRadius.circular(isTablet ? 10 : 8),
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    vertical: isTablet ? 10 : 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: provider.isAvailable
                                      ? _successGreen.withOpacity(0.1)
                                      : _warningOrange.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(isTablet ? 10 : 8),
                                    border: Border.all(
                                      color: provider.isAvailable
                                        ? _successGreen
                                        : _warningOrange,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Center(
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          provider.isAvailable ? Icons.check_circle_rounded : Icons.remove_circle_rounded,
                                          size: isTablet ? 18 : 14,
                                          color: provider.isAvailable
                                            ? _successGreen
                                            : _warningOrange,
                                        ),
                                        SizedBox(width: isTablet ? 8 : 6),
                                        Text(
                                          provider.isAvailable ? 'Active' : 'Inactive',
                                          style: GoogleFonts.inter(
                                            fontSize: isTablet ? 14 : 12,
                                            fontWeight: FontWeight.w700,
                                            color: provider.isAvailable
                                              ? _successGreen
                                              : _warningOrange,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: isTablet ? 12 : 8),
                          Expanded(
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  final providerProvider = Provider.of<ServiceProviderProvider>(context, listen: false);
                                  providerProvider.toggleVerification(provider.id!, !provider.isVerified);
                                },
                                borderRadius: BorderRadius.circular(isTablet ? 10 : 8),
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    vertical: isTablet ? 10 : 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: provider.isVerified
                                      ? _infoBlue.withOpacity(0.1)
                                      : _warningOrange.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(isTablet ? 10 : 8),
                                    border: Border.all(
                                      color: provider.isVerified
                                        ? _infoBlue
                                        : _warningOrange,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Center(
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          provider.isVerified ? Icons.verified_rounded : Icons.pending_rounded,
                                          size: isTablet ? 18 : 14,
                                          color: provider.isVerified
                                            ? _infoBlue
                                            : _warningOrange,
                                        ),
                                        SizedBox(width: isTablet ? 8 : 6),
                                        Text(
                                          provider.isVerified ? 'Verified' : 'Verify',
                                          style: GoogleFonts.inter(
                                            fontSize: isTablet ? 14 : 12,
                                            fontWeight: FontWeight.w700,
                                            color: provider.isVerified
                                              ? _infoBlue
                                              : _warningOrange,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }




  Widget _buildStatistics(BuildContext context, bool isTablet) {
    final provider = Provider.of<ServiceProviderProvider>(context);
    final stats = provider.allProviders;

    final total = stats.length;
    final pending = stats.where((p) => !p.isVerified && !p.isDeleted).length;
    final available = stats.where((p) => p.isAvailable && !p.isDeleted).length;
    final deleted = stats.where((p) => p.isDeleted).length;
    final verified = stats.where((p) => p.isVerified && !p.isDeleted).length;

    return SliverToBoxAdapter(
      child: Container(
        margin: EdgeInsets.all(isTablet ? 24 : 16),
        padding: EdgeInsets.all(isTablet ? 24 : 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [_bgGradient1, _bgGradient2],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(isTablet ? 25 : 20),
          border: Border.all(color: _borderColor, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 25,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: isTablet ? 50 : 40,
                  height: isTablet ? 50 : 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_primaryRed, _primaryGreen],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(isTablet ? 12 : 10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      Icons.bar_chart_rounded,
                      color: Colors.white,
                      size: isTablet ? 28 : 24,
                    ),
                  ),
                ),
                SizedBox(width: isTablet ? 16 : 12),
                Text(
                  'Service Statistics', overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                //    fontSize: isTablet ? 24 : 20,
                                        fontSize: isTablet ? 18 : 15,

                    fontWeight: FontWeight.w800,
                    color: _textWhite,
                  ),
                ),
                Spacer(),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _showStatistics = !_showStatistics;
                    });
                  },
                  icon: Container(
                    width: isTablet ? 40 : 32,
                    height: isTablet ? 40 : 32,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(color: _borderColor),
                    ),
                    child: Icon(
                      _showStatistics ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                      color: _textMuted,
                      size: isTablet ? 22 : 18,
                    ),
                  ),
                ),
              ],
            ),
            
            if (_showStatistics) ...[
              SizedBox(height: isTablet ? 24 : 20),
              
              // Stats Grid
              Wrap(
                spacing: isTablet ? 16 : 12,
                runSpacing: isTablet ? 16 : 12,
                alignment: WrapAlignment.spaceBetween,
                children: [
                  _buildStatCard(
                    'Total Services',
                    total.toString(),
                    Colors.white,
                    Icons.business_center_rounded,
                    'All registered services',
                    isTablet: isTablet,
                  ),
                  _buildStatCard(
                    'Verified',
                    verified.toString(),
                    _successGreen,
                    Icons.verified_rounded,
                    'Approved services',
                    isTablet: isTablet,
                  ),
                  _buildStatCard(
                    'Available',
                    available.toString(),
                    _infoBlue,
                    Icons.check_circle_rounded,
                    'Active for booking',
                    isTablet: isTablet,
                  ),
                  _buildStatCard(
                    'Pending',
                    pending.toString(),
                    _warningOrange,
                    Icons.pending_rounded,
                    'Awaiting approval',
                    isTablet: isTablet,
                  ),
                  _buildStatCard(
                    'Deleted',
                    deleted.toString(),
                    _deepRed,
                    Icons.delete_rounded,
                    'Removed services',
                    isTablet: isTablet,
                  ),
                ],
              ),
              
              // Summary
              SizedBox(height: isTablet ? 20 : 16),
              Container(
                padding: EdgeInsets.all(isTablet ? 20 : 16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
                  border: Border.all(color: _borderColor),
                ),
                child: Row(
                  children: [
                    Container(
                      width: isTablet ? 40 : 32,
                      height: isTablet ? 40 : 32,
                      decoration: BoxDecoration(
                        color: _primaryGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(isTablet ? 10 : 8),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.analytics_rounded,
                          color: _primaryGreen,
                          size: isTablet ? 22 : 18,
                        ),
                      ),
                    ),
                    SizedBox(width: isTablet ? 16 : 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Service Health',
                            style: GoogleFonts.inter(
                              fontSize: isTablet ? 16 : 14,
                              fontWeight: FontWeight.w700,
                              color: _textWhite,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '${((verified / total) * 100).toStringAsFixed(1)}% of services are verified',
                            style: GoogleFonts.inter(
                              fontSize: isTablet ? 14 : 12,
                              color: _textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color, IconData icon, String description, {required bool isTablet}) {
    return Container(
      width: isTablet ? 170 : 140,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 16 : 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(isTablet ? 8 : 6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: isTablet ? 22 : 18,
                  ),
                ),
                Spacer(),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: isTablet ? 28 : 24,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ],
            ),
            SizedBox(height: isTablet ? 12 : 8),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: isTablet ? 16 : 14,
                fontWeight: FontWeight.w700,
                color: _textWhite,
              ),
            ),
            SizedBox(height: isTablet ? 4 : 2),
            Text(
              description,
              style: GoogleFonts.inter(
                fontSize: isTablet ? 12 : 10,
                color: _textMuted,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showPremiumAddServiceDialog(context),
          icon: Icon(
            Icons.add_circle_rounded,
            size: isTablet ? 28 : 24,
          ),
          label: Text(
            'Add Service',
            style: GoogleFonts.inter(
              fontSize: isTablet ? 18 : 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          backgroundColor: _primaryGreen,
          foregroundColor: Colors.white,
          elevation: 12,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(isTablet ? 30 : 25),
          ),
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                _bgGradient1,
                _bgGradient2,
                _primaryGreen,
              ],
            ),
          ),
          child: CustomScrollView(
            slivers: [
              // Premium Sliver App Bar
              SliverAppBar(
                expandedHeight: isTablet ? 180 : 140,
                collapsedHeight: isTablet ? 100 : 80,
                floating: false,
                pinned: true,
                snap: false,
                elevation: 0,
                backgroundColor: Colors.transparent,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _primaryGreen.withOpacity(0.95),
                          _primaryRed.withOpacity(0.15),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: isTablet ? 40 : 24,
                          vertical: isTablet ? 20 : 16,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Pattern Design
                            Container(
                              height: 4,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [_primaryRed, _goldAccent, _primaryRed],
                                  stops: [0.0, 0.5, 1.0],
                                ),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            SizedBox(height: isTablet ? 20 : 16),
                            
                            Row(
                              children: [
                                Container(
                                  width: isTablet ? 60 : 50,
                                  height: isTablet ? 60 : 50,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [_primaryRed, _primaryGreen],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 10,
                                        offset: Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.manage_accounts_rounded,
                                    color: Colors.white,
                                    size: isTablet ? 32 : 28,
                                  ),
                                ),
                                SizedBox(width: isTablet ? 20 : 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Service Management',
                                        style: GoogleFonts.poppins(
                                          fontSize: isTablet ? 28 : 22,
                                          fontWeight: FontWeight.w800,
                                          color: _textWhite,
                                          letterSpacing: 0.5,
                                          shadows: [
                                            Shadow(
                                              blurRadius: 10,
                                              color: Colors.black.withOpacity(0.3),
                                            ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Consumer<ServiceProviderProvider>(
                                        builder: (context, provider, child) {
                                          return Text(
                                            'Manage ${provider.allProviders.length} service providers',
                                            style: GoogleFonts.inter(
                                              fontSize: isTablet ? 16 : 14,
                                              color: _textLight,
                                              fontWeight: FontWeight.w600,
                                              letterSpacing: 0.5,
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              
              // Statistics Section
              _buildStatistics(context, isTablet),
              
              // Search and Filter Section
              SliverToBoxAdapter(
                child: Container(
                  margin: EdgeInsets.all(isTablet ? 24 : 16),
                  padding: EdgeInsets.all(isTablet ? 24 : 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(isTablet ? 25 : 20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Search Bar
                      TextField(
                        controller: _searchController,
                        style: GoogleFonts.inter(
                          fontSize: isTablet ? 18 : 16,
                          color: Colors.black87,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search services by name, company, location...',
                          hintStyle: GoogleFonts.inter(
                            color: Colors.grey[600],
                          ),
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            color: _primaryGreen,
                            size: isTablet ? 28 : 24,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
                            borderSide: BorderSide(color: _borderColor),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
                            borderSide: BorderSide(color: _primaryGreen, width: 2),
                          ),
                          filled: true,
                          fillColor: _offWhite,
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: Icon(
                                    Icons.clear_rounded,
                                    color: _primaryRed,
                                    size: isTablet ? 24 : 20,
                                  ),
                                  onPressed: () {
                                    _searchController.clear();
                                    final provider = Provider.of<ServiceProviderProvider>(context, listen: false);
                                    provider.setSearchQuery('');
                                  },
                                  tooltip: 'Clear search',
                                )
                              : null,
                        ),
                        onChanged: (value) {
                          final provider = Provider.of<ServiceProviderProvider>(context, listen: false);
                          provider.setSearchQuery(value);
                        },
                      ),
                      
                      SizedBox(height: isTablet ? 20 : 16),
                      
                      // Filter Chips
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildPremiumFilterChip('All', 'all', isTablet),
                            _buildPremiumFilterChip('Pending', 'pending', isTablet),
                            _buildPremiumFilterChip('Verified', 'verified', isTablet),
                            _buildPremiumFilterChip('Active', 'available', isTablet),
                            _buildPremiumFilterChip('Deleted', 'deleted', isTablet),
                          ],
                        ),
                      ),
                      
                      // Results Count
                      SizedBox(height: isTablet ? 16 : 12),
                      Consumer<ServiceProviderProvider>(
                        builder: (context, provider, child) {
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: '${provider.serviceProviders.length} ',
                                      style: GoogleFonts.poppins(
                                        fontSize: isTablet ? 20 : 18,
                                        fontWeight: FontWeight.w800,
                                        color: _primaryGreen,
                                      ),
                                    ),
                                    TextSpan(
                                      text: 'services found',
                                      style: GoogleFonts.inter(
                                        fontSize: isTablet ? 16 : 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (provider.hasActiveFilters)
                                Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () {
                                      provider.clearFilters();
                                    },
                                    borderRadius: BorderRadius.circular(isTablet ? 12 : 10),
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: isTablet ? 20 : 16,
                                        vertical: isTablet ? 12 : 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _primaryRed.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(isTablet ? 12 : 10),
                                        border: Border.all(color: _primaryRed),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.clear_all_rounded,
                                            size: isTablet ? 20 : 16,
                                            color: _primaryRed,
                                          ),
                                          SizedBox(width: isTablet ? 8 : 6),
                                          Text(
                                            'Clear Filters',
                                            style: GoogleFonts.inter(
                                              fontSize: isTablet ? 16 : 14,
                                              fontWeight: FontWeight.w700,
                                              color: _primaryRed,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              
              // Services List
              _buildServicesList(isTablet),
              
              // Bottom Spacing
              SliverToBoxAdapter(
                child: SizedBox(height: isTablet ? 60 : 40),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumFilterChip(String label, String value, bool isTablet) {
    return Container(
      margin: EdgeInsets.only(right: isTablet ? 12 : 8),
      child: ChoiceChip(
        label: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: isTablet ? 14 : 12,
            fontWeight: FontWeight.w600,
            color: _filterType == value ? Colors.white : _primaryGreen,
          ),
        ),
        selected: _filterType == value,
        onSelected: (selected) {
          setState(() {
            _filterType = value;
            _applyFilter();
          });
        },
        selectedColor: _primaryGreen,
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: _filterType == value ? _primaryGreen : Colors.grey.shade300,
            width: 1.5,
          ),
        ),
        elevation: _filterType == value ? 4 : 0,
        shadowColor: _filterType == value ? _primaryGreen.withOpacity(0.3) : Colors.transparent,
      ),
    );
  }

  void _applyFilter() {
    final provider = Provider.of<ServiceProviderProvider>(context, listen: false);
    provider.loadServiceProviders(adminView: true);
  }

  Widget _buildServicesList(bool isTablet) {
    return Consumer<ServiceProviderProvider>(
      builder: (context, provider, child) {
        // Apply additional filtering based on selected filter type
        List<ServiceProviderModel> filteredProviders = provider.serviceProviders;
        
        switch (_filterType) {
          case 'pending':
            filteredProviders = filteredProviders.where((p) => !p.isVerified && !p.isDeleted).toList();
            break;
          case 'verified':
            filteredProviders = filteredProviders.where((p) => p.isVerified && !p.isDeleted).toList();
            break;
          case 'available':
            filteredProviders = filteredProviders.where((p) => p.isAvailable && !p.isDeleted).toList();
            break;
          case 'deleted':
            filteredProviders = filteredProviders.where((p) => p.isDeleted).toList();
            break;
        }

        if (provider.isLoading && provider.serviceProviders.isEmpty) {
          return SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: isTablet ? 80 : 60,
                    height: isTablet ? 80 : 60,
                    child: CircularProgressIndicator(
                      strokeWidth: 4,
                      color: _primaryGreen,
                    ),
                  ),
                  SizedBox(height: isTablet ? 24 : 20),
                  Text(
                    'Loading Services...',
                    style: GoogleFonts.poppins(
                      fontSize: isTablet ? 24 : 20,
                      fontWeight: FontWeight.w700,
                      color: _primaryGreen,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (provider.error.isNotEmpty) {
          return SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(isTablet ? 40 : 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: isTablet ? 120 : 100,
                      height: isTablet ? 120 : 100,
                      decoration: BoxDecoration(
                        color: _primaryRed.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.error_outline_rounded,
                        size: isTablet ? 60 : 50,
                        color: _primaryRed,
                      ),
                    ),
                    SizedBox(height: isTablet ? 24 : 20),
                    Text(
                      'Error Loading Services',
                      style: GoogleFonts.poppins(
                        fontSize: isTablet ? 24 : 20,
                        fontWeight: FontWeight.w800,
                        color: _primaryRed,
                      ),
                    ),
                    SizedBox(height: isTablet ? 16 : 12),
                    Text(
                      provider.error,
                      style: GoogleFonts.inter(
                        fontSize: isTablet ? 16 : 14,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: isTablet ? 24 : 20),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          provider.loadServiceProviders(adminView: true);
                        },
                        borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isTablet ? 32 : 24,
                            vertical: isTablet ? 16 : 14,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [_primaryGreen, _darkGreen],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
                            boxShadow: [
                              BoxShadow(
                                color: _primaryGreen.withOpacity(0.3),
                                blurRadius: 15,
                                offset: Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Text(
                            'Try Again',
                            style: GoogleFonts.inter(
                              fontSize: isTablet ? 18 : 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        if (filteredProviders.isEmpty) {
          return SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(isTablet ? 40 : 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: isTablet ? 120 : 100,
                      height: isTablet ? 120 : 100,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [_primaryGreen.withOpacity(0.1), _primaryRed.withOpacity(0.1)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.search_off_rounded,
                        size: isTablet ? 50 : 40,
                        color: _primaryGreen,
                      ),
                    ),
                    SizedBox(height: isTablet ? 24 : 20),
                    Text(
                      'No Services Found',
                      style: GoogleFonts.poppins(
                        fontSize: isTablet ? 24 : 20,
                        fontWeight: FontWeight.w800,
                        color: _primaryGreen,
                      ),
                    ),
                    SizedBox(height: isTablet ? 12 : 10),
                    Text(
                      _filterType == 'all' 
                        ? 'No services match your search criteria'
                        : 'No ${_filterType} services found',
                      style: GoogleFonts.inter(
                        fontSize: isTablet ? 16 : 14,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: isTablet ? 24 : 20),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          provider.clearFilters();
                          setState(() {
                            _filterType = 'all';
                            _searchController.clear();
                          });
                        },
                        borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isTablet ? 32 : 24,
                            vertical: isTablet ? 16 : 14,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [_primaryRed, _deepRed],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
                            boxShadow: [
                              BoxShadow(
                                color: _primaryRed.withOpacity(0.3),
                                blurRadius: 15,
                                offset: Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Text(
                            'Clear All Filters',
                            style: GoogleFonts.inter(
                              fontSize: isTablet ? 18 : 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final serviceProvider = filteredProviders[index];
              return _buildServiceProviderCard(serviceProvider, context, isTablet);
            },
            childCount: filteredProviders.length,
          ),
        );
      },
    );
  }
}

// Separate widget for dialog content to manage state better
class _AddServiceDialogContent extends StatefulWidget {
  final Color primaryRed;
  final Color primaryGreen;
  final Color darkGreen;
  final Color deepRed;
  final Color bgGradient1;
  final Color bgGradient2;
  final Color borderColor;
  final Color textWhite;
  final Color textMuted;
  final Color textLight;
  final Color offWhite;
  final Color successGreen;
  final Color warningOrange;
  final Color infoBlue;
  final Color lightGreen;
  final Color goldAccent;
  final bool isTablet;

  const _AddServiceDialogContent({
    required this.primaryRed,
    required this.primaryGreen,
    required this.darkGreen,
    required this.deepRed,
    required this.bgGradient1,
    required this.bgGradient2,
    required this.borderColor,
    required this.textWhite,
    required this.textMuted,
    required this.textLight,
    required this.offWhite,
    required this.successGreen,
    required this.warningOrange,
    required this.infoBlue,
    required this.lightGreen,
    required this.goldAccent,
    required this.isTablet,
  });

  @override
  __AddServiceDialogContentState createState() => __AddServiceDialogContentState();
}

class __AddServiceDialogContentState extends State<_AddServiceDialogContent> {
  // Form controllers
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _websiteController = TextEditingController();
  final TextEditingController _businessHoursController = TextEditingController();
  final TextEditingController _yearsOfExperienceController = TextEditingController();
  final TextEditingController _licenseNumberController = TextEditingController();
  final TextEditingController _specialtiesController = TextEditingController();
  final TextEditingController _consultationFeeController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Dropdown values
  String? _selectedState;
  ServiceCategory? _selectedCategory;
  String? _selectedServiceProvider;
  String? _selectedSubServiceProvider;

  // Image
  XFile? _selectedImage;
  String? _base64Image;
  bool _isImageLoading = false;
  bool _isSaving = false;

  // Multi-select values
  List<String> _languagesSpoken = ['English'];
  List<String> _serviceTags = [];
  List<String> _serviceAreas = [];

  // Other fields
  List<String> _availableServiceProviders = [];
  List<String> _availableSubServiceProviders = [];
  bool _isAvailable = true;
  bool _acceptsInsurance = false;
  List<String> _acceptedPaymentMethods = ['Cash'];

  @override
  void initState() {
    super.initState();
    _selectedState = CommunityStates.states.first;
  }

  void _updateServiceProviders() {
    if (_selectedCategory == null) {
      setState(() {
        _availableServiceProviders = [];
        _selectedServiceProvider = null;
        _availableSubServiceProviders = [];
        _selectedSubServiceProvider = null;
      });
      return;
    }

    setState(() {
      _availableServiceProviders = _selectedCategory!.serviceProviders;
      _selectedServiceProvider = null;
      _updateSubServiceProviders();
    });
  }

  void _updateSubServiceProviders() {
    if (_selectedCategory == null || _selectedServiceProvider == null) {
      setState(() {
        _availableSubServiceProviders = [];
        _selectedSubServiceProvider = null;
      });
      return;
    }

    final subProviders = _selectedCategory!.subServiceProviders[_selectedServiceProvider!];
    
    setState(() {
      _availableSubServiceProviders = subProviders ?? [];
      _selectedSubServiceProvider = null;
    });
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _selectedImage = image;
          _isImageLoading = true;
        });
        
        final bytes = await File(image.path).readAsBytes();
        final base64String = base64Encode(bytes);
        
        final mimeType = _getMimeType(image.path);
        final dataUrl = 'data:$mimeType;base64,$base64String';
        
        setState(() {
          _base64Image = dataUrl;
          _isImageLoading = false;
        });
        
        print('✅ Image converted to base64, length: ${dataUrl.length}');
      }
    } catch (e) {
      setState(() {
        _isImageLoading = false;
      });
      print('❌ Error picking image: $e');
      _showPremiumSnackBar('Error picking image: $e', widget.primaryRed);
    }
  }

  String _getMimeType(String filePath) {
    final extension = filePath.split('.').last.toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'bmp':
        return 'image/bmp';
      default:
        return 'image/jpeg';
    }
  }

  void _showPremiumSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color, color.withOpacity(0.8)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                color == widget.primaryGreen ? Icons.check_circle_rounded : Icons.error_rounded,
                color: Colors.white,
                size: 24,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        duration: Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(20),
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildPremiumTextField({
    required TextEditingController controller,
    required String labelText,
    required IconData prefixIcon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    bool isRequired = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(widget.isTablet ? 16 : 12),
        border: Border.all(color: widget.borderColor, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isRequired)
            Padding(
              padding: EdgeInsets.only(left: widget.isTablet ? 24 : 20, top: widget.isTablet ? 16 : 12),
              child: Text(
                '* Required',
                style: GoogleFonts.inter(
                  fontSize: widget.isTablet ? 12 : 10,
                  color: widget.primaryRed,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            style: TextStyle(
              color: widget.textWhite,
              fontSize: widget.isTablet ? 18 : 16,
            ),
            decoration: InputDecoration(
              labelText: labelText + (isRequired ? ' *' : ''),
              labelStyle: TextStyle(
                color: widget.textMuted,
                fontSize: widget.isTablet ? 16 : 14,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(widget.isTablet ? 24 : 20),
              prefixIcon: Container(
                width: widget.isTablet ? 24 : 20,
                height: widget.isTablet ? 24 : 20,
                alignment: Alignment.center,
                child: Icon(
                  prefixIcon,
                  color: widget.primaryRed,
                  size: widget.isTablet ? 24 : 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumDropdownSection({
    required String title,
    required Widget child,
    required IconData icon,
    bool isRequired = false,
    String? hintText,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: widget.isTablet ? 24 : 16,
        vertical: widget.isTablet ? 20 : 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(widget.isTablet ? 16 : 12),
        border: Border.all(color: widget.borderColor, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isRequired)
            Padding(
              padding: EdgeInsets.only(bottom: widget.isTablet ? 8 : 6),
              child: Text(
                '* Required',
                style: GoogleFonts.inter(
                  fontSize: widget.isTablet ? 12 : 10,
                  color: widget.primaryRed,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          Row(
            children: [
              Container(
                width: widget.isTablet ? 48 : 40,
                height: widget.isTablet ? 48 : 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [widget.primaryRed.withOpacity(0.2), widget.primaryGreen.withOpacity(0.2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(widget.isTablet ? 12 : 10),
                ),
                child: Center(
                  child: Icon(
                    icon,
                    color: widget.primaryRed,
                    size: widget.isTablet ? 24 : 20,
                  ),
                ),
              ),
              SizedBox(width: widget.isTablet ? 20 : 16),
              Expanded(child: child),
            ],
          ),
          if (hintText != null)
            Padding(
              padding: EdgeInsets.only(top: widget.isTablet ? 12 : 8, left: widget.isTablet ? 68 : 56),
              child: Text(
                hintText,
                style: GoogleFonts.inter(
                  fontSize: widget.isTablet ? 12 : 10,
                  color: widget.textMuted,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(
        top: widget.isTablet ? 32 : 24,
        bottom: widget.isTablet ? 20 : 16,
      ),
      child: Row(
        children: [
          Container(
            height: widget.isTablet ? 4 : 3,
            width: widget.isTablet ? 40 : 30,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [widget.primaryRed, widget.primaryGreen],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
      //    SizedBox(width: widget.isTablet ? 16 : 12),
            SizedBox(width: widget.isTablet ? 12 : 8),
          Text(
            title, overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
           //   fontSize: widget.isTablet ? 22 : 18,
               fontSize: widget.isTablet ? 20 : 15,
              fontWeight: FontWeight.w800,
              color: widget.textWhite,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _createService() async {
    // Get current user from Firebase Auth
    final currentUser = _auth.currentUser;

    // Validation
    if (_selectedState == null) {
      _showPremiumSnackBar('Please select a state', widget.primaryRed);
      return;
    }

    if (_selectedCategory == null) {
      _showPremiumSnackBar('Please select a service category', widget.primaryRed);
      return;
    }

    if (_selectedServiceProvider == null) {
      _showPremiumSnackBar('Please select a service provider', widget.primaryRed);
      return;
    }

    if (_fullNameController.text.isEmpty) {
      _showPremiumSnackBar('Please enter full name', widget.primaryRed);
      return;
    }

    if (_phoneController.text.isEmpty) {
      _showPremiumSnackBar('Please enter phone number', widget.primaryRed);
      return;
    }

    if (_emailController.text.isEmpty) {
      _showPremiumSnackBar('Please enter email address', widget.primaryRed);
      return;
    }

    if (_addressController.text.isEmpty) {
      _showPremiumSnackBar('Please enter address', widget.primaryRed);
      return;
    }

    if (_cityController.text.isEmpty) {
      _showPremiumSnackBar('Please enter city', widget.primaryRed);
      return;
    }

    setState(() => _isSaving = true);

    try {
      final providerProvider = Provider.of<ServiceProviderProvider>(context, listen: false);
      
      final serviceProvider = ServiceProviderModel(
        fullName: _fullNameController.text.trim(),
        companyName: _companyNameController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        address: _addressController.text.trim(),
        state: _selectedState!,
        city: _cityController.text.trim(),
        serviceCategory: _selectedCategory!,
        serviceProvider: _selectedServiceProvider!,
        subServiceProvider: _selectedSubServiceProvider,
        profileImageBase64: _base64Image,
        description: _descriptionController.text.trim(),
        website: _websiteController.text.trim(),
        businessHours: _businessHoursController.text.trim(),
        yearsOfExperience: _yearsOfExperienceController.text.trim(),
        languagesSpoken: _languagesSpoken,
        serviceTags: _serviceTags,
        serviceAreas: _serviceAreas,
        isVerified: true,
        isAvailable: _isAvailable,
        isDeleted: false,
        createdBy: currentUser != null ? currentUser.uid : '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        licenseNumber: _licenseNumberController.text.trim(),
        specialties: _specialtiesController.text.trim(),
        consultationFee: double.tryParse(_consultationFeeController.text.trim()),
        acceptsInsurance: _acceptsInsurance,
        acceptedPaymentMethods: _acceptedPaymentMethods,
      );

      final success = await providerProvider.addServiceProvider(serviceProvider);
      
      if (success) {
        _showPremiumSnackBar('Service added successfully!', widget.primaryGreen);
        Navigator.pop(context);
        _clearForm();
      } else {
        _showPremiumSnackBar('Failed to add service', widget.primaryRed);
      }
    } catch (e) {
      _showPremiumSnackBar('Error: $e', widget.primaryRed);
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _clearForm() {
    _fullNameController.clear();
    _companyNameController.clear();
    _phoneController.clear();
    _emailController.clear();
    _addressController.clear();
    _cityController.clear();
    _descriptionController.clear();
    _websiteController.clear();
    _businessHoursController.clear();
    _yearsOfExperienceController.clear();
    _licenseNumberController.clear();
    _specialtiesController.clear();
    _consultationFeeController.clear();
    
    setState(() {
      _selectedState = CommunityStates.states.first;
      _selectedCategory = null;
      _selectedServiceProvider = null;
      _selectedSubServiceProvider = null;
      _selectedImage = null;
      _base64Image = null;
      _languagesSpoken = ['English'];
      _serviceTags = [];
      _serviceAreas = [];
      _isAvailable = true;
      _acceptsInsurance = false;
      _acceptedPaymentMethods = ['Cash'];
      _availableServiceProviders = [];
      _availableSubServiceProviders = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(widget.isTablet ? 32 : 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Premium Header
          Row(
            children: [
              Container(
                width: widget.isTablet ? 60 : 48,
                height: widget.isTablet ? 60 : 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [widget.primaryRed, widget.primaryGreen],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(widget.isTablet ? 16 : 12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.add_circle_rounded,
                  color: Colors.white,
                  size: widget.isTablet ? 32 : 28,
                ),
              ),
              SizedBox(width: widget.isTablet ? 20 : 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Add New Service',
                      style: GoogleFonts.poppins(
                        fontSize: widget.isTablet ? 28 : 22,
                        fontWeight: FontWeight.w800,
                        color: widget.textWhite,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Register a new service provider',
                      style: GoogleFonts.inter(
                        fontSize: widget.isTablet ? 16 : 14,
                        color: widget.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: widget.isTablet ? 28 : 24),

          // Form Fields
          SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Location Information Section
                _buildSectionTitle('Location Information'),
                
                // State Dropdown with hint
                _buildPremiumDropdownSection(
                  title: 'State *',
                  icon: Icons.location_on_rounded,
                  isRequired: true,
                  hintText: 'Select the state where service is provided',
                  child: DropdownButton<String>(
                    value: _selectedState,
                    isExpanded: true,
                    dropdownColor: widget.bgGradient2,
                    style: TextStyle(
                      color: widget.textWhite,
                      fontSize: widget.isTablet ? 18 : 16,
                      fontWeight: FontWeight.w500,
                    ),
                    underline: SizedBox(),
                    icon: Icon(
                      Icons.arrow_drop_down_rounded,
                      color: widget.textMuted,
                      size: widget.isTablet ? 32 : 28,
                    ),
                    items: CommunityStates.states.map((state) {
                      return DropdownMenuItem<String>(
                        value: state,
                        child: Text(state),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedState = value;
                      });
                    },
                    hint: Text(
                      'Select State',
                      style: TextStyle(
                        color: widget.textMuted,
                        fontSize: widget.isTablet ? 18 : 16,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: widget.isTablet ? 20 : 16),

                // City Text Field
                _buildPremiumTextField(
                  controller: _cityController,
                  labelText: 'City',
                  prefixIcon: Icons.location_city_rounded,
                  isRequired: true,
                ),
                SizedBox(height: widget.isTablet ? 20 : 16),

                // Service Information Section
                _buildSectionTitle('Service Information'),
                
                // Service Category Dropdown with hint
                _buildPremiumDropdownSection(
                  title: 'Service Category *',
                  icon: Icons.category_rounded,
                  isRequired: true,
                  hintText: 'Choose the main service category',
             
                

                child : DropdownButton<ServiceCategory>(
  value: _selectedCategory,
  isExpanded: true,
  dropdownColor: widget.bgGradient2,
  underline: const SizedBox(),

  icon: Icon(
    Icons.arrow_drop_down_rounded,
    color: widget.textMuted,
    size: widget.isTablet ? 32 : 28,
  ),

  // ✅ FIX #1: Selected value (closed dropdown)
  selectedItemBuilder: (context) {
    return ServiceCategory.values.map((category) {
      return Row(
        children: [
          Icon(
            category.icon,
            color: widget.primaryRed,
            size: widget.isTablet ? 22 : 18,
          ),
          SizedBox(width: widget.isTablet ? 16 : 12),

          // 🔥 THIS prevents overflow
          Expanded(
            child: Text(
              category.displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: widget.textWhite,
                fontSize: widget.isTablet ? 18 : 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      );
    }).toList();
  },

  // ✅ FIX #2: Dropdown menu items
  items: ServiceCategory.values.map((category) {
    return DropdownMenuItem<ServiceCategory>(
      value: category,
      child: Row(
        children: [
          Icon(
            category.icon,
            color: widget.primaryRed,
            size: widget.isTablet ? 22 : 18,
          ),
          SizedBox(width: widget.isTablet ? 16 : 12),

          // 🔥 SAME fix here
          Expanded(
            child: Text(
              category.displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }).toList(),

  onChanged: (value) {
    setState(() {
      _selectedCategory = value;
      _updateServiceProviders();
    });
  },

  hint: Text(
    'Select Category',
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    style: TextStyle(
      color: widget.textMuted,
      fontSize: widget.isTablet ? 18 : 16,
    ),
  ),
)

                
                ),
                SizedBox(height: widget.isTablet ? 20 : 16),

                // Service Provider Dropdown (if category selected)
                if (_selectedCategory != null)
                  Column(
                    children: [
                      _buildPremiumDropdownSection(
                        title: 'Service Provider *',
                        icon: Icons.work_rounded,
                        isRequired: true,
                        hintText: 'Select the specific service provider type',
                 
   child : DropdownButton<String>(
  value: _selectedServiceProvider,
  isExpanded: true,
  dropdownColor: widget.bgGradient2,
  underline: const SizedBox(),

  style: TextStyle(
    color: widget.textWhite,
    fontSize: widget.isTablet ? 18 : 16,
    fontWeight: FontWeight.w500,
  ),

  icon: Icon(
    Icons.arrow_drop_down_rounded,
    color: widget.textMuted,
    size: widget.isTablet ? 32 : 28,
  ),

  // ✅ FIX #1: selected value overflow
  selectedItemBuilder: (context) {
    return _availableServiceProviders.map((provider) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Text(
          provider,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: widget.textWhite,
            fontSize: widget.isTablet ? 18 : 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }).toList();
  },

  // ✅ FIX #2: dropdown list items overflow
  items: _availableServiceProviders.map((provider) {
    return DropdownMenuItem<String>(
      value: provider,
      child: Text(
        provider,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }).toList(),

  onChanged: (value) {
    setState(() {
      _selectedServiceProvider = value;
      _updateSubServiceProviders();
    });
  },

  hint: Text(
    'Select Service Provider',
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    style: TextStyle(
      color: widget.textMuted,
      fontSize: widget.isTablet ? 18 : 16,
    ),
  ),
)


                      ),
                      SizedBox(height: widget.isTablet ? 20 : 16),
                    ],
                  ),

                // Sub-Service Provider Dropdown (if available)
                if (_selectedServiceProvider != null && _availableSubServiceProviders.isNotEmpty)
                  Column(
                    children: [
                      _buildPremiumDropdownSection(
                        title: 'Sub-Service Provider',
                        icon: Icons.work_outline_rounded,
                        hintText: 'Optional: Choose sub-category if applicable',
                  

 child : DropdownButton<String?>(
  value: _selectedSubServiceProvider,
  isExpanded: true,
  dropdownColor: widget.bgGradient2,
  underline: const SizedBox(),

  style: TextStyle(
    color: widget.textWhite,
    fontSize: widget.isTablet ? 18 : 16,
    fontWeight: FontWeight.w500,
  ),

  icon: Icon(
    Icons.arrow_drop_down_rounded,
    color: widget.textMuted,
    size: widget.isTablet ? 32 : 28,
  ),

  // ✅ FIX #1: selected value overflow (including null)
  selectedItemBuilder: (context) {
    return [
      // null option
      Align(
        alignment: Alignment.centerLeft,
        child: Text(
          'Select Sub-Service Provider (Optional)',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: widget.textMuted,
            fontSize: widget.isTablet ? 18 : 16,
          ),
        ),
      ),

      // actual providers
      ..._availableSubServiceProviders.map((provider) {
        return Align(
          alignment: Alignment.centerLeft,
          child: Text(
            provider,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: widget.textWhite,
              fontSize: widget.isTablet ? 18 : 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      }),
    ];
  },

  // ✅ FIX #2: dropdown menu items overflow
  items: [
    DropdownMenuItem<String?>(
      value: null,
      child: Text(
        'Select Sub-Service Provider (Optional)',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    ),
    ..._availableSubServiceProviders.map((provider) {
      return DropdownMenuItem<String?>(
        value: provider,
        child: Text(
          provider,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      );
    }),
  ],

  onChanged: (value) {
    setState(() {
      _selectedSubServiceProvider = value;
    });
  },
)


                      ),


                      SizedBox(height: widget.isTablet ? 20 : 16),
                    ],
                  ),

                // Profile Image Section
                _buildSectionTitle('Profile Image'),
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    padding: EdgeInsets.all(widget.isTablet ? 24 : 20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(widget.isTablet ? 16 : 12),
                      border: Border.all(
                        color: _selectedImage != null ? widget.primaryGreen : widget.borderColor,
                        width: _selectedImage != null ? 2.5 : 1.5,
                      ),
                    ),
                    child: Column(
                      children: [
                        if (_selectedImage != null)
                          Column(
                            children: [
                              Container(
                                height: widget.isTablet ? 160 : 120,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(widget.isTablet ? 12 : 8),
                                  image: DecorationImage(
                                    image: FileImage(File(_selectedImage!.path)),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              SizedBox(height: widget.isTablet ? 20 : 16),
                            ],
                          ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: widget.isTablet ? 60 : 50,
                              height: widget.isTablet ? 60 : 50,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: _selectedImage != null
                                    ? [widget.primaryGreen, widget.darkGreen]
                                    : [widget.primaryRed, widget.deepRed],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(widget.isTablet ? 15 : 12),
                                boxShadow: [
                                  BoxShadow(
                                    color: (_selectedImage != null ? widget.primaryGreen : widget.primaryRed).withOpacity(0.3),
                                    blurRadius: 10,
                                    offset: Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Icon(
                                  _selectedImage != null ? Icons.image_rounded : Icons.add_photo_alternate_rounded,
                                  color: Colors.white,
                                  size: widget.isTablet ? 30 : 24,
                                ),
                              ),
                            ),
                            SizedBox(width: widget.isTablet ? 20 : 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _selectedImage != null ? 'Profile Image Selected' : 'Upload Profile Image',
                                    style: TextStyle(
                                      color: _selectedImage != null ? widget.primaryGreen : widget.textWhite,
                                      fontSize: widget.isTablet ? 20 : 18,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    _selectedImage != null ? 'Tap to change image' : 'Recommended headshot photo (Optional)',
                                    style: TextStyle(
                                      color: widget.textMuted,
                                      fontSize: widget.isTablet ? 16 : 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (_isImageLoading)
                          Padding(
                            padding: EdgeInsets.only(top: widget.isTablet ? 20 : 16),
                            child: CircularProgressIndicator(
                              color: widget.primaryGreen,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: widget.isTablet ? 32 : 24),

                // Service Provider Details Section
                _buildSectionTitle('Service Provider Details'),
                
                // Full Name
                _buildPremiumTextField(
                  controller: _fullNameController,
                  labelText: 'Full Name',
                  prefixIcon: Icons.person_rounded,
                  isRequired: true,
                ),
                SizedBox(height: widget.isTablet ? 20 : 16),

                // Company Name
                _buildPremiumTextField(
                  controller: _companyNameController,
                  labelText: 'Company Name',
                  prefixIcon: Icons.business_rounded,
                ),
                SizedBox(height: widget.isTablet ? 20 : 16),

                // Phone
                _buildPremiumTextField(
                  controller: _phoneController,
                  labelText: 'Phone',
                  prefixIcon: Icons.phone_rounded,
                  keyboardType: TextInputType.phone,
                  isRequired: true,
                ),
                SizedBox(height: widget.isTablet ? 20 : 16),

                // Email
                _buildPremiumTextField(
                  controller: _emailController,
                  labelText: 'Email',
                  prefixIcon: Icons.email_rounded,
                  keyboardType: TextInputType.emailAddress,
                  isRequired: true,
                ),
                SizedBox(height: widget.isTablet ? 20 : 16),

                // Address
                _buildPremiumTextField(
                  controller: _addressController,
                  labelText: 'Address',
                  prefixIcon: Icons.home_rounded,
                  maxLines: 2,
                  isRequired: true,
                ),
                SizedBox(height: widget.isTablet ? 20 : 16),

                // Description
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(widget.isTablet ? 16 : 12),
                    border: Border.all(color: widget.borderColor, width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(left: widget.isTablet ? 24 : 20, top: widget.isTablet ? 16 : 12),
                        child: Text(
                          'Describe your services',
                          style: GoogleFonts.inter(
                            fontSize: widget.isTablet ? 12 : 10,
                            color: widget.textMuted,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 4,
                        style: TextStyle(
                          color: widget.textWhite,
                          fontSize: widget.isTablet ? 18 : 16,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Description',
                          labelStyle: TextStyle(
                            color: widget.textMuted,
                            fontSize: widget.isTablet ? 16 : 14,
                          ),
                          alignLabelWithHint: true,
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.all(widget.isTablet ? 24 : 20),
                          prefixIcon: Padding(
                            padding: EdgeInsets.only(top: 20),
                            child: Icon(
                              Icons.description_rounded,
                              color: widget.primaryRed,
                              size: widget.isTablet ? 28 : 24,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: widget.isTablet ? 32 : 24),

                // Professional Information Section
                _buildSectionTitle('Professional Information'),
                
                // Website
                _buildPremiumTextField(
                  controller: _websiteController,
                  labelText: 'Website',
                  prefixIcon: Icons.language_rounded,
                  keyboardType: TextInputType.url,
                ),
                SizedBox(height: widget.isTablet ? 20 : 16),

                // Business Hours
                _buildPremiumTextField(
                  controller: _businessHoursController,
                  labelText: 'Business Hours',
                  prefixIcon: Icons.access_time_rounded,
                ),
                SizedBox(height: widget.isTablet ? 20 : 16),

                // Years of Experience
                _buildPremiumTextField(
                  controller: _yearsOfExperienceController,
                  labelText: 'Years of Experience',
                  prefixIcon: Icons.timeline_rounded,
                ),
                SizedBox(height: widget.isTablet ? 20 : 16),

                // License Number
                _buildPremiumTextField(
                  controller: _licenseNumberController,
                  labelText: 'License Number',
                  prefixIcon: Icons.badge_rounded,
                ),
                SizedBox(height: widget.isTablet ? 20 : 16),

                // Specialties
                _buildPremiumTextField(
                  controller: _specialtiesController,
                  labelText: 'Specialties',
                  prefixIcon: Icons.star_rounded,
                  maxLines: 2,
                ),
                SizedBox(height: widget.isTablet ? 20 : 16),

                // Consultation Fee
                _buildPremiumTextField(
                  controller: _consultationFeeController,
                  labelText: 'Consultation Fee (\$)',
                  prefixIcon: Icons.attach_money_rounded,
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: widget.isTablet ? 32 : 24),

                // Availability Section
                _buildSectionTitle('Service Settings'),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _isAvailable = !_isAvailable;
                      });
                    },
                    borderRadius: BorderRadius.circular(widget.isTablet ? 16 : 12),
                    child: Container(
                      padding: EdgeInsets.all(widget.isTablet ? 20 : 16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(widget.isTablet ? 16 : 12),
                        border: Border.all(
                          color: _isAvailable ? widget.primaryGreen : widget.borderColor,
                          width: _isAvailable ? 2 : 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: widget.isTablet ? 30 : 24,
                            height: widget.isTablet ? 30 : 24,
                            decoration: BoxDecoration(
                              color: _isAvailable ? widget.primaryGreen : Colors.transparent,
                              borderRadius: BorderRadius.circular(widget.isTablet ? 8 : 6),
                              border: Border.all(
                                color: _isAvailable ? widget.primaryGreen : Colors.grey,
                                width: 2,
                              ),
                            ),
                            child: _isAvailable
                                ? Icon(
                                    Icons.check_rounded,
                                    color: Colors.white,
                                    size: widget.isTablet ? 20 : 16,
                                  )
                                : null,
                          ),
                          SizedBox(width: widget.isTablet ? 20 : 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Available for Service',
                                  style: TextStyle(
                                    color: widget.textWhite,
                                    fontSize: widget.isTablet ? 20 : 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Service will be immediately available to users',
                                  style: TextStyle(
                                    color: widget.textMuted,
                                    fontSize: widget.isTablet ? 16 : 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: widget.isTablet ? 32 : 24),

                // Premium Info Card
                Container(
                  padding: EdgeInsets.all(widget.isTablet ? 24 : 20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [widget.primaryRed.withOpacity(0.1), widget.primaryGreen.withOpacity(0.1)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(widget.isTablet ? 20 : 16),
                    border: Border.all(color: widget.borderColor, width: 1.5),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: widget.isTablet ? 50 : 40,
                        height: widget.isTablet ? 50 : 40,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [widget.primaryRed, widget.primaryGreen],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Icon(
                            Icons.info_rounded,
                            color: Colors.white,
                            size: widget.isTablet ? 24 : 20,
                          ),
                        ),
                      ),
                      SizedBox(width: widget.isTablet ? 20 : 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Important Notes',
                              style: TextStyle(
                                color: widget.textWhite,
                                fontSize: widget.isTablet ? 18 : 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              '• All fields marked with * are required\n'
                              '• Service will be immediately available\n'
                              '• Profile can be edited later\n'
                              '• Verification status can be changed',
                              style: TextStyle(
                                color: widget.textMuted,
                                fontSize: widget.isTablet ? 14 : 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: widget.isTablet ? 32 : 28),

                // Premium Buttons
                Row(
                  children: [
                    Expanded(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            _clearForm();
                            Navigator.pop(context);
                          },
                          borderRadius: BorderRadius.circular(widget.isTablet ? 16 : 12),
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: widget.isTablet ? 22 : 18),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(widget.isTablet ? 16 : 12),
                              border: Border.all(color: widget.borderColor, width: 1.5),
                            ),
                            child: Center(
                              child: Text(
                                'Cancel',
                                style: TextStyle(
                                  color: widget.textMuted,
                                  fontWeight: FontWeight.w800,
                                  fontSize: widget.isTablet ? 20 : 18,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: widget.isTablet ? 20 : 16),
                    Expanded(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _isSaving ? null : _createService,
                          borderRadius: BorderRadius.circular(widget.isTablet ? 16 : 12),
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: widget.isTablet ? 22 : 18),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [widget.primaryGreen, widget.darkGreen],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(widget.isTablet ? 16 : 12),
                              boxShadow: [
                                BoxShadow(
                                  color: widget.primaryGreen.withOpacity(0.4),
                                  blurRadius: 15,
                                  offset: Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Center(
                              child: _isSaving
                                  ? SizedBox(
                                      width: widget.isTablet ? 30 : 24,
                                      height: widget.isTablet ? 30 : 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 3,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                   
                                        Text(
                                          'Add Service',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w800,
                                            fontSize: widget.isTablet ? 20 : 18,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: widget.isTablet ? 16 : 12),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _companyNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _descriptionController.dispose();
    _websiteController.dispose();
    _businessHoursController.dispose();
    _yearsOfExperienceController.dispose();
    _licenseNumberController.dispose();
    _specialtiesController.dispose();
    _consultationFeeController.dispose();
    super.dispose();
  }
}