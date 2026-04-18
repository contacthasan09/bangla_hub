// services/cloudinary_service.dart - Updated with better error handling

import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';

class CloudinaryService {
  static const String cloudName = 'divm0reuj';
  static const String uploadPreset = 'bangla_hub';
  static const String profileFolder = 'profile_images';
  static const String eventFolder = 'event_banners';
  
  // Upload profile image (for registration and profile updates)
  static Future<String?> uploadProfileImage(File imageFile, {String? customFolder}) async {
    print('📸 Starting profile image upload...');
    print('📸 Cloud name: $cloudName');
    print('📸 Upload preset: $uploadPreset');
    return await _uploadToCloudinary(imageFile, customFolder ?? profileFolder);
  }
  
  // Keep uploadImage as alias for backward compatibility
  static Future<String?> uploadImage(File imageFile, {String? customFolder}) async {
    return await uploadProfileImage(imageFile, customFolder: customFolder);
  }
  
  // Upload event banner image
  static Future<String?> uploadEventBanner(File imageFile, String eventId) async {
    final customFolder = '$eventFolder/$eventId';
    return await _uploadToCloudinary(imageFile, customFolder);
  }
  
  static Future<String?> _uploadToCloudinary(File imageFile, String folderPath) async {
    File? compressedFile;
    
    try {
      print('📸 Uploading to Cloudinary...');
      print('📁 Folder: $folderPath');
      
      // Check if file exists
      if (!await imageFile.exists()) {
        print('❌ File does not exist at path: ${imageFile.path}');
        return null;
      }
      
      print('📸 File exists, size: ${await imageFile.length()} bytes');
      
      // Compress image
      compressedFile = await _compressImage(imageFile);
      final compressedSize = await compressedFile.length();
      print('📸 Compressed size: ${compressedSize ~/ 1024}KB');
      
      // Create request
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload'),
      );
      
      // Add file
      final multipartFile = await http.MultipartFile.fromPath('file', compressedFile.path);
      request.files.add(multipartFile);
      
      // Add upload preset and folder
      request.fields['upload_preset'] = uploadPreset;
      request.fields['folder'] = folderPath;
      request.fields['quality'] = 'auto:good';
      request.fields['fetch_format'] = 'auto';
      
      print('📸 Request fields: ${request.fields}');
      print('📸 Sending request to Cloudinary...');
      
      // Send with timeout
      final response = await request.send().timeout(const Duration(seconds: 30));
      
      // Read response
      final responseData = await response.stream.bytesToString();
      print('📸 Response status code: ${response.statusCode}');
      print('📸 Response body: $responseData');
      
      if (response.statusCode != 200) {
        print('❌ Upload failed with status: ${response.statusCode}');
        print('❌ Response: $responseData');
        
        // Try to parse error message
        try {
          final errorJson = json.decode(responseData);
          final errorMessage = errorJson['error']['message'];
          print('❌ Cloudinary error: $errorMessage');
        } catch (_) {}
        
        return null;
      }
      
      final jsonData = json.decode(responseData);
      final imageUrl = jsonData['secure_url'];
      print('✅ Upload success!');
      print('✅ Image URL: $imageUrl');
      
      return imageUrl;
      
    } catch (e) {
      print('❌ Upload error: $e');
      print('❌ Error type: ${e.runtimeType}');
      return null;
    } finally {
      // Clean up temp file
      try {
        if (compressedFile != null && await compressedFile.exists()) {
          await compressedFile.delete();
          print('🧹 Temp file deleted: ${compressedFile.path}');
        }
      } catch (_) {}
    }
  }
  
  static Future<File> _compressImage(File file) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final targetPath = "${tempDir.path}/img_${DateTime.now().millisecondsSinceEpoch}.jpg";
      
      final originalSize = await file.length();
      int quality = 75;
      
      // Adjust quality based on original size
      if (originalSize > 5 * 1024 * 1024) {
        quality = 55;
      } else if (originalSize > 2 * 1024 * 1024) {
        quality = 65;
      } else if (originalSize > 1 * 1024 * 1024) {
        quality = 75;
      }
      
      print('📸 Original size: ${originalSize ~/ 1024}KB');
      print('📸 Compressing with quality: $quality');
      
      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: quality,
        minWidth: 800,
        minHeight: 400,
        format: CompressFormat.jpeg,
      );
      
      if (result != null) {
        final compressedSize = await File(result.path).length();
        print('📸 Compression successful: ${originalSize ~/ 1024}KB -> ${compressedSize ~/ 1024}KB');
        return File(result.path);
      }
      
      print('⚠️ Compression failed, using original file');
      return file;
    } catch (e) {
      print('❌ Compression error: $e');
      return file;
    }
  }
  
  static String sanitizeEmailForFolder(String email) {
    final bytes = utf8.encode(email.trim().toLowerCase());
    final digest = md5.convert(bytes);
    return digest.toString().substring(0, 8);
  }
  
  // Helper to get optimized URL for different sizes
  static String getOptimizedUrl(String url, {int width = 800, int height = 400, String crop = 'fill'}) {
    try {
      final uri = Uri.parse(url);
      final pathParts = uri.path.split('/');
      
      final uploadIndex = pathParts.indexOf('upload');
      if (uploadIndex != -1 && uploadIndex + 1 < pathParts.length) {
        pathParts.insert(uploadIndex + 1, 'w_$width,h_$height,c_$crop,q_auto,f_auto');
        final transformedPath = pathParts.join('/');
        return uri.replace(path: transformedPath).toString();
      }
      
      return url;
    } catch (e) {
      print('Error optimizing URL: $e');
      return url;
    }
  }
  
  static String getThumbnailUrl(String url) {
    return getOptimizedUrl(url, width: 200, height: 150, crop: 'thumb');
  }
  
  static String getCardUrl(String url) {
    return getOptimizedUrl(url, width: 400, height: 250, crop: 'fill');
  }
  
  static String getFullQualityUrl(String url) {
    return getOptimizedUrl(url, width: 1200, height: 600, crop: 'limit');
  }
}