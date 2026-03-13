// widgets/common/global_location_filter_bar.dart (Enhanced)
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
        if (!locationProvider.isFilterActive) {
          return const SizedBox.shrink();
        }

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
                      SnackBar(
                        content: const Text('Location filter cleared'),
                        backgroundColor: const Color(0xFF006A4E),
                        behavior: SnackBarBehavior.floating,
                        margin: const EdgeInsets.all(16),
                        duration: const Duration(seconds: 2),
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
      },
    );
  }
}