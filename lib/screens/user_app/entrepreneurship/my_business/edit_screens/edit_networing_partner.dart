// lib/screens/user_app/entrepreneurship/networing_partner/edit_business_partner_dialog.dart
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:bangla_hub/models/community_services_models.dart';
import 'package:bangla_hub/widgets/common/osm_location_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:bangla_hub/models/entrepreneurship_models.dart';
import 'package:bangla_hub/providers/auth_provider.dart';
import 'package:bangla_hub/providers/entrepreneurship_provider.dart';

class EditNetworkingPartnerDialog extends StatefulWidget {
  final NetworkingBusinessPartner partner;
  final VoidCallback onUpdate;

  const EditNetworkingPartnerDialog({
    Key? key, 
    required this.partner,
    required this.onUpdate,
  }) : super(key: key);

  @override
  State<EditNetworkingPartnerDialog> createState() => _EditNetworkingPartnerDialogState();
}

class _EditNetworkingPartnerDialogState extends State<EditNetworkingPartnerDialog> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _businessNameController;
  late TextEditingController _ownerNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _cityController;
  late TextEditingController _descriptionController;
  late TextEditingController _industryController;
  late TextEditingController _yearsController;
  late TextEditingController _websiteController;
  late TextEditingController _serviceController;
  late TextEditingController _socialMediaController;
  
  BusinessType? _selectedBusinessType;
  List<String> _servicesOffered = [];
  List<String> _socialMediaLinks = [];
  
  // Image handling
  File? _logoImage;
  String? _logoBase64;
  bool _isImageProcessing = false;
  
  // Location
  double? _latitude;
  double? _longitude;
  String? _selectedState;
  String? _selectedCity;
  
  bool _isLoading = false;

  final Color _primaryGreen = const Color(0xFF006A4E);
  final Color _darkGreen = const Color(0xFF004D38);
  final Color _goldAccent = const Color(0xFFFFD700);
  final Color _lightGreen = const Color(0xFFE8F5E9);
  final Color _errorRed = const Color(0xFFE53935);

  @override
  void initState() {
    super.initState();
    _businessNameController = TextEditingController(text: widget.partner.businessName);
    _ownerNameController = TextEditingController(text: widget.partner.ownerName);
    _emailController = TextEditingController(text: widget.partner.email);
    _phoneController = TextEditingController(text: widget.partner.phone);
    _addressController = TextEditingController(text: widget.partner.address);
    _cityController = TextEditingController(text: widget.partner.city);
    _descriptionController = TextEditingController(text: widget.partner.description);
    _industryController = TextEditingController(text: widget.partner.industry);
    _yearsController = TextEditingController(text: widget.partner.yearsInBusiness.toString());
    _websiteController = TextEditingController(text: widget.partner.website ?? '');
    _serviceController = TextEditingController();
    _socialMediaController = TextEditingController();
    
    _selectedBusinessType = widget.partner.businessType;
    _servicesOffered = List.from(widget.partner.servicesOffered);
    _socialMediaLinks = List.from(widget.partner.socialMediaLinks ?? []);
    _latitude = widget.partner.latitude;
    _longitude = widget.partner.longitude;
    _selectedState = widget.partner.state;
    _selectedCity = widget.partner.city;
    _logoBase64 = widget.partner.logoImageBase64;
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _ownerNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _descriptionController.dispose();
    _industryController.dispose();
    _yearsController.dispose();
    _websiteController.dispose();
    _serviceController.dispose();
    _socialMediaController.dispose();
    super.dispose();
  }

  // Helper method to clean base64 string
  String _cleanBase64String(String base64) {
    String cleaned = base64.trim();
    
    if (cleaned.contains(',')) {
      cleaned = cleaned.split(',').last;
    }
    if (cleaned.contains('base64,')) {
      cleaned = cleaned.split('base64,').last;
    }
    
    cleaned = cleaned.replaceAll(RegExp(r'\s'), '');
    
    while (cleaned.length % 4 != 0) {
      cleaned += '=';
    }
    
    return cleaned;
  }

  // Helper to decode base64 safely
  Uint8List _decodeBase64Image(String? base64String) {
    if (base64String == null || base64String.isEmpty) {
      return Uint8List(0);
    }
    
    try {
      final cleaned = _cleanBase64String(base64String);
      return base64Decode(cleaned);
    } catch (e) {
      print('Error decoding base64: $e');
      return Uint8List(0);
    }
  }

  Future<void> _pickLogoImage() async {
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
          _logoImage = File(pickedFile.path);
          _logoBase64 = base64String;
          _isImageProcessing = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Logo updated'), backgroundColor: Color(0xFF006A4E), duration: Duration(seconds: 1)),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isImageProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Widget _buildLocationPickerField() {
    final isTablet = MediaQuery.of(context).size.width >= 600;
    
    return GestureDetector(
      onTap: () async {
        await showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => GoogleMapsLocationPicker(
            initialLatitude: _latitude,
            initialLongitude: _longitude,
            initialAddress: _addressController.text,
            initialState: _selectedState,
            initialCity: _cityController.text,
            onLocationSelected: (lat, lng, address, state, city) {
              if (mounted) {
                setState(() {
                  _latitude = lat;
                  _longitude = lng;
                  _selectedState = state;
                  _selectedCity = city;
                  _addressController.text = address;
                  if (city != null && city.isNotEmpty) _cityController.text = city;
                });
              }
            },
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.all(isTablet ? 16 : 14),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
          color: _latitude != null ? _lightGreen : null,
        ),
        child: Row(
          children: [
            Icon(Icons.map_rounded, color: _primaryGreen, size: isTablet ? 24 : 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Location *',
                    style: GoogleFonts.poppins(
                      fontSize: isTablet ? 13 : 12,
                      fontWeight: FontWeight.w600,
                      color: _primaryGreen,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _addressController.text.isEmpty 
                        ? 'Tap to select location on map' 
                        : _addressController.text,
                    style: GoogleFonts.inter(
                      fontSize: isTablet ? 15 : 14,
                      color: _addressController.text.isEmpty ? Colors.grey[500] : Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: isTablet ? 18 : 16, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoSection() {
    final isTablet = MediaQuery.of(context).size.width >= 600;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Business Logo',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: isTablet ? 15 : 14,
            color: _primaryGreen,
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: GestureDetector(
            onTap: _isImageProcessing ? null : _pickLogoImage,
            child: Container(
              width: isTablet ? 140 : 120,
              height: isTablet ? 140 : 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: _primaryGreen, width: 2),
                color: _lightGreen,
                boxShadow: [BoxShadow(color: _primaryGreen.withOpacity(0.2), blurRadius: 8)],
              ),
              child: _isImageProcessing
                  ? const Center(child: CircularProgressIndicator())
                  : _logoBase64 != null && _logoBase64!.isNotEmpty
                      ? ClipOval(
                          child: Image.memory(
                            _decodeBase64Image(_logoBase64),
                            fit: BoxFit.cover,
                            width: isTablet ? 140 : 120,
                            height: isTablet ? 140 : 120,
                            errorBuilder: (context, error, stackTrace) => Icon(
                              Icons.business,
                              size: isTablet ? 60 : 50,
                              color: _primaryGreen,
                            ),
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_photo_alternate_rounded,
                              size: isTablet ? 48 : 40,
                              color: _primaryGreen,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Add Logo',
                              style: GoogleFonts.poppins(
                                color: _primaryGreen,
                                fontSize: isTablet ? 14 : 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              '(Optional)',
                              style: GoogleFonts.inter(
                                fontSize: isTablet ? 11 : 10,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width >= 600;
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Dialog(
      insetPadding: EdgeInsets.symmetric(horizontal: isTablet ? 40 : 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        width: isTablet ? 800 : double.infinity,
        constraints: BoxConstraints(
          maxHeight: screenHeight * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
// Header
Container(
  padding: EdgeInsets.all(isTablet ? 24 : 20),
  decoration: BoxDecoration(
    gradient: LinearGradient(colors: [_primaryGreen, _darkGreen]),
    borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
  ),
  child: Row(
    children: [
      Container(
        padding: EdgeInsets.all(isTablet ? 12 : 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(isTablet ? 14 : 12),
        ),
        child: Icon(Icons.edit_rounded, color: _goldAccent, size: isTablet ? 28 : 24),
      ),
      const SizedBox(width: 16),
      Expanded(  // ✅ Add Expanded to prevent overflow
        child: Text(
          'Edit Business Partner',
          style: GoogleFonts.poppins(
            fontSize: isTablet ? 22 : 20,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
          overflow: TextOverflow.ellipsis, // ✅ Add overflow handling
        ),
      ),
      IconButton(
        onPressed: () => Navigator.pop(context),
        icon: Icon(Icons.close_rounded, color: Colors.white, size: isTablet ? 28 : 24),
      ),
    ],
  ),
),
            
            // Form
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(isTablet ? 24 : 20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildLogoSection(),
                      const SizedBox(height: 24),
                      
                      // Business Name
                      _buildTextField(
                        _businessNameController,
                        'Business Name *',
                        Icons.business_rounded,
                        isTablet: isTablet,
                      ),
                      const SizedBox(height: 16),
                      
                      // Owner Name
                      _buildTextField(
                        _ownerNameController,
                        'Owner Name *',
                        Icons.person_rounded,
                        isTablet: isTablet,
                      ),
                      const SizedBox(height: 16),
                      
                      // Email & Phone Row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _buildTextField(
                              _emailController,
                              'Email *',
                              Icons.email_rounded,
                              keyboardType: TextInputType.emailAddress,
                              isTablet: isTablet,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildTextField(
                              _phoneController,
                              'Phone Number *',
                              Icons.phone_rounded,
                              keyboardType: TextInputType.phone,
                              isTablet: isTablet,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Location Picker
                      _buildLocationPickerField(),
                      const SizedBox(height: 16),
                      
                      // City & State Row
                      // City & State Row
Row(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Expanded(
      child: _buildTextField(
        _cityController,
        'City *',
        Icons.location_city_rounded,
        isTablet: isTablet,
      ),
    ),
    const SizedBox(width: 12),
    Expanded(
      child: _buildStateDropdown(isTablet), // Both Expanded now
    ),
  ],
),
                      const SizedBox(height: 16),
                      
                      // Business Type Dropdown
                      _buildDropdown<BusinessType>(
                        value: _selectedBusinessType,
                        hint: 'Business Type *',
                        items: BusinessType.values.map((type) => DropdownMenuItem(
                          value: type,
                          child: Text(
                            type.displayName,
                            style: GoogleFonts.inter(fontSize: isTablet ? 15 : 14),
                          ),
                        )).toList(),
                        onChanged: (value) => setState(() => _selectedBusinessType = value),
                        isTablet: isTablet,
                      ),
                      const SizedBox(height: 16),
                      
                      // Industry
                      _buildTextField(
                        _industryController,
                        'Industry *',
                        Icons.category_rounded,
                        isTablet: isTablet,
                      ),
                      const SizedBox(height: 16),
                      
                      // Description
                      _buildTextField(
                        _descriptionController,
                        'Description *',
                        Icons.description_rounded,
                        maxLines: 4,
                        isTablet: isTablet,
                      ),
                      const SizedBox(height: 16),
                      
                      // Years & Website Row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _buildTextField(
                              _yearsController,
                              'Years in Business *',
                              Icons.calendar_today_rounded,
                              keyboardType: TextInputType.number,
                              isTablet: isTablet,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildTextField(
                              _websiteController,
                              'Website',
                              Icons.language_rounded,
                              keyboardType: TextInputType.url,
                              isRequired: false,
                              isTablet: isTablet,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      
                      // Services Offered
                      Text(
                        'Services Offered',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: isTablet ? 15 : 14,
                          color: _primaryGreen,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildTagInput(
                        controller: _serviceController,
                        tags: _servicesOffered,
                        hint: 'Add a service',
                        onAdd: () {
                          if (_serviceController.text.trim().isNotEmpty) {
                            setState(() {
                              _servicesOffered.add(_serviceController.text.trim());
                              _serviceController.clear();
                            });
                          }
                        },
                        onRemove: (index) => setState(() => _servicesOffered.removeAt(index)),
                        isTablet: isTablet,
                      ),
                      const SizedBox(height: 20),
                      
                      // Social Media Links
                      Text(
                        'Social Media Links',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: isTablet ? 15 : 14,
                          color: _primaryGreen,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildTagInput(
                        controller: _socialMediaController,
                        tags: _socialMediaLinks,
                        hint: 'Add social media URL',
                        onAdd: () {
                          if (_socialMediaController.text.trim().isNotEmpty) {
                            setState(() {
                              _socialMediaLinks.add(_socialMediaController.text.trim());
                              _socialMediaController.clear();
                            });
                          }
                        },
                        onRemove: (index) => setState(() => _socialMediaLinks.removeAt(index)),
                        isSocialMedia: true,
                        isTablet: isTablet,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Actions
            Container(
              padding: EdgeInsets.all(isTablet ? 24 : 20),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey[200]!)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: isTablet ? 14 : 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        side: BorderSide(color: _errorRed),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.poppins(
                          fontSize: isTablet ? 15 : 14,
                          fontWeight: FontWeight.w600,
                          color: _errorRed,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveChanges,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryGreen,
                        padding: EdgeInsets.symmetric(vertical: isTablet ? 14 : 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 2,
                      ),
                      child: _isLoading
                          ? SizedBox(
                              width: isTablet ? 24 : 20,
                              height: isTablet ? 24 : 20,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              'Save Changes',
                              style: GoogleFonts.poppins(
                                fontSize: isTablet ? 15 : 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
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


Widget _buildTextField(
  TextEditingController controller,
  String label,
  IconData icon, {
  TextInputType keyboardType = TextInputType.text,
  int maxLines = 1,
  bool isRequired = true,
  required bool isTablet,
}) {
  // ✅ Fix: For multiline fields, use multiline keyboard type
  final bool isMultiline = maxLines > 1;
  final TextInputType effectiveKeyboardType = isMultiline 
      ? TextInputType.multiline 
      : keyboardType;
  
  return TextFormField(
    controller: controller,
    keyboardType: effectiveKeyboardType, // ✅ Fixed: Use multiline for multiline fields
    maxLines: maxLines,
    textInputAction: maxLines == 1 ? TextInputAction.next : TextInputAction.newline,
    style: GoogleFonts.inter(fontSize: isTablet ? 15 : 14),
    decoration: InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.poppins(fontSize: isTablet ? 13 : 12, fontWeight: FontWeight.w500),
      prefixIcon: Icon(icon, color: _primaryGreen, size: isTablet ? 22 : 20),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: _primaryGreen, width: 2),
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: EdgeInsets.symmetric(
        horizontal: isTablet ? 18 : 16,
        vertical: maxLines > 1 ? (isTablet ? 18 : 16) : (isTablet ? 16 : 14),
      ),
    ),
    validator: isRequired
        ? (value) => value == null || value.isEmpty ? 'This field is required' : null
        : null,
  );
}
 
 
Widget _buildStateDropdown(bool isTablet) {
  return Container(
    constraints: BoxConstraints(
      maxWidth: isTablet ? 400 : double.infinity,
    ),
    child: DropdownButtonFormField<String>(
      value: _selectedState,
      isExpanded: true, // ✅ Add this to make dropdown take full width
      decoration: InputDecoration(
        labelText: 'State *',
        labelStyle: GoogleFonts.poppins(fontSize: isTablet ? 13 : 12, fontWeight: FontWeight.w500),
        prefixIcon: Icon(Icons.map_rounded, color: _primaryGreen, size: isTablet ? 22 : 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _primaryGreen, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(
          horizontal: isTablet ? 18 : 16,
          vertical: isTablet ? 16 : 14,
        ),
      ),
      items: [
        // If current value is not in the list, add it as an option
        if (_selectedState != null && !CommunityStates.states.contains(_selectedState))
          DropdownMenuItem(
            value: _selectedState,
            child: Text(
              _selectedState!,
              style: GoogleFonts.inter(fontSize: isTablet ? 15 : 14),
              overflow: TextOverflow.ellipsis, // ✅ Add overflow handling
            ),
          ),
        // Add all US states
        ...CommunityStates.states.map((state) => DropdownMenuItem(
          value: state,
          child: Text(
            state,
            style: GoogleFonts.inter(fontSize: isTablet ? 15 : 14),
            overflow: TextOverflow.ellipsis, // ✅ Add overflow handling
          ),
        )),
      ],
      onChanged: (value) {
        if (mounted) {
          setState(() {
            _selectedState = value;
          });
        }
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'State is required';
        }
        return null;
      },
      // ✅ Add these to prevent overflow
      isDense: true,
      icon: Icon(Icons.arrow_drop_down, size: isTablet ? 28 : 24),
      iconSize: isTablet ? 28 : 24,
    ),
  );
}

  Widget _buildDropdown<T>({
    required T? value,
    required String hint,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
    required bool isTablet,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      decoration: InputDecoration(
        labelText: hint,
        labelStyle: GoogleFonts.poppins(fontSize: isTablet ? 13 : 12, fontWeight: FontWeight.w500),
        prefixIcon: Icon(Icons.business_rounded, color: _primaryGreen, size: isTablet ? 22 : 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _primaryGreen, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(horizontal: isTablet ? 18 : 16, vertical: isTablet ? 16 : 14),
      ),
      items: items,
      onChanged: onChanged,
      validator: (value) => value == null ? 'This field is required' : null,
    );
  }

  Widget _buildTagInput({
    required TextEditingController controller,
    required List<String> tags,
    required String hint,
    required VoidCallback onAdd,
    required Function(int) onRemove,
    bool isSocialMedia = false,
    required bool isTablet,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                style: GoogleFonts.inter(fontSize: isTablet ? 15 : 14),
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: GoogleFonts.inter(fontSize: isTablet ? 14 : 13, color: Colors.grey[400]),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: EdgeInsets.symmetric(horizontal: isTablet ? 16 : 14, vertical: isTablet ? 14 : 12),
                ),
                onSubmitted: (_) => onAdd(),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [_primaryGreen, _darkGreen]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                onPressed: onAdd,
                icon: Icon(Icons.add, color: Colors.white, size: isTablet ? 24 : 22),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  padding: EdgeInsets.all(isTablet ? 12 : 10),
                ),
              ),
            ),
          ],
        ),
        if (tags.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: tags.asMap().entries.map((entry) {
              return Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 14 : 12,
                  vertical: isTablet ? 8 : 6,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isSocialMedia
                        ? [_getSocialMediaColor(entry.value), _getSocialMediaColor(entry.value).withOpacity(0.7)]
                        : [_primaryGreen.withOpacity(0.1), _lightGreen],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: isSocialMedia
                        ? _getSocialMediaColor(entry.value).withOpacity(0.3)
                        : _primaryGreen.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isSocialMedia) ...[
                      Icon(
                        _getSocialMediaIcon(entry.value),
                        size: isTablet ? 18 : 16,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      isSocialMedia ? _getSocialMediaName(entry.value) : entry.value,
                      style: GoogleFonts.inter(
                        fontSize: isTablet ? 14 : 13,
                        fontWeight: FontWeight.w600,
                        color: isSocialMedia ? Colors.white : _primaryGreen,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => onRemove(entry.key),
                      child: Container(
                        padding: EdgeInsets.all(isTablet ? 4 : 3),
                        decoration: BoxDecoration(
                          color: isSocialMedia ? Colors.white.withOpacity(0.2) : _errorRed.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close_rounded,
                          size: isTablet ? 16 : 14,
                          color: isSocialMedia ? Colors.white : _errorRed,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Color _getSocialMediaColor(String url) {
    if (url.contains('facebook.com') || url.contains('fb.com')) return const Color(0xFF1877F2);
    if (url.contains('instagram.com')) return const Color(0xFFE4405F);
    if (url.contains('twitter.com') || url.contains('x.com')) return const Color(0xFF1DA1F2);
    if (url.contains('linkedin.com')) return const Color(0xFF0A66C2);
    if (url.contains('youtube.com')) return const Color(0xFFFF0000);
    return _primaryGreen;
  }

  IconData _getSocialMediaIcon(String url) {
    if (url.contains('facebook.com') || url.contains('fb.com')) return Icons.facebook;
    if (url.contains('instagram.com')) return Icons.camera_alt;
    if (url.contains('twitter.com') || url.contains('x.com')) return Icons.flutter_dash;
    if (url.contains('linkedin.com')) return Icons.work;
    if (url.contains('youtube.com')) return Icons.play_circle_filled;
    return Icons.link;
  }

  String _getSocialMediaName(String url) {
    if (url.contains('facebook.com') || url.contains('fb.com')) return 'Facebook';
    if (url.contains('instagram.com')) return 'Instagram';
    if (url.contains('twitter.com') || url.contains('x.com')) return 'Twitter';
    if (url.contains('linkedin.com')) return 'LinkedIn';
    if (url.contains('youtube.com')) return 'YouTube';
    return 'Link';
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedBusinessType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a business type'), backgroundColor: Colors.red),
      );
      return;
    }
    if (_selectedState == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a state'), backgroundColor: Colors.red),
      );
      return;
    }
    if (_latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a location on the map'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.user;
    if (currentUser == null) {
      setState(() => _isLoading = false);
      return;
    }

    final updatedPartner = widget.partner.copyWith(
      businessName: _businessNameController.text.trim(),
      ownerName: _ownerNameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      address: _addressController.text.trim(),
      state: _selectedState!,
      city: _cityController.text.trim(),
      businessType: _selectedBusinessType!,
      industry: _industryController.text.trim(),
      description: _descriptionController.text.trim(),
      yearsInBusiness: int.tryParse(_yearsController.text) ?? 0,
      servicesOffered: _servicesOffered,
      website: _websiteController.text.trim().isNotEmpty ? _websiteController.text.trim() : null,
      socialMediaLinks: _socialMediaLinks.isNotEmpty ? _socialMediaLinks : null,
      logoImageBase64: _logoBase64,
      latitude: _latitude,
      longitude: _longitude,
      updatedAt: DateTime.now(),
    );

    final provider = Provider.of<EntrepreneurshipProvider>(context, listen: false);
    final success = await provider.updateBusinessPartner(widget.partner.id!, updatedPartner);

    setState(() => _isLoading = false);

    if (success && mounted) {
      Navigator.pop(context);
      widget.onUpdate();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Business partner updated successfully'), backgroundColor: Color(0xFF006A4E)),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update business partner'), backgroundColor: Colors.red),
      );
    }
  }
}