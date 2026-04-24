// screens/add_service_screen.dart
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:bangla_hub/models/community_services_models.dart';
import 'package:bangla_hub/providers/service_provider_provider.dart';
import 'package:bangla_hub/widgets/common/osm_location_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';



class AddServiceScreen extends StatefulWidget {
  const AddServiceScreen({Key? key}) : super(key: key);

  @override
  State<AddServiceScreen> createState() => _AddServiceScreenState();
}

class _AddServiceScreenState extends State<AddServiceScreen> 
    with TickerProviderStateMixin {
  
  // Color Palette
  final Color _primaryGreen = const Color(0xFF006A4E);
  final Color _accentRed = const Color(0xFFD32F2F);
  final Color _goldAccent = const Color(0xFFFFB300);
  final Color _lightGreen = const Color(0xFFE8F5E9);
  
  // Form Controllers
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _websiteController = TextEditingController();
  final TextEditingController _businessHoursController = TextEditingController();
  final TextEditingController _yearsOfExperienceController = TextEditingController();
  final TextEditingController _licenseNumberController = TextEditingController();
  final TextEditingController _specialtiesController = TextEditingController();
  final TextEditingController _consultationFeeController = TextEditingController();
  
  // Location variables
  double? _eventLatitude;
  double? _eventLongitude;
  String? _eventState;
  String? _eventCity;
  String? _fullAddress;
  
  // Selection variables
  ServiceCategory? _selectedCategory;
  String? _selectedServiceProvider;
  String? _selectedSubServiceProvider;
  String? _selectedState;
  String? _selectedCity;
  
  // Multi-select lists
  List<String> _languagesSpoken = [];
  List<String> _serviceTags = [];
  List<String> _serviceAreas = [];
  List<String> _acceptedPaymentMethods = [];
  
  // Other fields
  bool _isAvailable = true;
  bool _acceptsInsurance = false;
  
  // Image
  XFile? _selectedImage;
  String? _base64Image;
  bool _isImageLoading = false;
  bool _isSaving = false;
  
  // Tab Controller
  late TabController _tabController;
  
  // Validation flags
  bool _isBasicInfoValid = false;
  bool _isDetailsTabValid = false;
  
  // Available options
  List<String> _availableServiceProviders = [];
  List<String> _availableSubServiceProviders = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabChange);
    
    // Add listeners for validation
    _fullNameController.addListener(_validateBasicInfo);
    _companyNameController.addListener(_validateBasicInfo);
    _phoneController.addListener(_validateBasicInfo);
    _addressController.addListener(_validateBasicInfo);
    _descriptionController.addListener(_validateDetailsTab);
  }
  
  @override
  void dispose() {
    _fullNameController.removeListener(_validateBasicInfo);
    _companyNameController.removeListener(_validateBasicInfo);
    _phoneController.removeListener(_validateBasicInfo);
    _addressController.removeListener(_validateBasicInfo);
    _descriptionController.removeListener(_validateDetailsTab);
    
    _fullNameController.dispose();
    _companyNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    _websiteController.dispose();
    _businessHoursController.dispose();
    _yearsOfExperienceController.dispose();
    _licenseNumberController.dispose();
    _specialtiesController.dispose();
    _consultationFeeController.dispose();
    
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (mounted) setState(() {});
  }

  void _validateBasicInfo() {
    if (mounted) {
      setState(() {
        _isBasicInfoValid = 
            _fullNameController.text.isNotEmpty &&
        //    _companyNameController.text.isNotEmpty &&
            _phoneController.text.isNotEmpty &&
            _addressController.text.isNotEmpty &&
            _selectedCategory != null &&
            _selectedServiceProvider != null &&
            (_eventLatitude != null && _eventLongitude != null) &&
            _selectedState != null &&
            _selectedCity != null;
      });
    }
  }

  void _validateDetailsTab() {
    if (mounted) {
      setState(() {
        _isDetailsTabValid = _descriptionController.text.isNotEmpty;
      });
    }
  }

  bool get _isSubmitEnabled => _isBasicInfoValid && _isDetailsTabValid;

  void _updateServiceProviders() {
    if (_selectedCategory != null) {
      setState(() {
        _availableServiceProviders = _selectedCategory!.serviceProviders;
        _selectedServiceProvider = null;
        _selectedSubServiceProvider = null;
        _availableSubServiceProviders = [];
      });
    }
  }

  void _updateSubServiceProviders() {
    if (_selectedCategory != null && _selectedServiceProvider != null) {
      setState(() {
        _availableSubServiceProviders = 
            _selectedCategory!.subServiceProviders[_selectedServiceProvider!] ?? [];
        _selectedSubServiceProvider = null;
      });
    }
  }

  void _goToPreviousTab() {
    if (_tabController.index > 0) {
      _tabController.animateTo(_tabController.index - 1);
    }
  }

  void _goToNextTab() {
    if (_tabController.index < 2) {
      if (_tabController.index == 0 && !_isBasicInfoValid) {
        _showErrorSnackBar('Please complete all required fields');
        return;
      }
      _tabController.animateTo(_tabController.index + 1);
    }
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
      );
      
      if (pickedFile != null) {
        setState(() {
          _isImageLoading = true;
        });
        
        // Compress image
        final compressedBytes = await _compressImage(File(pickedFile.path));
        if (compressedBytes != null) {
          final base64String = base64Encode(compressedBytes);
          setState(() {
            _selectedImage = pickedFile;
            _base64Image = 'data:image/jpeg;base64,$base64String';
            _isImageLoading = false;
          });
          _showSuccessSnackBar('Image selected successfully');
        } else {
          setState(() => _isImageLoading = false);
          _showErrorSnackBar('Failed to compress image');
        }
      }
    } catch (e) {
      setState(() => _isImageLoading = false);
      _showErrorSnackBar('Error picking image: $e');
    }
  }

  Future<Uint8List?> _compressImage(File file) async {
    try {
      final dir = await getTemporaryDirectory();
      final targetPath = '${dir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      final result = await FlutterImageCompress.compressAndGetFile(
        file.path,
        targetPath,
        quality: 70,
        minWidth: 400,
        minHeight: 400,
        format: CompressFormat.jpeg,
      );
      
      if (result != null) {
        return await result.readAsBytes();
      }
      return null;
    } catch (e) {
      print('Compression error: $e');
      return null;
    }
  }

  Future<void> _submitForm() async {
    if (!_isSubmitEnabled) return;

  final currentUser = FirebaseAuth.instance.currentUser;
    
    if (currentUser == null) {
      _showErrorSnackBar('You must be logged in to add a service');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final serviceProvider = ServiceProviderModel(
        fullName: _fullNameController.text.trim(),
        companyName: _companyNameController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        address: _fullAddress ?? _addressController.text.trim(),
        state: _selectedState!,
        city: _selectedCity!,
        serviceCategory: _selectedCategory!,
        serviceProvider: _selectedServiceProvider!,
        subServiceProvider: _selectedSubServiceProvider,
        profileImageBase64: _base64Image,
        description: _descriptionController.text.trim(),
        website: _websiteController.text.trim().isEmpty ? null : _websiteController.text.trim(),
        businessHours: _businessHoursController.text.trim().isEmpty ? null : _businessHoursController.text.trim(),
        yearsOfExperience: _yearsOfExperienceController.text.trim().isEmpty ? null : _yearsOfExperienceController.text.trim(),
        languagesSpoken: _languagesSpoken.isEmpty ? ['English'] : _languagesSpoken,
        serviceTags: _serviceTags,
        serviceAreas: _serviceAreas,
        isVerified: false,
        isAvailable: _isAvailable,
        isDeleted: false,
        createdBy: currentUser.uid, // ✅ Use currentUser.id
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        licenseNumber: _licenseNumberController.text.trim().isEmpty ? null : _licenseNumberController.text.trim(),
        specialties: _specialtiesController.text.trim().isEmpty ? null : _specialtiesController.text.trim(),
        consultationFee: _consultationFeeController.text.trim().isEmpty 
            ? null 
            : double.tryParse(_consultationFeeController.text.trim()),
        acceptsInsurance: _acceptsInsurance,
        acceptedPaymentMethods: _acceptedPaymentMethods.isEmpty ? null : _acceptedPaymentMethods,
        latitude: _eventLatitude,
        longitude: _eventLongitude,
      );

      final provider = Provider.of<ServiceProviderProvider>(context, listen: false);
      final success = await provider.addServiceProvider(serviceProvider);
      
      if (success && mounted) {
        _showSuccessSnackBar('Service added successfully! Pending admin approval.');
        Navigator.pop(context);
      }
    } catch (e) {
      _showErrorSnackBar('Failed to add service: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // UI Components
  Widget _buildTabIndicator(int index, String label, bool isValid) {
    final isSelected = _tabController.index == index;
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (index == 0) {
            _tabController.animateTo(0);
          } else if (index == 1 && _isBasicInfoValid) {
            _tabController.animateTo(1);
          } else if (index == 2 && _isBasicInfoValid) {
            _tabController.animateTo(2);
          } else {
            _showErrorSnackBar('Complete previous steps first');
          }
        },
        child: Container(
          height: screenWidth > 600 ? 60 : 50,
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    colors: [_goldAccent, _primaryGreen],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isSelected ? null : Colors.grey[100],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isValid ? _primaryGreen : Colors.grey[300]!,
              width: isValid ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: screenWidth > 600 ? 24 : 20,
                height: screenWidth > 600 ? 24 : 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isValid ? _primaryGreen : (isSelected ? Colors.white : Colors.grey[400]),
                ),
                child: isValid
                    ? Icon(Icons.check, color: Colors.white, size: screenWidth > 600 ? 14 : 12)
                    : Center(
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            color: isSelected ? _primaryGreen : Colors.white,
                            fontSize: screenWidth > 600 ? 12 : 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : (isValid ? _primaryGreen : Colors.grey[600]),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  fontSize: screenWidth > 600 ? 10 : 9,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabConnector(bool isCompleted) {
    return Container(
      width: MediaQuery.of(context).size.width > 600 ? 20 : 12,
      height: 2,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        gradient: isCompleted
            ? LinearGradient(colors: [_primaryGreen, _goldAccent])
            : LinearGradient(colors: [Colors.grey[300]!, Colors.grey[400]!]),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildNavButton({
    required String label,
    required VoidCallback onPressed,
    required bool isPrimary,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Container(
      height: screenWidth > 600 ? 50 : 44,
      decoration: BoxDecoration(
        gradient: isPrimary
            ? LinearGradient(colors: [_primaryGreen, _primaryGreen.withOpacity(0.8)])
            : null,
        color: isPrimary ? null : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isPrimary ? null : Border.all(color: _primaryGreen),
        boxShadow: isPrimary
            ? [BoxShadow(color: _primaryGreen.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                color: isPrimary ? Colors.white : _primaryGreen,
                fontWeight: FontWeight.w600,
                fontSize: screenWidth > 600 ? 15 : 13,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Container(
      height: screenWidth > 600 ? 50 : 44,
      decoration: BoxDecoration(
        gradient: _isSubmitEnabled
            ? LinearGradient(colors: [_primaryGreen, _primaryGreen.withOpacity(0.8)])
            : null,
        color: _isSubmitEnabled ? null : Colors.grey[300],
        borderRadius: BorderRadius.circular(12),
        boxShadow: _isSubmitEnabled
            ? [BoxShadow(color: _primaryGreen.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isSubmitEnabled ? _submitForm : null,
          borderRadius: BorderRadius.circular(12),
          child: Center(
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Text(
                    'Submit',
                    style: GoogleFonts.poppins(
                      color: _isSubmitEnabled ? Colors.white : Colors.grey[600],
                      fontWeight: FontWeight.w700,
                      fontSize: screenWidth > 600 ? 15 : 13,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(screenWidth > 600 ? 8 : 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [_primaryGreen, _primaryGreen.withOpacity(0.7)]),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.white, size: screenWidth > 600 ? 18 : 16),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: screenWidth > 600 ? 16 : 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1E2A3A),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    bool isRequired = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: isRequired ? '$label *' : label,
          labelStyle: TextStyle(color: Colors.grey[600], fontSize: 13),
          prefixIcon: Icon(icon, color: _primaryGreen, size: 18),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _primaryGreen, width: 2)),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: maxLines > 1 ? 14 : 12),
        ),
      ),
    );
  }

 /* Widget _buildDropdownField<T>({
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required String label,
    required IconData icon,
    required void Function(T?) onChanged,
    bool isRequired = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: DropdownButtonFormField<T>(
        value: value,
        decoration: InputDecoration(
          labelText: isRequired ? '$label *' : label,
          labelStyle: TextStyle(color: Colors.grey[600], fontSize: 13),
          prefixIcon: Icon(icon, color: _primaryGreen, size: 18),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _primaryGreen, width: 2)),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        ),
        items: items,
        onChanged: onChanged,
      ),
    );
  }
*/


Widget _buildDropdownField<T>({
  required T? value,
  required List<DropdownMenuItem<T>> items,
  required String label,
  required IconData icon,
  required void Function(T?) onChanged,
  bool isRequired = false,
}) {
  return Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.02),
          blurRadius: 8,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: DropdownButtonFormField<T>(
      value: value,

      isExpanded: true, // ✅ Prevents horizontal overflow

      decoration: InputDecoration(
        labelText: isRequired ? '$label *' : label,
        labelStyle: TextStyle(
          color: Colors.grey[600],
          fontSize: 13,
        ),
        prefixIcon: Icon(
          icon,
          color: _primaryGreen,
          size: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _primaryGreen, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 10,
        ),
      ),

      items: items,

      onChanged: onChanged,

      // ✅ Safe selected item rendering (prevents overflow)
      selectedItemBuilder: (BuildContext context) {
        return items.map((item) {
          final text = item.value?.toString() ?? '';

          return Align(
            alignment: Alignment.centerLeft,
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              softWrap: false,
            ),
          );
        }).toList();
      },

      // ✅ Dropdown menu height control (prevents vertical overflow)
      menuMaxHeight: 300,
    ),
  );
}




  Widget _buildLocationPickerField() {
    final isTablet = MediaQuery.of(context).size.width > 600;
    
    return GestureDetector(
      onTap: () async {
        final result = await showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => GoogleMapsLocationPicker(
            initialLatitude: _eventLatitude,
            initialLongitude: _eventLongitude,
            initialAddress: _addressController.text,
            initialState: _eventState,
            initialCity: _eventCity,
            onLocationSelected: (lat, lng, address, state, city) {
              setState(() {
                _eventLatitude = lat;
                _eventLongitude = lng;
                _eventState = state;
                _eventCity = city;
                _fullAddress = address;
                _addressController.text = address;
                
                if (state != null) {
                  _selectedState = state;
                }
                if (city != null) {
                  _selectedCity = city;
                }
                _validateBasicInfo();
              });
            },
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.all(isTablet ? 16 : 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [Colors.white.withOpacity(0.95), Colors.white.withOpacity(0.9)]),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _eventLatitude != null ? _primaryGreen : Colors.grey.shade300.withOpacity(0.5), width: _eventLatitude != null ? 2 : 1.5),
          boxShadow: [BoxShadow(color: _primaryGreen.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [_primaryGreen, _primaryGreen.withOpacity(0.7)]),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.location_on, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Location *',
                        style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: _primaryGreen),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _addressController.text.isEmpty ? 'Tap to select location on map' : _addressController.text,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: _addressController.text.isEmpty ? Colors.grey[600] : Colors.black87,
                          fontWeight: _addressController.text.isEmpty ? FontWeight.w500 : FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios, color: _primaryGreen, size: 14),
              ],
            ),
            if (_eventLatitude != null && _eventLongitude != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: _lightGreen.withOpacity(0.3), borderRadius: BorderRadius.circular(16)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.my_location, color: _primaryGreen, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      '${_eventLatitude!.toStringAsFixed(4)}, ${_eventLongitude!.toStringAsFixed(4)}',
                      style: GoogleFonts.inter(fontSize: 11, color: _primaryGreen, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfoTab() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Personal / Business Information', Icons.person_rounded),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _fullNameController,
            label: 'Full Name',
            icon: Icons.person_rounded,
            isRequired: true,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _companyNameController,
            label: 'Company Name (Optional)',
            icon: Icons.business_rounded,
            isRequired: false,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _phoneController,
            label: 'Phone Number',
            icon: Icons.phone_rounded,
            keyboardType: TextInputType.phone,
            isRequired: true,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _emailController,
            label: 'Email (Optional)',
            icon: Icons.email_rounded,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 20),
          
          _buildSectionHeader('Location', Icons.location_on_rounded),
          const SizedBox(height: 16),
          _buildLocationPickerField(),
          const SizedBox(height: 20),
          
          _buildSectionHeader('Service Details', Icons.handyman_rounded),
          const SizedBox(height: 16),
          _buildDropdownField<ServiceCategory>(
            value: _selectedCategory,
            label: 'Service Category',
            icon: Icons.category_rounded,
            isRequired: true,
            items: ServiceCategory.values.map((category) {
              return DropdownMenuItem(
                value: category,
                child: Text(category.displayName),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedCategory = value;
                _updateServiceProviders();
                _validateBasicInfo();
              });
            },
          ),
          const SizedBox(height: 12),
          if (_selectedCategory != null)
            _buildDropdownField<String>(
              value: _selectedServiceProvider,
              label: 'Service Type',
              icon: Icons.work_rounded,
              isRequired: true,
              items: _availableServiceProviders.map((provider) {
                return DropdownMenuItem(
                  value: provider,
                  child: Text(provider),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedServiceProvider = value;
                  _updateSubServiceProviders();
                  _validateBasicInfo();
                });
              },
            ),
          const SizedBox(height: 12),
          if (_availableSubServiceProviders.isNotEmpty)
            _buildDropdownField<String>(
              value: _selectedSubServiceProvider,
              label: 'Sub-Service (Optional)',
              icon: Icons.work_outline_rounded,
              items: _availableSubServiceProviders.map((provider) {
                return DropdownMenuItem(
                  value: provider,
                  child: Text(provider),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedSubServiceProvider = value;
                });
              },
            ),
        ],
      ),
    );
  }

  Widget _buildMediaTab() {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Profile Image', Icons.image_rounded),
          const SizedBox(height: 8),
          Text(
            'Upload a profile image for your service (optional)',
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
          const SizedBox(height: 16),
          
          Center(
            child: GestureDetector(
              onTap: _isImageLoading ? null : _pickImage,
              child: Container(
                width: screenWidth > 600 ? 200 : 160,
                height: screenWidth > 600 ? 200 : 160,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(colors: [_lightGreen, Colors.white]),
                  border: Border.all(color: _primaryGreen, width: 2),
                  boxShadow: [BoxShadow(color: _primaryGreen.withOpacity(0.2), blurRadius: 8, spreadRadius: 2)],
                ),
                child: _isImageLoading
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const CircularProgressIndicator(strokeWidth: 2),
                            const SizedBox(height: 8),
                            Text('Compressing...', style: TextStyle(fontSize: 10, color: _primaryGreen)),
                          ],
                        ),
                      )
                    : _selectedImage != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: Image.file(File(_selectedImage!.path), fit: BoxFit.cover),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo_rounded, size: screenWidth > 600 ? 40 : 32, color: _primaryGreen),
                              const SizedBox(height: 8),
                              Text('Add Image', style: GoogleFonts.poppins(color: _primaryGreen, fontSize: screenWidth > 600 ? 14 : 12, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              Text('Tap to upload', style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 9)),
                            ],
                          ),
              ),
            ),
          ),
          
          if (_selectedImage != null && !_isImageLoading)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Center(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedImage = null;
                      _base64Image = null;
                    });
                    _showSuccessSnackBar('Image removed');
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _accentRed.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _accentRed.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.delete_outline, size: 14, color: _accentRed),
                        const SizedBox(width: 4),
                        Text('Remove Image', style: TextStyle(fontSize: 11, color: _accentRed, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Service Information', Icons.info_rounded),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _descriptionController,
            label: 'Description',
            icon: Icons.description_rounded,
            maxLines: 5,
            isRequired: true,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _websiteController,
            label: 'Website (Optional)',
            icon: Icons.language_rounded,
            keyboardType: TextInputType.url,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _businessHoursController,
            label: 'Business Hours (Optional)',
            icon: Icons.access_time_rounded,
            maxLines: 2,
          ),
          const SizedBox(height: 20),
          
          _buildSectionHeader('Professional Information', Icons.work_rounded),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _yearsOfExperienceController,
            label: 'Years of Experience (Optional)',
            icon: Icons.timeline_rounded,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _licenseNumberController,
            label: 'License Number (Optional)',
            icon: Icons.badge_rounded,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _specialtiesController,
            label: 'Specialties (Optional)',
            icon: Icons.star_rounded,
            maxLines: 2,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _consultationFeeController,
            label: 'Consultation Fee (Optional)',
            icon: Icons.attach_money_rounded,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 20),
          
          _buildSectionHeader('Additional Options', Icons.tune_rounded),
          const SizedBox(height: 16),
          _buildToggleOption(
            title: 'Available for Service',
            value: _isAvailable,
            onChanged: (value) => setState(() => _isAvailable = value),
          ),
          const SizedBox(height: 12),
          _buildToggleOption(
            title: 'Accepts Insurance',
            value: _acceptsInsurance,
            onChanged: (value) => setState(() => _acceptsInsurance = value),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleOption({
    required String title,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500)),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: _primaryGreen,
            activeTrackColor: _primaryGreen.withOpacity(0.3),
          ),
        ],
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [Icon(Icons.check_circle_rounded, color: Colors.white, size: 20), const SizedBox(width: 10), Expanded(child: Text(message))]),
        backgroundColor: _primaryGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(12),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [Icon(Icons.error_rounded, color: Colors.white, size: 20), const SizedBox(width: 10), Expanded(child: Text(message))]),
        backgroundColor: _accentRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Add Service', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: _primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Tab Indicators
          Container(
            margin: EdgeInsets.symmetric(horizontal: isTablet ? 20 : 16, vertical: 16),
            height: isTablet ? 60 : 50,
            child: Row(
              children: [
                _buildTabIndicator(0, 'Basic', _isBasicInfoValid),
                _buildTabConnector(_isBasicInfoValid),
                _buildTabIndicator(1, 'Media', true),
                _buildTabConnector(true),
                _buildTabIndicator(2, 'Details', _isDetailsTabValid),
              ],
            ),
          ),
          
          // Form Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildBasicInfoTab(),
                _buildMediaTab(),
                _buildDetailsTab(),
              ],
            ),
          ),
          
          // Navigation Buttons
          Container(
            padding: EdgeInsets.all(isTablet ? 20 : 16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, -5))],
              border: Border(top: BorderSide(color: Colors.grey.shade200, width: 1)),
            ),
            child: Row(
              children: [
                if (_tabController.index > 0)
                  Expanded(child: _buildNavButton(label: 'Previous', onPressed: _goToPreviousTab, isPrimary: false)),
                if (_tabController.index > 0) const SizedBox(width: 12),
                Expanded(
                  child: _tabController.index < 2
                      ? _buildNavButton(label: 'Next', onPressed: _goToNextTab, isPrimary: true)
                      : _buildSubmitButton(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}