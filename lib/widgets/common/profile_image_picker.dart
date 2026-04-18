// widgets/common/profile_image_picker.dart

import 'package:bangla_hub/models/user_model.dart';
import 'package:bangla_hub/widgets/common/image_upload_service.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:bangla_hub/providers/auth_provider.dart';
import 'package:provider/provider.dart';

class ProfileImagePicker extends StatelessWidget {
  final double size;
  final VoidCallback? onImageUpdated;

  const ProfileImagePicker({
    Key? key,
    this.size = 80,
    this.onImageUpdated,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;
    
    // Listen to the ValueNotifier for real-time profile image updates
    return ValueListenableBuilder<String?>(
      valueListenable: authProvider.profileImageNotifier,
      builder: (context, profileImageUrl, child) {
        // Use the notifier value first, fallback to user's profileImageUrl
        final imageUrl = profileImageUrl ?? user?.profileImageUrl;
        
        return GestureDetector(
          onTap: () => _showImageSourceSheet(context),
          child: Stack(
            children: [
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey[300],
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: _buildImageContent(imageUrl),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: size * 0.3,
                  height: size * 0.3,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildImageContent(String? imageUrl) {
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        width: size,
        height: size,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                  : null,
              strokeWidth: 2,
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[300],
            child: const Icon(Icons.person, color: Colors.grey, size: 40),
          );
        },
      );
    }
    return Container(
      color: Colors.grey[300],
      child: const Icon(Icons.person, color: Colors.grey, size: 40),
    );
  }

  void _showImageSourceSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Update Profile Picture',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.green),
              title: const Text('Take a Photo'),
              onTap: () {
                Navigator.pop(context);
                ImageUploadService.uploadProfileImage(
                  ImageSource.camera,
                  onSuccess: () {
                    onImageUpdated?.call();
                  },
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.blue),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                ImageUploadService.uploadProfileImage(
                  ImageSource.gallery,
                  onSuccess: () {
                    onImageUpdated?.call();
                  },
                );
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}