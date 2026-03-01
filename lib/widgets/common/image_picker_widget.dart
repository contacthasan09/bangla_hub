import 'dart:io';
import 'package:bangla_hub/constants/colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ImagePickerWidget extends StatelessWidget {
  final File? imageFile;
  final VoidCallback onImagePicked;
  final String label;
  final double size;

  const ImagePickerWidget({
    Key? key,
    this.imageFile,
    required this.onImagePicked,
    this.label = 'Add Image',
    this.size = 100,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onImagePicked,
          borderRadius: BorderRadius.circular(size / 2),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: AppColors.lightGray,
              borderRadius: BorderRadius.circular(size / 2),
              border: Border.all(
                color: AppColors.mediumGray,
                width: 2,
              ),
            ),
            child: imageFile != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(size / 2),
                    child: Image.file(
                      imageFile!,
                      width: size,
                      height: size,
                      fit: BoxFit.cover,
                    ),
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.camera_alt,
                          size: size * 0.3,
                          color: AppColors.textLight,
                        ),
                        SizedBox(height: size * 0.05),
                        Text(
                          'Add',
                          style: GoogleFonts.poppins(
                            fontSize: size * 0.1,
                            color: AppColors.textLight,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
        SizedBox(height: size * 0.1),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}