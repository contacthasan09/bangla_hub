// widgets/common/global_location_filter_bar.dart (Enhanced - Ready for Location Guard)
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/location_filter_provider.dart';

class GlobalLocationFilterBar extends StatelessWidget {
  final bool isTablet;
  final VoidCallback? onClearTap;

  const GlobalLocationFilterBar({
    Key? key,
    required this.isTablet,
    this.onClearTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<LocationFilterProvider>(
      builder: (context, locationProvider, _) {
        // ✅ If no state is selected, show a prompt to select state
        if (!locationProvider.isFilterActive && !locationProvider.isStateSelected) {
          return _buildStateSelectionPrompt(context);
        }
        
        // ✅ If filter is active, show the filter bar
        if (locationProvider.isFilterActive && locationProvider.isStateSelected) {
          return _buildActiveFilterBar(context, locationProvider);
        }
        
        // Default: show nothing
        return const SizedBox.shrink();
      },
    );
  }
  
  // ✅ New: Show a prompt when no state is selected
  Widget _buildStateSelectionPrompt(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: EdgeInsets.symmetric(
        horizontal: isTablet ? 24 : 16,
        vertical: 8,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 16 : 12,
        vertical: isTablet ? 12 : 8,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF42A41), Color(0xFFD32F2F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF42A41).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          // This will trigger the location guard to show the selection dialog
          // The guard is already handling this, so just show a message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please select a state to continue'),
              backgroundColor: Color(0xFF006A4E),
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 2),
            ),
          );
        },
        borderRadius: BorderRadius.circular(30),
        child: Row(
          children: [
            // Animated location icon
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.8, end: 1.2),
              duration: const Duration(milliseconds: 1000),
              curve: Curves.easeInOut,
              builder: (context, scale, child) {
                return Transform.scale(
                  scale: scale,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.location_on_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(width: 12),
            
            // Prompt text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '📍 Location Required',
                    style: GoogleFonts.inter(
                      fontSize: isTablet ? 12 : 10,
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Tap to select your state',
                    style: GoogleFonts.poppins(
                      fontSize: isTablet ? 14 : 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            
            // Arrow indicator
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_forward_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // ✅ Existing active filter bar (your original code)
  Widget _buildActiveFilterBar(BuildContext context, LocationFilterProvider locationProvider) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: EdgeInsets.symmetric(
        horizontal: isTablet ? 24 : 16,
        vertical: 8,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 16 : 12,
        vertical: isTablet ? 12 : 8,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF006A4E), Color(0xFF004D38)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF006A4E).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          // Filter indicator with pulse animation
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.8, end: 1.2),
            duration: const Duration(milliseconds: 1000),
            curve: Curves.easeInOut,
            builder: (context, scale, child) {
              return Transform.scale(
                scale: scale,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.filter_alt_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 12),
          
          // Filter info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '📍 Showing results in:',
                  style: GoogleFonts.inter(
                    fontSize: isTablet ? 12 : 10,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
                Text(
                  locationProvider.selectedState!,
                  style: GoogleFonts.poppins(
                    fontSize: isTablet ? 16 : 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          
          // Clear button with hover effect
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                print('📍 Global filter bar clear button tapped');
                
                // Clear filter in provider
                locationProvider.clearLocationFilter();
                
                // Call the screen's custom clear handler if provided
                if (onClearTap != null) {
                  onClearTap!();
                }
                
                // Show feedback
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Location filter cleared'),
                    backgroundColor: Color(0xFF006A4E),
                    behavior: SnackBarBehavior.floating,
                    margin: EdgeInsets.all(16),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}