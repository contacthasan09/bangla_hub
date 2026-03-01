import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  Future<Position?> getCurrentPosition() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      // Get current position
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      print('Error getting location: $e');
      return null;
    }
  }

  Future<String?> getCityAndCountry() async {
    try {
      final position = await getCurrentPosition();
      if (position == null) return null;

      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        final city = placemark.locality ?? '';
        final country = placemark.country ?? '';
        
        if (city.isNotEmpty && country.isNotEmpty) {
          return '$city, $country';
        } else if (city.isNotEmpty) {
          return city;
        } else if (country.isNotEmpty) {
          return country;
        }
      }
      return null;
    } catch (e) {
      print('Error getting city/country: $e');
      return null;
    }
  }

  Future<Map<String, double>?> getCoordinatesFromAddress(String address) async {
    try {
      final locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        return {
          'latitude': locations.first.latitude,
          'longitude': locations.first.longitude,
        };
      }
      return null;
    } catch (e) {
      print('Error getting coordinates: $e');
      return null;
    }
  }
}