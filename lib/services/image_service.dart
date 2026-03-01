import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ImageService {
  static final ImagePicker _picker = ImagePicker();

  static Future<String?> convertImageToBase64(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      return base64Encode(bytes);
    } catch (e) {
      print('Error converting image to base64: $e');
      return null;
    }
  }

  static Future<String?> convertImageFileToBase64(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final base64String = base64Encode(bytes);
      return 'data:image/jpeg;base64,$base64String';
    } catch (e) {
      print('Error converting image file: $e');
      return null;
    }
  }

  static ImageProvider getImageProvider(String? base64String) {
    if (base64String == null || base64String.isEmpty) {
      return const AssetImage('assets/images/placeholder_profile.png');
    }

    // Remove data URL prefix if present
    String cleanBase64 = base64String;
    if (base64String.contains(',')) {
      cleanBase64 = base64String.split(',')[1];
    }

    try {
      final bytes = base64Decode(cleanBase64);
      return MemoryImage(bytes);
    } catch (e) {
      print('Error decoding base64 image: $e');
      return const AssetImage('assets/images/placeholder_profile.png');
    }
  }

  static Future<File?> pickImage({
    ImageSource source = ImageSource.gallery,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
  }) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        imageQuality: imageQuality,
      );

      if (pickedFile != null) {
        return File(pickedFile.path);
      }
      return null;
    } catch (e) {
      print('Error picking image: $e');
      return null;
    }
  }

  static Future<Uint8List?> compressImage(File imageFile) async {
    try {
      // You can add image compression logic here
      // For now, just return the original bytes
      return await imageFile.readAsBytes();
    } catch (e) {
      print('Error compressing image: $e');
      return null;
    }
  }

  static String? getImageExtension(String base64String) {
    if (base64String.startsWith('data:image/')) {
      final parts = base64String.split(';');
      if (parts.isNotEmpty) {
        final mimeType = parts[0];
        return mimeType.split('/')[1];
      }
    }
    return 'jpg'; // default extension
  }

  static bool isValidBase64Image(String? base64String) {
    if (base64String == null || base64String.isEmpty) {
      return false;
    }

    try {
      String cleanBase64 = base64String;
      if (base64String.contains(',')) {
        cleanBase64 = base64String.split(',')[1];
      }

      base64Decode(cleanBase64);
      return true;
    } catch (e) {
      return false;
    }
  }
}