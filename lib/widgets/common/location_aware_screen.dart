// widgets/common/location_aware_screen.dart
import 'package:bangla_hub/widgets/common/global_location_guard.dart';
import 'package:flutter/material.dart';

class LocationAwareScreen extends StatelessWidget {
  final Widget child;
  final bool requireLocation;
  
  const LocationAwareScreen({
    Key? key,
    required this.child,
    this.requireLocation = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LocationGuard(
      required: requireLocation,
      child: child,
    );
  }
}