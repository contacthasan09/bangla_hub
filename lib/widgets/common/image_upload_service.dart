// services/image_upload_service.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:bangla_hub/main.dart';
import 'package:bangla_hub/services/cloudinary_service.dart';
import 'package:bangla_hub/providers/auth_provider.dart';
import 'package:provider/provider.dart';

class ImageUploadService {
  static bool _isUploading = false;
  
// services/image_upload_service.dart - Update to use silent update

static Future<bool> uploadProfileImage(
  ImageSource source, {
  VoidCallback? onSuccess,
  VoidCallback? onFailure,
}) async {
  if (_isUploading) {
    _showSnackBar('Upload already in progress...', Colors.orange);
    return false;
  }
  
  _isUploading = true;
  
  OverlayEntry? overlayEntry;
  final overlayState = navigatorKey.currentState?.overlay;
  
  if (overlayState != null) {
    overlayEntry = OverlayEntry(
      builder: (context) => const Material(
        color: Colors.black54,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 16),
              Text('Uploading image...', style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
      ),
    );
    overlayState.insert(overlayEntry);
  }
  
  try {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: source,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    
    if (pickedFile == null) {
      overlayEntry?.remove();
      _isUploading = false;
      return false;
    }
    
    final file = File(pickedFile.path);
    final authProvider = Provider.of<AuthProvider>(navigatorKey.currentContext!, listen: false);
    final currentUser = authProvider.user;
    
    if (currentUser == null) {
      overlayEntry?.remove();
      _isUploading = false;
      return false;
    }
    
    final userId = CloudinaryService.sanitizeEmailForFolder(currentUser.email);
    final imageUrl = await CloudinaryService.uploadProfileImage(
      file,
      customFolder: 'profile_images/$userId',
    );
    
    overlayEntry?.remove();
    
    if (imageUrl == null) {
      _isUploading = false;
      _showSnackBar('Upload failed. Please try again.', Colors.red);
      onFailure?.call();
      return false;
    }
    
    // Use the silent update method - NO FULL REBUILD
    await authProvider.updateProfileImageOnly(imageUrl);
    
    _isUploading = false;
    _showSnackBar('Profile picture updated successfully!', Colors.green);
    
    onSuccess?.call();
    return true;
    
  } catch (e) {
    print('Upload error: $e');
    overlayEntry?.remove();
    _isUploading = false;
    _showSnackBar('Upload failed: ${e.toString()}', Colors.red);
    onFailure?.call();
    return false;
  }
}




  static void _showSnackBar(String message, Color color) {
    final context = navigatorKey.currentContext;
    if (context != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}