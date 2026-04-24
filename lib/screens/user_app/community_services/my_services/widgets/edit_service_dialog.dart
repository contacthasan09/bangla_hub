// lib/screens/user_app/community_services/my_services/widgets/edit_service_dialog.dart
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:bangla_hub/models/community_services_models.dart';
import 'package:bangla_hub/providers/auth_provider.dart';
import 'package:bangla_hub/providers/service_provider_provider.dart';
import 'package:bangla_hub/widgets/common/osm_location_picker.dart';

class EditServiceDialog extends StatefulWidget {
  final ServiceProviderModel service;
  final VoidCallback onUpdate;

  const EditServiceDialog({
    Key? key,
    required this.service,
    required this.onUpdate,
  }) : super(key: key);

  @override
  State<EditServiceDialog> createState() => _EditServiceDialogState();
}

class _EditServiceDialogState extends State<EditServiceDialog> {
  final _formKey = GlobalKey<FormState>();
  
  // Basic Controllers
  late TextEditingController _fullNameController;
  late TextEditingController _companyNameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  late TextEditingController _cityController;
  late TextEditingController _descriptionController;

  // Location
  double? _latitude;
  double? _longitude;
  String? _fullAddress;
  String? _selectedState;

  // Selected values
  ServiceCategory? _selectedCategory;
  String? _selectedServiceProvider;
  String? _selectedSubServiceProvider;

  // Image
  File? _profileImage;
  String? _profileImageBase64;
  bool _isImageProcessing = false;

  bool _isLoading = false;

  final Color _primaryGreen = const Color(0xFF006A4E);
  final Color _primaryRed = const Color(0xFFF42A41);
  final Color _goldAccent = const Color(0xFFFFD700);
  final Color _lightGreen = const Color(0xFFE8F5E9);
  final Color _warningYellow = const Color(0xFFFFC107);
  final Color _infoBlue = const Color(0xFF2196F3);

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _initializeValues();
  }

  void _initializeControllers() {
    _fullNameController = TextEditingController(text: widget.service.fullName);
    _companyNameController = TextEditingController(text: widget.service.companyName);
    _phoneController = TextEditingController(text: widget.service.phone);
    _emailController = TextEditingController(text: widget.service.email ?? '');
    _addressController = TextEditingController(text: widget.service.address);
    _cityController = TextEditingController(text: widget.service.city);
    
    // Set description with pending review message if it's a suggested service
    String descriptionText = widget.service.description ?? '';
    if (!widget.service.isVerified && descriptionText.isEmpty) {
      descriptionText = '📝 Suggested by user - pending admin review';
    } else if (!widget.service.isVerified && !descriptionText.contains('pending review')) {
      descriptionText = '📝 $descriptionText\n\n⏳ Pending admin review - Service will be visible after verification';
    }
    _descriptionController = TextEditingController(text: descriptionText);
  }

  void _initializeValues() {
    _selectedCategory = widget.service.serviceCategory;
    _selectedServiceProvider = widget.service.serviceProvider;
    _selectedSubServiceProvider = widget.service.subServiceProvider;
    _latitude = widget.service.latitude;
    _longitude = widget.service.longitude;
    _fullAddress = widget.service.address;
    _selectedState = widget.service.state;
    _profileImageBase64 = widget.service.profileImageBase64;
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _companyNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // Helper method to decode base64 image safely
  Uint8List _decodeBase64Image(String? base64String) {
    if (base64String == null || base64String.isEmpty) {
      return Uint8List(0);
    }
    
    String cleaned = base64String.trim();
    
    // Remove data URL prefix if present (e.g., "data:image/jpeg;base64,")
    if (cleaned.contains(',')) {
      cleaned = cleaned.split(',').last;
    }
    
    // Remove any whitespace
    cleaned = cleaned.replaceAll(RegExp(r'\s'), '');
    
    // Fix padding if needed
    if (cleaned.length % 4 != 0) {
      cleaned = cleaned.padRight(cleaned.length + (4 - cleaned.length % 4), '=');
    }
    
    try {
      return base64Decode(cleaned);
    } catch (e) {
      print('Error decoding base64: $e');
      return Uint8List(0);
    }
  }

  // Helper method to remove duplicate dropdown items
  List<DropdownMenuItem<T>> _getUniqueDropdownItems<T>(List<DropdownMenuItem<T>> items) {
    final seenValues = <T>{};
    final uniqueItems = <DropdownMenuItem<T>>[];
    
    for (var item in items) {
      final itemValue = item.value;
      
      if (itemValue == null) {
        bool hasNull = false;
        for (var existingItem in uniqueItems) {
          if (existingItem.value == null) {
            hasNull = true;
            break;
          }
        }
        if (!hasNull) {
          uniqueItems.add(item);
        }
      } else {
        if (!seenValues.contains(itemValue)) {
          seenValues.add(itemValue);
          uniqueItems.add(item);
        }
      }
    }
    return uniqueItems;
  }

  Future<void> _pickProfileImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery, 
        maxWidth: 800, 
        maxHeight: 800,
        imageQuality: 70,
      );
      
      if (pickedFile != null) {
        setState(() => _isImageProcessing = true);
        
        final bytes = await File(pickedFile.path).readAsBytes();
        final base64String = base64Encode(bytes);
        
        setState(() {
          _profileImage = File(pickedFile.path);
          _profileImageBase64 = base64String; // Store pure base64 without prefix
          _isImageProcessing = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile image updated'), backgroundColor: Color(0xFF006A4E)),
        );
      }
    } catch (e) {
      setState(() => _isImageProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  Widget _buildLocationPickerField() {
    return GestureDetector(
      onTap: () async {
        await showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => GoogleMapsLocationPicker(
            initialLatitude: _latitude,
            initialLongitude: _longitude,
            initialAddress: _fullAddress,
            initialState: _selectedState,
            initialCity: _cityController.text,
            onLocationSelected: (lat, lng, address, state, city) {
              setState(() {
                _latitude = lat;
                _longitude = lng;
                _fullAddress = address;
                _selectedState = state;
                _addressController.text = address;
                if (city != null && city.isNotEmpty) _cityController.text = city;
              });
            },
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(10),
          color: _latitude != null ? _lightGreen : null,
        ),
        child: Row(
          children: [
            Icon(Icons.map_rounded, color: _primaryGreen, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Location *', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: _primaryGreen)),
                  const SizedBox(height: 2),
                  Text(
                    _fullAddress ?? 'Tap to select location',
                    style: GoogleFonts.inter(fontSize: 13, color: Colors.black87),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Profile Image', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13, color: _primaryGreen)),
        const SizedBox(height: 6),
        Center(
          child: GestureDetector(
            onTap: _isImageProcessing ? null : _pickProfileImage,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: _primaryGreen, width: 2),
                color: _lightGreen,
                boxShadow: [BoxShadow(color: _primaryGreen.withOpacity(0.2), blurRadius: 6)],
              ),
              child: _isImageProcessing
                  ? const Center(child: CircularProgressIndicator())
                  : _profileImageBase64 != null && _profileImageBase64!.isNotEmpty
                      ? ClipOval(
                          child: Image.memory(
                            _decodeBase64Image(_profileImageBase64),
                            fit: BoxFit.cover,
                            width: 100,
                            height: 100,
                            errorBuilder: (context, error, stackTrace) => 
                                Icon(Icons.person, size: 40, color: _primaryGreen),
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate_rounded, size: 32, color: _primaryGreen),
                            const SizedBox(height: 4),
                            Text('Add Photo', style: GoogleFonts.poppins(color: _primaryGreen, fontSize: 11)),
                          ],
                        ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPendingReviewNotice() {
    if (widget.service.isVerified) return const SizedBox.shrink();
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _warningYellow.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _warningYellow.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: _warningYellow.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.pending_actions, color: _warningYellow, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '⏳ Pending Admin Review',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: _warningYellow,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'This service is waiting for admin verification. It will be visible to users once approved.',
                  style: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminContactInfo() {
    if (widget.service.isVerified) return const SizedBox.shrink();
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _infoBlue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _infoBlue.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _infoBlue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.contact_support, color: _infoBlue, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '📞 Admin Will Contact You',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: _infoBlue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'To complete the verification process, our admin team may contact you for:',
            style: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.check_circle_outline, size: 12, color: _infoBlue),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Business license verification',
                  style: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.check_circle_outline, size: 12, color: _infoBlue),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Service quality confirmation',
                  style: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.check_circle_outline, size: 12, color: _infoBlue),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Additional service details if needed',
                  style: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _infoBlue.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.email, size: 14, color: _primaryGreen),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'For urgent inquiries, contact: info@banglahub.us',
                    style: GoogleFonts.inter(fontSize: 10, color: Colors.grey.shade600),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, 
      {TextInputType keyboardType = TextInputType.text, int maxLines = 1, bool isRequired = true}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: GoogleFonts.inter(fontSize: 13, color: Colors.black87),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade700),
        prefixIcon: Icon(icon, color: _primaryGreen, size: 18),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10), 
          borderSide: BorderSide(color: _primaryGreen, width: 1.5)
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: maxLines > 1 ? 12 : 10),
        filled: true,
        fillColor: Colors.white,
      ),
      validator: isRequired ? (value) => value == null || value.isEmpty ? 'Required' : null : null,
    );
  }

  Widget _buildReadOnlyField(String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300), 
        borderRadius: BorderRadius.circular(10), 
        color: Colors.grey.shade50
      ),
      child: Row(
        children: [
          Icon(icon, color: _primaryGreen, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value, 
              style: GoogleFonts.inter(fontSize: 13, color: Colors.black87),
            ),
          ),
          Icon(Icons.lock_outline_rounded, size: 14, color: Colors.grey.shade400),
        ],
      ),
    );
  }

  Widget _buildNonEditableDescription() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(10),
        color: Colors.grey.shade50,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.description_rounded, color: _primaryGreen, size: 18),
              const SizedBox(width: 8),
              Text(
                'Description',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 12, color: _primaryGreen),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _warningYellow.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Not Editable',
                  style: GoogleFonts.inter(fontSize: 9, color: _warningYellow),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _descriptionController.text,
            style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade700, height: 1.4),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.info_outline, size: 14, color: _infoBlue),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'This service is pending admin review. Description cannot be edited until verification is complete.',
                  style: GoogleFonts.inter(fontSize: 10, color: _infoBlue),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown<T>({
    required T? value,
    required String label,
    required IconData icon,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
  }) {
    final uniqueItems = _getUniqueDropdownItems(items);
    final valueExists = value == null || uniqueItems.any((item) => item.value == value);
    
    return DropdownButtonFormField<T>(
      value: valueExists ? value : null,
      isExpanded: true,
      style: GoogleFonts.inter(fontSize: 13, color: Colors.black87),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade700),
        prefixIcon: Icon(icon, color: _primaryGreen, size: 18),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10), 
          borderSide: BorderSide(color: _primaryGreen, width: 1.5)
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        filled: true,
        fillColor: Colors.white,
      ),
      items: uniqueItems,
      onChanged: onChanged,
      validator: (value) => value == null && label.contains('*') ? 'Required' : null,
      dropdownColor: Colors.white,
      icon: Icon(Icons.arrow_drop_down, color: _primaryGreen, size: 20),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width >= 600;
    
    return Dialog(
      insetPadding: EdgeInsets.symmetric(horizontal: isTablet ? 40 : 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: isTablet ? 650 : double.infinity,
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF006A4E), Color(0xFFF42A41)]),
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8), 
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2), 
                      borderRadius: BorderRadius.circular(10)
                    ), 
                    child: Icon(Icons.edit_rounded, color: _goldAccent, size: 20)
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text('Edit Service', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white))),
                  IconButton(
                    onPressed: () => Navigator.pop(context), 
                    icon: Icon(Icons.close_rounded, color: Colors.white, size: 20)
                  ),
                ],
              ),
            ),
            
            // Form
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildProfileImageSection(),
                      const SizedBox(height: 16),
                      _buildPendingReviewNotice(),
                      _buildAdminContactInfo(),
                      _buildTextField(_fullNameController, 'Full Name *', Icons.person_rounded),
                      const SizedBox(height: 10),
                      _buildTextField(_companyNameController, 'Company Name *', Icons.business_rounded),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(child: _buildTextField(_phoneController, 'Enter a valid US number *', Icons.phone_rounded, keyboardType: TextInputType.phone)),
                          const SizedBox(width: 10),
                          Expanded(child: _buildTextField(_emailController, 'Email (Optional)', Icons.email_rounded, keyboardType: TextInputType.emailAddress, isRequired: false)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _buildLocationPickerField(),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(child: _buildReadOnlyField(_cityController.text.isEmpty ? 'Not set' : _cityController.text, Icons.location_city_rounded)),
                          const SizedBox(width: 10),
                          Expanded(child: _buildReadOnlyField(_selectedState ?? 'Not set', Icons.map_rounded)),
                        ],
                      ),
                      const SizedBox(height: 14),
                      
                      // Category Dropdown
                      _buildDropdown<ServiceCategory>(
                        value: _selectedCategory,
                        label: 'Category *',
                        icon: Icons.category_rounded,
                        items: ServiceCategory.values.map((category) => 
                          DropdownMenuItem(
                            value: category, 
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(category.icon, color: _primaryRed, size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    category.displayName,
                                    style: GoogleFonts.inter(fontSize: 13, color: Colors.black87),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedCategory = value;
                            _selectedServiceProvider = null;
                            _selectedSubServiceProvider = null;
                          });
                        },
                      ),
                      const SizedBox(height: 10),
                      
                      // Service Provider Dropdown
                      if (_selectedCategory != null)
                        _buildDropdown<String?>(
                          value: _selectedServiceProvider,
                          label: 'Service Type *',
                          icon: Icons.work_rounded,
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null, 
                              child: Text('Select Service Type', style: TextStyle(fontSize: 13, color: Colors.black87)),
                            ),
                            ..._selectedCategory!.serviceProviders.map((provider) => 
                              DropdownMenuItem(
                                value: provider, 
                                child: Text(
                                  provider, 
                                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedServiceProvider = value;
                              _selectedSubServiceProvider = null;
                            });
                          },
                        ),
                      const SizedBox(height: 10),
                      
                      // Sub Service Provider Dropdown
                      if (_selectedServiceProvider != null && _selectedCategory != null && 
                          _selectedCategory!.subServiceProviders[_selectedServiceProvider!]?.isNotEmpty == true)
                        _buildDropdown<String?>(
                          value: _selectedSubServiceProvider,
                          label: 'Sub Service Type',
                          icon: Icons.subdirectory_arrow_right_rounded,
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null, 
                              child: Text('Select Sub Service Type', style: TextStyle(fontSize: 13, color: Colors.black87)),
                            ),
                            ..._selectedCategory!.subServiceProviders[_selectedServiceProvider!]!.map((sub) => 
                              DropdownMenuItem(
                                value: sub, 
                                child: Text(
                                  sub, 
                                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                          onChanged: (value) => setState(() => _selectedSubServiceProvider = value),
                        ),
                      const SizedBox(height: 10),
                      
                      // Non-editable Description for pending services
                      !widget.service.isVerified 
                        ? _buildNonEditableDescription()
                        : _buildTextField(_descriptionController, 'Description', Icons.description_rounded, maxLines: 3, isRequired: false),
                    ],
                  ),
                ),
              ),
            ),
            
            // Actions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.grey.shade200))),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10), 
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                      ),
                      child: Text('Cancel', style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade700)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveChanges,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryGreen, 
                        padding: const EdgeInsets.symmetric(vertical: 10), 
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                      ),
                      child: _isLoading 
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) 
                        : Text('Save Changes', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a category')));
      return;
    }
    
    if (_selectedServiceProvider == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a service type')));
      return;
    }
    
    if (_latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a location on the map')));
      return;
    }

    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.user;
    if (currentUser == null) {
      setState(() => _isLoading = false);
      return;
    }

    // Handle email - convert empty string to null
    final String? email = _emailController.text.trim().isEmpty 
        ? null 
        : _emailController.text.trim();

    final updatedService = widget.service.copyWith(
      fullName: _fullNameController.text.trim(),
      companyName: _companyNameController.text.trim(),
      phone: _phoneController.text.trim(),
      email: email, // ✅ Pass nullable email
      address: _fullAddress ?? _addressController.text.trim(),
      state: _selectedState ?? '',
      city: _cityController.text.trim(),
      serviceCategory: _selectedCategory!,
      serviceProvider: _selectedServiceProvider!,
      subServiceProvider: _selectedSubServiceProvider,
      profileImageBase64: _profileImageBase64,
      // Only update description if service is verified (editable)
      description: widget.service.isVerified 
          ? (_descriptionController.text.isNotEmpty ? _descriptionController.text : null)
          : widget.service.description, // Keep original description for unverified services
      latitude: _latitude,
      longitude: _longitude,
      updatedAt: DateTime.now(),
    );

    final provider = Provider.of<ServiceProviderProvider>(context, listen: false);
    final success = await provider.updateUserService(widget.service.id!, updatedService);

    setState(() => _isLoading = false);

    if (success && mounted) {
      Navigator.pop(context);
      widget.onUpdate();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Service updated successfully'), backgroundColor: Color(0xFF006A4E))
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update service'), backgroundColor: Colors.red)
      );
    }
  }
}