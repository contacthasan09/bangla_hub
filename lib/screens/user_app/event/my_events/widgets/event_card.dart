// lib/widgets/event/event_card.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:bangla_hub/models/event_model.dart';

class EventCard extends StatelessWidget {
  final EventModel event;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool showActions;

  // Premium Color Palette
  final Color _primaryGreen = const Color(0xFF006A4E);
  final Color _darkGreen = const Color(0xFF004D38);
  final Color _goldAccent = const Color(0xFFFFD700);
  final Color _softGold = const Color(0xFFFFD966);
  final Color _lightGreen = const Color(0xFFE8F5E9);
  final Color _coralRed = const Color(0xFFFF6B6B);
  final Color _emeraldGreen = const Color(0xFF2ECC71);
  final Color _sapphireBlue = const Color(0xFF3498DB);
  final Color _amethystPurple = const Color(0xFF9B59B6);
  final Color _textPrimary = const Color(0xFF1A1A2E);
  final Color _textSecondary = const Color(0xFF4A4A4A);

  const EventCard({
    Key? key,
    required this.event,
    required this.onTap,
    this.onEdit,
    this.onDelete,
    this.showActions = false,
  }) : super(key: key);

  // Get gradient based on event category
  LinearGradient _getCategoryGradient() {
    switch (event.category) {
      case 'sports':
        return LinearGradient(
          colors: [_emeraldGreen, _primaryGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'religious':
        return LinearGradient(
          colors: [_amethystPurple, const Color(0xFF6C3483)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'business':
        return LinearGradient(
          colors: [_sapphireBlue, const Color(0xFF1A5276)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'educational':
        return LinearGradient(
          colors: [_emeraldGreen, const Color(0xFF1E8449)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'social':
        return LinearGradient(
          colors: [_coralRed, const Color(0xFFCB4335)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      default:
        return LinearGradient(
          colors: [_primaryGreen, _darkGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width >= 600;
    final isPast = event.isPast;
    final isPending = event.isPending;

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isTablet ? 16 : 12,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          // Primary shadow - deep and wide
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 25,
            offset: const Offset(0, 8),
            spreadRadius: -2,
          ),
          // Secondary shadow - colored accent
          BoxShadow(
            color: _primaryGreen.withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 6),
            spreadRadius: -3,
          ),
          // Tertiary shadow - for depth
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        elevation: 0,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          splashColor: _primaryGreen.withOpacity(0.15),
          highlightColor: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: _goldAccent.withOpacity(0.15),
                width: 0.5,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Section - Image with Badges
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(24),
                        bottomLeft: Radius.circular(24),
                      ),
                      child: SizedBox(
                        width: isTablet ? 130 : 110,
                        height: isTablet ? 150 : 130,
                        child: event.bannerImageUrl != null && event.bannerImageUrl!.isNotEmpty
                            ? Image.network(
                                event.thumbnailUrl,
                                fit: BoxFit.cover,
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Container(
                                    color: Colors.grey[100],
                                    child: Center(
                                      child: SizedBox(
                                        width: 25,
                                        height: 25,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(_goldAccent),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  return _buildImagePlaceholder(isTablet);
                                },
                              )
                            : _buildImagePlaceholder(isTablet),
                      ),
                    ),
                    
                    // Category Icon Badge
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          gradient: _getCategoryGradient(),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Icon(
                          event.categoryIcon,
                          size: isTablet ? 16 : 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    
                    // Status Badge
                    if (isPending || isPast)
                      Positioned(
                        bottom: 10,
                        left: 10,
                        right: 10,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isPending 
                                  ? [const Color(0xFFFF9800), const Color(0xFFF57C00)]
                                  : [Colors.grey[700]!, Colors.grey[900]!],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              isPending ? 'PENDING' : 'PAST',
                              style: GoogleFonts.poppins(
                                fontSize: isTablet ? 10 : 9,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                
                // Right Section - Content
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(isTablet ? 16 : 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Date Badge
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [_goldAccent.withOpacity(0.15), _softGold.withOpacity(0.08)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _goldAccent.withOpacity(0.3),
                              width: 0.5,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.calendar_today_rounded,
                                size: isTablet ? 12 : 10,
                                color: _goldAccent,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                event.formattedDateRange,
                                style: GoogleFonts.inter(
                                  fontSize: isTablet ? 11 : 10,
                                  fontWeight: FontWeight.w700,
                                  color: _goldAccent,
                                ),
                              ),
                              if (event.startTime != null) ...[
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.access_time_rounded,
                                  size: isTablet ? 10 : 9,
                                  color: _goldAccent,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  event.formattedTimeRange,
                                  style: GoogleFonts.inter(
                                    fontSize: isTablet ? 10 : 9,
                                    fontWeight: FontWeight.w600,
                                    color: _goldAccent,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 12),
                        
                        // Event Title
                        Text(
                          event.title,
                          style: GoogleFonts.poppins(
                            fontSize: isTablet ? 16 : 14,
                            fontWeight: FontWeight.w800,
                            color: _textPrimary,
                            height: 1.2,
                            letterSpacing: -0.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        
                        const SizedBox(height: 10),
                        
                        // Location
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: _coralRed.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.location_on_rounded,
                                size: isTablet ? 12 : 10,
                                color: _coralRed,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                event.location,
                                style: GoogleFonts.inter(
                                  fontSize: isTablet ? 12 : 11,
                                  fontWeight: FontWeight.w500,
                                  color: _textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 8),
                        
                        // Organizer
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: _primaryGreen.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.business_rounded,
                                size: isTablet ? 12 : 10,
                                color: _primaryGreen,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                event.organizer,
                                style: GoogleFonts.inter(
                                  fontSize: isTablet ? 12 : 11,
                                  fontWeight: FontWeight.w600,
                                  color: _primaryGreen,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (!event.isFree)
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [_goldAccent, _softGold],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _goldAccent.withOpacity(0.3),
                                      blurRadius: 4,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  'PAID',
                                  style: GoogleFonts.poppins(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        
                        // Action Buttons (if showActions is true)
                        if (showActions) ...[
                          const SizedBox(height: 14),
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
                                const SizedBox(width: 10),
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

  Widget _buildImagePlaceholder(bool isTablet) {
    return Container(
      width: isTablet ? 130 : 110,
      height: isTablet ? 150 : 130,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_primaryGreen, _darkGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.event_rounded,
          size: isTablet ? 35 : 28,
          color: Colors.white.withOpacity(0.3),
        ),
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
        padding: EdgeInsets.symmetric(vertical: isTablet ? 8 : 7),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.12), color.withOpacity(0.06)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.4), width: 1),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.15),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: isTablet ? 14 : 12, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: isTablet ? 12 : 11,
                fontWeight: FontWeight.w700,
                color: color,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}