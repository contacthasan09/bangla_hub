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

  // Premium Color Palette - Vibrant Colors
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
  final Color _textLight = const Color(0xFF6C757D);
  final Color _shadowColor = const Color(0x1A000000);
  
  // New Vibrant Colors
  final Color _vibrantOrange = const Color(0xFFFF6B35);
  final Color _vibrantPink = const Color(0xFFFF69B4);
  final Color _vibrantPurple = const Color(0xFF9D4EDD);
  final Color _vibrantTeal = const Color(0xFF00B4D8);
  final Color _vibrantYellow = const Color(0xFFFFD93D);
  final Color _vibrantRed = const Color(0xFFFF4757);
  final Color _vibrantMint = const Color(0xFF2ECC71);
  final Color _vibrantLavender = const Color(0xFFB980F0);
  final Color _vibrantPeach = const Color(0xFFFFA07A);
  final Color _vibrantAqua = const Color(0xFF00E5FF);

  const EventCard({
    Key? key,
    required this.event,
    required this.onTap,
    this.onEdit,
    this.onDelete,
    this.showActions = false,
  }) : super(key: key);

  // Get vibrant gradient based on event category
  LinearGradient _getCategoryGradient() {
    switch (event.category) {
      case 'sports':
        return LinearGradient(
          colors: [_vibrantTeal, _vibrantAqua, _emeraldGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: const [0.0, 0.5, 1.0],
        );
      case 'religious':
        return LinearGradient(
          colors: [_vibrantPurple, _vibrantLavender, _amethystPurple],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: const [0.0, 0.5, 1.0],
        );
      case 'business':
        return LinearGradient(
          colors: [_sapphireBlue, _vibrantTeal, _primaryGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: const [0.0, 0.5, 1.0],
        );
      case 'educational':
        return LinearGradient(
          colors: [_vibrantOrange, _vibrantYellow, _vibrantRed],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: const [0.0, 0.5, 1.0],
        );
      case 'social':
        return LinearGradient(
          colors: [_vibrantPink, _vibrantRed, _coralRed],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: const [0.0, 0.5, 1.0],
        );
      default:
        return LinearGradient(
          colors: [_primaryGreen, _emeraldGreen, _vibrantMint],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: const [0.0, 0.5, 1.0],
        );
    }
  }

  // Get vibrant color for status badges
  Color _getStatusGradientColor(bool isPending, bool isPast) {
    if (isPending) return _vibrantOrange;
    if (isPast) return _textLight;
    return _emeraldGreen;
  }

  // Get formatted date range with proper truncation
  String _getFormattedDateRange() {
    String dateRangeText = event.formattedDateRange;
    
    if (dateRangeText.length > 25) {
      final startFormat = DateFormat('MMM d').format(event.eventDate);
      if (event.endDate != null) {
        final endFormat = DateFormat('MMM d').format(event.endDate!);
        dateRangeText = '$startFormat - $endFormat';
      } else {
        dateRangeText = DateFormat('MMM d, yyyy').format(event.eventDate);
      }
    }
    return dateRangeText;
  }

  bool get _hasTimeInfo => event.startTime != null;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;
    final isSmallScreen = screenWidth < 380;
    final isPast = event.isPast;
    final isPending = event.isPending;
    
    final formattedDateRange = _getFormattedDateRange();
    final formattedTimeRange = event.formattedTimeRange;
    final statusColor = _getStatusGradientColor(isPending, isPast);

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isTablet ? 16 : (isSmallScreen ? 8 : 12),
        vertical: isTablet ? 12 : 8,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(isTablet ? 28 : 24),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(isTablet ? 28 : 24),
          splashColor: Colors.white.withOpacity(0.1),
          highlightColor: Colors.transparent,
          child: Stack(
            children: [
              // Main Card Container
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white,
                      _lightGreen,
                      Colors.white,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    stops: const [0.0, 0.3, 1.0],
                  ),
                  borderRadius: BorderRadius.circular(isTablet ? 28 : 24),
                  boxShadow: [
                    BoxShadow(
                      color: _getCategoryGradient().colors.first.withOpacity(0.25),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                      spreadRadius: -2,
                    ),
                    BoxShadow(
                      color: _shadowColor,
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left Section - Image with Badges
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(isTablet ? 28 : 24),
                            bottomLeft: Radius.circular(isTablet ? 28 : 24),
                          ),
                          child: Container(
                            width: isTablet ? 140 : (isSmallScreen ? 100 : 120),
                            height: isTablet ? 160 : (isSmallScreen ? 120 : 140),
                            child: event.bannerImageUrl != null && event.bannerImageUrl!.isNotEmpty
                                ? Image.network(
                                    event.bannerImageUrl!,
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
                                      return _buildImagePlaceholder(isTablet, isSmallScreen);
                                    },
                                  )
                                : _buildImagePlaceholder(isTablet, isSmallScreen),
                          ),
                        ),
                        
                        // Colorful Category Icon Badge
                        Positioned(
                          top: isTablet ? 12 : (isSmallScreen ? 8 : 10),
                          left: isTablet ? 12 : (isSmallScreen ? 8 : 10),
                          child: Container(
                            padding: EdgeInsets.all(isTablet ? 8 : (isSmallScreen ? 5 : 6)),
                            decoration: BoxDecoration(
                              gradient: _getCategoryGradient(),
                              borderRadius: BorderRadius.circular(isTablet ? 14 : (isSmallScreen ? 10 : 12)),
                              boxShadow: [
                                BoxShadow(
                                  color: _getCategoryGradient().colors.first.withOpacity(0.4),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Icon(
                              event.categoryIcon,
                              size: isTablet ? 18 : (isSmallScreen ? 12 : 14),
                              color: Colors.white,
                            ),
                          ),
                        ),
                        
                        // Colorful Status Badge
                        if (isPending || isPast)
                          Positioned(
                            bottom: isTablet ? 12 : (isSmallScreen ? 8 : 10),
                            left: isTablet ? 12 : (isSmallScreen ? 8 : 10),
                            right: isTablet ? 12 : (isSmallScreen ? 8 : 10),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: isTablet ? 10 : (isSmallScreen ? 6 : 8),
                                vertical: isTablet ? 6 : (isSmallScreen ? 3 : 4),
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    statusColor,
                                    statusColor.withOpacity(0.8),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(isTablet ? 12 : 10),
                                boxShadow: [
                                  BoxShadow(
                                    color: statusColor.withOpacity(0.4),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  isPending ? 'PENDING' : 'PAST',
                                  style: GoogleFonts.poppins(
                                    fontSize: isTablet ? 11 : (isSmallScreen ? 8 : 9),
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: 1,
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
                        padding: EdgeInsets.all(
                          isTablet ? 18 : (isSmallScreen ? 10 : 14)
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Colorful Date/Timestamp Badge
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: isTablet ? 10 : (isSmallScreen ? 6 : 8),
                                vertical: isTablet ? 6 : (isSmallScreen ? 3 : 4),
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    _goldAccent.withOpacity(0.15),
                                    _softGold.withOpacity(0.08),
                                    Colors.white,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(isTablet ? 14 : (isSmallScreen ? 10 : 12)),
                                border: Border.all(
                                  color: _goldAccent.withOpacity(0.3),
                                  width: 0.8,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.calendar_today_rounded,
                                          size: isTablet ? 14 : (isSmallScreen ? 10 : 12),
                                          color: _vibrantOrange,
                                        ),
                                        SizedBox(width: isTablet ? 6 : (isSmallScreen ? 3 : 4)),
                                        Flexible(
                                          child: Text(
                                            formattedDateRange,
                                            style: GoogleFonts.inter(
                                              fontSize: isTablet ? 12 : (isSmallScreen ? 9 : 10),
                                              fontWeight: FontWeight.w700,
                                              color: _vibrantOrange,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (_hasTimeInfo && formattedTimeRange.isNotEmpty && formattedTimeRange != 'Time TBA') ...[
                                    const SizedBox(height: 2),
                                    Flexible(
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.access_time_rounded,
                                            size: isTablet ? 12 : (isSmallScreen ? 9 : 10),
                                            color: _vibrantTeal,
                                          ),
                                          SizedBox(width: isTablet ? 5 : (isSmallScreen ? 3 : 4)),
                                          Flexible(
                                            child: Text(
                                              formattedTimeRange,
                                              style: GoogleFonts.inter(
                                                fontSize: isTablet ? 11 : (isSmallScreen ? 8 : 9),
                                                fontWeight: FontWeight.w600,
                                                color: _vibrantTeal,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            
                            SizedBox(height: isTablet ? 14 : (isSmallScreen ? 8 : 10)),
                            
                            // Event Title
                            Text(
                              event.title,
                              style: GoogleFonts.poppins(
                                fontSize: isTablet ? 18 : (isSmallScreen ? 13 : 16),
                                fontWeight: FontWeight.w800,
                                color: _textPrimary,
                                height: 1.2,
                                letterSpacing: -0.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            
                            SizedBox(height: isTablet ? 12 : (isSmallScreen ? 6 : 8)),
                            
                            // Colorful Location Row
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(isTablet ? 6 : (isSmallScreen ? 3 : 4)),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [_coralRed, _vibrantRed],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(isTablet ? 10 : (isSmallScreen ? 6 : 8)),
                                  ),
                                  child: Icon(
                                    Icons.location_on_rounded,
                                    size: isTablet ? 14 : (isSmallScreen ? 10 : 12),
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(width: isTablet ? 10 : (isSmallScreen ? 6 : 8)),
                                Expanded(
                                  child: Text(
                                    event.location,
                                    style: GoogleFonts.inter(
                                      fontSize: isTablet ? 14 : (isSmallScreen ? 10 : 12),
                                      fontWeight: FontWeight.w600,
                                      color: _coralRed,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            
                            SizedBox(height: isTablet ? 10 : (isSmallScreen ? 6 : 8)),
                            
                            // Colorful Organizer Row
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(isTablet ? 6 : (isSmallScreen ? 3 : 4)),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [_primaryGreen, _emeraldGreen],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(isTablet ? 10 : (isSmallScreen ? 6 : 8)),
                                  ),
                                  child: Icon(
                                    Icons.business_rounded,
                                    size: isTablet ? 14 : (isSmallScreen ? 10 : 12),
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(width: isTablet ? 10 : (isSmallScreen ? 6 : 8)),
                                Expanded(
                                  child: Text(
                                    event.organizer,
                                    style: GoogleFonts.inter(
                                      fontSize: isTablet ? 14 : (isSmallScreen ? 10 : 12),
                                      fontWeight: FontWeight.w600,
                                      color: _primaryGreen,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (!event.isFree)
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: isTablet ? 10 : (isSmallScreen ? 6 : 8),
                                      vertical: isTablet ? 5 : (isSmallScreen ? 3 : 4),
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [_goldAccent, _vibrantYellow, _vibrantOrange],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(isTablet ? 14 : (isSmallScreen ? 10 : 12)),
                                      boxShadow: [
                                        BoxShadow(
                                          color: _goldAccent.withOpacity(0.4),
                                          blurRadius: 8,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      'PAID',
                                      style: GoogleFonts.poppins(
                                        fontSize: isTablet ? 11 : (isSmallScreen ? 8 : 9),
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            
                            // Colorful Action Buttons
                            if (showActions) ...[
                              SizedBox(height: isTablet ? 16 : (isSmallScreen ? 10 : 12)),
                              Row(
                                children: [
                                  if (onEdit != null)
                                    Expanded(
                                      child: _buildColorfulActionButton(
                                        icon: Icons.edit_rounded,
                                        label: 'Edit',
                                        gradient: LinearGradient(
                                          colors: [_sapphireBlue, _vibrantTeal],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        isTablet: isTablet,
                                        isSmallScreen: isSmallScreen,
                                        onTap: onEdit!,
                                      ),
                                    ),
                                  if (onEdit != null && onDelete != null)
                                    SizedBox(width: isTablet ? 12 : (isSmallScreen ? 8 : 10)),
                                  if (onDelete != null)
                                    Expanded(
                                      child: _buildColorfulActionButton(
                                        icon: Icons.delete_rounded,
                                        label: 'Delete',
                                        gradient: LinearGradient(
                                          colors: [_vibrantRed, _coralRed],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        isTablet: isTablet,
                                        isSmallScreen: isSmallScreen,
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
              // Colorful Border Accent - FIXED: Use Positioned instead of Container with height: Infinity
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 6,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _getCategoryGradient().colors.first,
                        _getCategoryGradient().colors.last,
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(isTablet ? 28 : 24),
                      bottomRight: Radius.circular(isTablet ? 28 : 24),
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

  Widget _buildImagePlaceholder(bool isTablet, bool isSmallScreen) {
    return Container(
      width: isTablet ? 140 : (isSmallScreen ? 100 : 120),
      height: isTablet ? 160 : (isSmallScreen ? 120 : 140),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_primaryGreen, _darkGreen, _emeraldGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_rounded,
              size: isTablet ? 45 : (isSmallScreen ? 30 : 35),
              color: Colors.white.withOpacity(0.4),
            ),
            SizedBox(height: isTablet ? 8 : (isSmallScreen ? 4 : 6)),
            Text(
              'No Image',
              style: GoogleFonts.poppins(
                fontSize: isTablet ? 12 : (isSmallScreen ? 9 : 10),
                fontWeight: FontWeight.w500,
                color: Colors.white.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorfulActionButton({
    required IconData icon,
    required String label,
    required LinearGradient gradient,
    required VoidCallback onTap,
    required bool isTablet,
    required bool isSmallScreen,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: isTablet ? 10 : (isSmallScreen ? 6 : 8),
        ),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(isTablet ? 14 : (isSmallScreen ? 10 : 12)),
          boxShadow: [
            BoxShadow(
              color: gradient.colors.first.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: isTablet ? 18 : (isSmallScreen ? 12 : 14),
              color: Colors.white,
            ),
            SizedBox(width: isTablet ? 8 : (isSmallScreen ? 4 : 6)),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: isTablet ? 14 : (isSmallScreen ? 10 : 12),
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}