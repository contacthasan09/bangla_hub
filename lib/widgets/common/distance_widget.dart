// widgets/distance_badge.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bangla_hub/providers/location_filter_provider.dart';

class DistanceBadge extends StatelessWidget {
  final double? latitude;
  final double? longitude;
  final bool isTablet;
  final Color? color;
  final EdgeInsets margin;

  const DistanceBadge({
    Key? key,
    required this.latitude,
    required this.longitude,
    required this.isTablet,
    this.color,
    this.margin = EdgeInsets.zero,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (latitude == null || longitude == null) {
      return const SizedBox.shrink();
    }

    return Consumer<LocationFilterProvider>(
      builder: (context, locationProvider, _) {
        if (locationProvider.currentUserLocation == null) {
          return const SizedBox.shrink();
        }

        final distance = locationProvider.getDistanceString(
          latitude!,
          longitude!,
        );
        
        if (distance == null) return const SizedBox.shrink();

        return Container(
          margin: margin,
          padding: EdgeInsets.symmetric(
            horizontal: isTablet ? 10 : 8,
            vertical: isTablet ? 6 : 4,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF006A4E).withOpacity(0.1),
                const Color(0xFFF42A41).withOpacity(0.05),
                const Color(0xFFFFD700).withOpacity(0.1),
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFFFD700).withOpacity(0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.near_me,
                color: color ?? const Color(0xFF006A4E),
                size: isTablet ? 14 : 12,
              ),
              const SizedBox(width: 4),
              Text(
                distance,
                style: GoogleFonts.poppins(
                  fontSize: isTablet ? 12 : 10,
                  fontWeight: FontWeight.w600,
                  color: color ?? const Color(0xFF006A4E),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}