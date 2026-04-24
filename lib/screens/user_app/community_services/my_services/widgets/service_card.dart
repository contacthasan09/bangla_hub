// lib/widgets/community_services/service_card.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bangla_hub/models/community_services_models.dart';

class ServiceCard extends StatelessWidget {
  final ServiceProviderModel service;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool showActions;

  final Color _primaryGreen = const Color(0xFF006A4E);
  final Color _darkGreen = const Color(0xFF004D38);
  final Color _goldAccent = const Color(0xFFFFD700);
  final Color _softGold = const Color(0xFFFFD966);
  final Color _coralRed = const Color(0xFFFF6B6B);
  final Color _textPrimary = const Color(0xFF1A1A2E);
  final Color _textSecondary = const Color(0xFF4A4A4A);

  const ServiceCard({
    Key? key,
    required this.service,
    required this.onTap,
    this.onEdit,
    this.onDelete,
    this.showActions = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width >= 600;
    final isPending = !service.isVerified;
    final isUnavailable = !service.isAvailable;

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
          BoxShadow(
            color: _primaryGreen.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 6),
            spreadRadius: -3,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          splashColor: _primaryGreen.withOpacity(0.1),
          highlightColor: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _goldAccent.withOpacity(0.15),
                width: 0.5,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Section - Image
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    bottomLeft: Radius.circular(20),
                  ),
                  child: Container(
                    width: isTablet ? 120 : 100,
                    height: isTablet ? 140 : 120,
                    color: _primaryGreen.withOpacity(0.1),
                    child: service.profileImageBase64 != null && service.profileImageBase64!.isNotEmpty
                        ? _buildProfileImage()
                        : Center(
                            child: Icon(
                              Icons.business_rounded,
                              size: isTablet ? 40 : 32,
                              color: _primaryGreen.withOpacity(0.3),
                            ),
                          ),
                  ),
                ),
                
                // Right Section - Content
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(isTablet ? 12 : 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Category Badge
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [_goldAccent.withOpacity(0.15), _softGold.withOpacity(0.08)],
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                service.serviceCategory.icon,
                                size: isTablet ? 10 : 8,
                                color: _goldAccent,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                service.serviceCategory.displayName,
                                style: GoogleFonts.inter(
                                  fontSize: isTablet ? 9 : 8,
                                  fontWeight: FontWeight.w600,
                                  color: _goldAccent,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 8),
                        
                        // Company Name
                   /*     Text(
                          service.companyName,
                          style: GoogleFonts.poppins(
                            fontSize: isTablet ? 15 : 13,
                            fontWeight: FontWeight.w700,
                            color: _textPrimary,
                            height: 1.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),  */

                        Text(
  service.companyName ?? 'Not Provided',
  style: GoogleFonts.poppins(
    fontSize: isTablet ? 15 : 13,
    fontWeight: FontWeight.w700,
    color: _textPrimary,
    height: 1.2,
  ),
  maxLines: 1,
  overflow: TextOverflow.ellipsis,
),
                        
                        const SizedBox(height: 4),
                        
                        // Service Provider Type
                        Text(
                          service.serviceProvider,
                          style: GoogleFonts.inter(
                            fontSize: isTablet ? 11 : 10,
                            fontWeight: FontWeight.w600,
                            color: _primaryGreen,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        
                        const SizedBox(height: 6),
                        
                        // Location
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_rounded,
                              size: isTablet ? 10 : 8,
                              color: _coralRed,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                '${service.city}, ${service.state}',
                                style: GoogleFonts.inter(
                                  fontSize: isTablet ? 10 : 9,
                                  fontWeight: FontWeight.w500,
                                  color: _textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        
                        // Status Badge
                        if (isPending || isUnavailable)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isPending ? Colors.orange.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                isPending ? 'Pending Approval' : 'Unavailable',
                                style: GoogleFonts.inter(
                                  fontSize: isTablet ? 9 : 8,
                                  fontWeight: FontWeight.w600,
                                  color: isPending ? Colors.orange[700] : Colors.red[700],
                                ),
                              ),
                            ),
                          ),
                        
                        // Action Buttons
                        if (showActions) ...[
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              if (onEdit != null)
                                Expanded(
                                  child: _buildActionButton(
                                    icon: Icons.edit_rounded,
                                    label: 'Edit',
                                    color: _primaryGreen,
                                    isTablet: isTablet,
                                    onTap: onEdit!,
                                  ),
                                ),
                              if (onEdit != null && onDelete != null)
                                const SizedBox(width: 8),
                              if (onDelete != null)
                                Expanded(
                                  child: _buildActionButton(
                                    icon: Icons.delete_rounded,
                                    label: 'Delete',
                                    color: const Color(0xFFE74C3C),
                                    isTablet: isTablet,
                                    onTap: onDelete!,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileImage() {
    return ClipRRect(
      child: Image.memory(
        base64Decode(service.cleanBase64String(service.profileImageBase64!)),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Center(
            child: Icon(
              Icons.business_rounded,
              size: 30,
              color: _primaryGreen.withOpacity(0.3),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    required bool isTablet,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: isTablet ? 6 : 5),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3), width: 0.8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: isTablet ? 12 : 10, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: isTablet ? 10 : 9,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}