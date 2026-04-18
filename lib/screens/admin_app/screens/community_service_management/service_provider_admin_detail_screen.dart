// screens/admin/service_provider_admin_detail_screen.dart
import 'dart:io';
import 'dart:convert';
import 'package:bangla_hub/models/community_services_models.dart';
import 'package:bangla_hub/providers/service_provider_provider.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';

class ServiceProviderAdminDetailScreen extends StatefulWidget {
  final String providerId;

  const ServiceProviderAdminDetailScreen({super.key, required this.providerId});

  @override
  State<ServiceProviderAdminDetailScreen> createState() => _ServiceProviderAdminDetailScreenState();
}

class _ServiceProviderAdminDetailScreenState extends State<ServiceProviderAdminDetailScreen> {
  // Form controllers for edit mode
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _websiteController = TextEditingController();
  final TextEditingController _businessHoursController = TextEditingController();
  final TextEditingController _yearsOfExperienceController = TextEditingController();
  final TextEditingController _licenseNumberController = TextEditingController();
  final TextEditingController _specialtiesController = TextEditingController();
  final TextEditingController _consultationFeeController = TextEditingController();
  final TextEditingController _languageController = TextEditingController();
  final TextEditingController _serviceTagController = TextEditingController();
  final TextEditingController _serviceAreaController = TextEditingController();

  // State variables
  bool _isEditing = false;
  bool _isSaving = false;
  XFile? _selectedImage;
  String? _base64Image;
  bool _isImageLoading = false;

  // Dropdown values
  String? _selectedState;
  ServiceCategory? _selectedCategory;
  String? _selectedServiceProvider;
  String? _selectedSubServiceProvider;

  // Multi-select values
  List<String> _languagesSpoken = [];
  List<String> _serviceTags = [];
  List<String> _serviceAreas = [];

  // Other fields
  List<String> _availableServiceProviders = [];
  List<String> _availableSubServiceProviders = [];
  bool _isAvailable = true;
  bool _acceptsInsurance = false;
  List<String> _acceptedPaymentMethods = [];

  // Premium Color Palette - Matching ServiceProviderDetailScreen
  final Color _primaryRed = const Color(0xFFE03C32);
  final Color _primaryGreen = const Color(0xFF006A4E);
  final Color _darkGreen = const Color(0xFF00432D);
  final Color _lightGreen = const Color(0xFFE8F5E9);
  final Color _goldAccent = const Color(0xFFFFD700);
  final Color _deepRed = const Color(0xFFC62828);
  final Color _bgGradient1 = const Color(0xFF0A2F1D);
  final Color _bgGradient2 = const Color(0xFF121212);
  final Color _cardColor = const Color(0x1AFFFFFF);
  final Color _borderColor = const Color(0x33FFFFFF);
  final Color _textWhite = const Color(0xFFFFFFFF);
  final Color _textLight = const Color(0xFFE0E0E0);
  final Color _textMuted = const Color(0xFFAAAAAA);
  final Color _offWhite = const Color(0xFFF8F8F8);
  final Color _surfaceColor = const Color(0xFFF5F7FA);
  final Color _successGreen = const Color(0xFF4CAF50);
  final Color _warningOrange = const Color(0xFFFF9800);
  final Color _infoBlue = const Color(0xFF2196F3);

  // Scroll controller
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<ServiceProviderProvider>(context, listen: false);
      provider.getProviderById(widget.providerId);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _fullNameController.dispose();
    _companyNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _descriptionController.dispose();
    _websiteController.dispose();
    _businessHoursController.dispose();
    _yearsOfExperienceController.dispose();
    _licenseNumberController.dispose();
    _specialtiesController.dispose();
    _consultationFeeController.dispose();
    _languageController.dispose();
    _serviceTagController.dispose();
    _serviceAreaController.dispose();
    super.dispose();
  }

  void _loadDataForEditing(ServiceProviderModel provider) {
    // Basic Information
    _fullNameController.text = provider.fullName;
    _companyNameController.text = provider.companyName;
    _phoneController.text = provider.phone;
    _emailController.text = provider.email;
    _addressController.text = provider.address;
    _cityController.text = provider.city;
    _selectedState = provider.state;
    
    // Service Details
    _selectedCategory = provider.serviceCategory;
    _selectedServiceProvider = provider.serviceProvider;
    _selectedSubServiceProvider = provider.subServiceProvider;
    
    // Update available options
    _updateServiceProviders();
    if (_selectedServiceProvider != null) {
      _updateSubServiceProviders();
    }
    
    // Description
    _descriptionController.text = provider.description ?? '';
    _websiteController.text = provider.website ?? '';
    _businessHoursController.text = provider.businessHours ?? '';
    
    // Professional Information
    _yearsOfExperienceController.text = provider.yearsOfExperience ?? '';
    _licenseNumberController.text = provider.licenseNumber ?? '';
    _specialtiesController.text = provider.specialties ?? '';
    _consultationFeeController.text = provider.consultationFee?.toString() ?? '';
    
    // Multi-select values
    _languagesSpoken = List.from(provider.languagesSpoken);
    _serviceTags = List.from(provider.serviceTags);
    _serviceAreas = List.from(provider.serviceAreas);
    
    // Other fields
    _isAvailable = provider.isAvailable;
    _acceptsInsurance = provider.acceptsInsurance ?? false;
    _acceptedPaymentMethods = List.from(provider.acceptedPaymentMethods ?? []);
    
    // Image
    _base64Image = provider.profileImageBase64;
  }

  void _updateServiceProviders() {
    if (_selectedCategory == null) {
      setState(() {
        _availableServiceProviders = [];
        _selectedServiceProvider = null;
        _availableSubServiceProviders = [];
        _selectedSubServiceProvider = null;
      });
      return;
    }

    setState(() {
      _availableServiceProviders = _selectedCategory!.serviceProviders;
      if (!_availableServiceProviders.contains(_selectedServiceProvider)) {
        _selectedServiceProvider = null;
      }
      _updateSubServiceProviders();
    });
  }

  void _updateSubServiceProviders() {
    if (_selectedCategory == null || _selectedServiceProvider == null) {
      setState(() {
        _availableSubServiceProviders = [];
        _selectedSubServiceProvider = null;
      });
      return;
    }

    final subProviders = _selectedCategory!.subServiceProviders[_selectedServiceProvider!];
    
    setState(() {
      _availableSubServiceProviders = subProviders ?? [];
      if (!_availableSubServiceProviders.contains(_selectedSubServiceProvider)) {
        _selectedSubServiceProvider = null;
      }
    });
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _selectedImage = image;
          _isImageLoading = true;
        });
        
        final bytes = await File(image.path).readAsBytes();
        final base64String = base64Encode(bytes);
        
        final mimeType = _getMimeType(image.path);
        final dataUrl = 'data:$mimeType;base64,$base64String';
        
        setState(() {
          _base64Image = dataUrl;
          _isImageLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isImageLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking image: $e'),
          backgroundColor: _primaryRed,
        ),
      );
    }
  }

  String _getMimeType(String filePath) {
    final extension = filePath.split('.').last.toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'bmp':
        return 'image/bmp';
      default:
        return 'image/jpeg';
    }
  }

  Widget _buildEditDialog(BuildContext context, ServiceProviderModel provider) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;
    
    return StatefulBuilder(
      builder: (context, setState) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.symmetric(
            horizontal: isTablet ? 40 : 20,
            vertical: 20,
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: Container(
              constraints: BoxConstraints(
                maxWidth: 600,
                minWidth: 300,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_bgGradient2, _primaryGreen.withOpacity(0.9)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(isTablet ? 25 : 20),
                border: Border.all(color: _borderColor, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 30,
                    offset: const Offset(0, 15),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.all(isTablet ? 24 : 18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          width: isTablet ? 48 : 42,
                          height: isTablet ? 48 : 42,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [_primaryRed, _primaryGreen],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(isTablet ? 12 : 10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.edit_rounded,
                            color: Colors.white,
                            size: isTablet ? 24 : 20,
                          ),
                        ),
                        SizedBox(width: isTablet ? 16 : 12),
                        Expanded(
                          child: Text(
                            'Edit Service Provider',
                            style: GoogleFonts.poppins(
                              fontSize: isTablet ? 22 : 18,
                              fontWeight: FontWeight.w800,
                              color: _textWhite,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: isTablet ? 20 : 16),

                    // Form Fields
                    SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Basic Information Section
                          _buildSectionTitle('Basic Information', isTablet),
                          SizedBox(height: isTablet ? 16 : 12),

                          // State Dropdown
                          _buildDropdownSection(
                            title: 'State',
                            icon: Icons.location_on_rounded,
                            isTablet: isTablet,
                            child: DropdownButton<String>(
                              value: _selectedState,
                              isExpanded: true,
                              dropdownColor: _bgGradient2,
                              underline: const SizedBox(),
                              style: TextStyle(
                                color: _textWhite,
                                fontSize: isTablet ? 16 : 14,
                                fontWeight: FontWeight.w500,
                              ),
                              icon: Icon(
                                Icons.arrow_drop_down_rounded,
                                color: _textMuted,
                                size: isTablet ? 28 : 24,
                              ),
                              selectedItemBuilder: (context) {
                                return CommunityStates.states.map((state) {
                                  return Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      state,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: _textWhite,
                                        fontSize: isTablet ? 16 : 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  );
                                }).toList();
                              },
                              items: CommunityStates.states.map((state) {
                                return DropdownMenuItem<String>(
                                  value: state,
                                  child: Text(
                                    state,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedState = value;
                                });
                              },
                            ),
                          ),
                          SizedBox(height: isTablet ? 16 : 12),

                          // City Text Field
                          _buildTextField(
                            controller: _cityController,
                            labelText: 'City *',
                            prefixIcon: Icons.location_city_rounded,
                            isTablet: isTablet,
                          ),
                          SizedBox(height: isTablet ? 16 : 12),

                          // Service Category Dropdown
                          _buildDropdownSection(
                            title: 'Service Category',
                            icon: Icons.category_rounded,
                            isTablet: isTablet,
                            child: DropdownButton<ServiceCategory>(
                              value: _selectedCategory,
                              isExpanded: true,
                              dropdownColor: _bgGradient2,
                              underline: const SizedBox(),
                              style: TextStyle(
                                color: _textWhite,
                                fontSize: isTablet ? 16 : 14,
                                fontWeight: FontWeight.w500,
                              ),
                              icon: Icon(
                                Icons.arrow_drop_down_rounded,
                                color: _textMuted,
                                size: isTablet ? 28 : 24,
                              ),
                              selectedItemBuilder: (context) {
                                return ServiceCategory.values.map((category) {
                                  return Align(
                                    alignment: Alignment.centerLeft,
                                    child: Row(
                                      children: [
                                        Icon(
                                          category.icon,
                                          color: _primaryRed,
                                          size: isTablet ? 18 : 14,
                                        ),
                                        SizedBox(width: isTablet ? 12 : 8),
                                        Expanded(
                                          child: Text(
                                            category.displayName,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: _textWhite,
                                              fontSize: isTablet ? 16 : 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList();
                              },
                              items: ServiceCategory.values.map((category) {
                                return DropdownMenuItem<ServiceCategory>(
                                  value: category,
                                  child: Row(
                                    children: [
                                      Icon(
                                        category.icon,
                                        color: _primaryRed,
                                        size: isTablet ? 18 : 14,
                                      ),
                                      SizedBox(width: isTablet ? 12 : 8),
                                      Expanded(
                                        child: Text(
                                          category.displayName,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedCategory = value;
                                  _updateServiceProviders();
                                });
                              },
                            ),
                          ),
                          SizedBox(height: isTablet ? 16 : 12),

                          // Service Provider Dropdown
                          if (_selectedCategory != null)
                            Column(
                              children: [
                                _buildDropdownSection(
                                  title: 'Service Provider',
                                  icon: Icons.work_rounded,
                                  isTablet: isTablet,
                                  child: DropdownButton<String>(
                                    value: _selectedServiceProvider,
                                    isExpanded: true,
                                    dropdownColor: _bgGradient2,
                                    underline: const SizedBox(),
                                    style: TextStyle(
                                      color: _textWhite,
                                      fontSize: isTablet ? 16 : 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    icon: Icon(
                                      Icons.arrow_drop_down_rounded,
                                      color: _textMuted,
                                      size: isTablet ? 28 : 24,
                                    ),
                                    selectedItemBuilder: (context) {
                                      return _availableServiceProviders.map((provider) {
                                        return Align(
                                          alignment: Alignment.centerLeft,
                                          child: Text(
                                            provider,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: _textWhite,
                                              fontSize: isTablet ? 16 : 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        );
                                      }).toList();
                                    },
                                    items: _availableServiceProviders.map((provider) {
                                      return DropdownMenuItem<String>(
                                        value: provider,
                                        child: Text(
                                          provider,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedServiceProvider = value;
                                        _updateSubServiceProviders();
                                      });
                                    },
                                  ),
                                ),
                                SizedBox(height: isTablet ? 16 : 12),
                              ],
                            ),

                          // Sub-Service Provider Dropdown
                          if (_selectedServiceProvider != null && _availableSubServiceProviders.isNotEmpty)
                            Column(
                              children: [
                                _buildDropdownSection(
                                  title: 'Sub-Service Provider',
                                  icon: Icons.work_outline_rounded,
                                  isTablet: isTablet,
                                  child: DropdownButton<String?>(
                                    value: _selectedSubServiceProvider,
                                    isExpanded: true,
                                    dropdownColor: _bgGradient2,
                                    underline: const SizedBox(),
                                    style: TextStyle(
                                      color: _textWhite,
                                      fontSize: isTablet ? 16 : 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    icon: Icon(
                                      Icons.arrow_drop_down_rounded,
                                      color: _textMuted,
                                      size: isTablet ? 28 : 24,
                                    ),
                                    selectedItemBuilder: (context) {
                                      return [
                                        null,
                                        ..._availableSubServiceProviders,
                                      ].map((provider) {
                                        return Align(
                                          alignment: Alignment.centerLeft,
                                          child: Text(
                                            provider ?? 'None',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: _textWhite,
                                              fontSize: isTablet ? 16 : 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        );
                                      }).toList();
                                    },
                                    items: [
                                      const DropdownMenuItem<String?>(
                                        value: null,
                                        child: Text(
                                          'None',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      ..._availableSubServiceProviders.map((provider) {
                                        return DropdownMenuItem<String?>(
                                          value: provider,
                                          child: Text(
                                            provider,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        );
                                      }),
                                    ],
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedSubServiceProvider = value;
                                      });
                                    },
                                  ),
                                ),
                                SizedBox(height: isTablet ? 16 : 12),
                              ],
                            ),

                          // Profile Image
                          _buildImagePicker(isTablet, setState),
                          SizedBox(height: isTablet ? 16 : 12),

                          // Provider Details Section
                          _buildSectionTitle('Provider Details', isTablet),
                          SizedBox(height: isTablet ? 16 : 12),

                          // Name and Company
                          _buildTextField(
                            controller: _fullNameController,
                            labelText: 'Full Name *',
                            prefixIcon: Icons.person_rounded,
                            isTablet: isTablet,
                          ),
                          SizedBox(height: isTablet ? 16 : 12),

                          _buildTextField(
                            controller: _companyNameController,
                            labelText: 'Company Name',
                            prefixIcon: Icons.business_rounded,
                            isTablet: isTablet,
                          ),
                          SizedBox(height: isTablet ? 16 : 12),

                          // Contact Information
                          _buildTextField(
                            controller: _phoneController,
                            labelText: 'Enter a valid US number *',
                            prefixIcon: Icons.phone_rounded,
                            keyboardType: TextInputType.phone,
                            isTablet: isTablet,
                          ),
                          SizedBox(height: isTablet ? 16 : 12),

                          _buildTextField(
                            controller: _emailController,
                            labelText: 'Email *',
                            prefixIcon: Icons.email_rounded,
                            keyboardType: TextInputType.emailAddress,
                            isTablet: isTablet,
                          ),
                          SizedBox(height: isTablet ? 16 : 12),

                          _buildTextField(
                            controller: _addressController,
                            labelText: 'Address *',
                            prefixIcon: Icons.home_rounded,
                            maxLines: 2,
                            isTablet: isTablet,
                          ),
                          SizedBox(height: isTablet ? 16 : 12),

                          // Description
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(isTablet ? 12 : 10),
                              border: Border.all(color: _borderColor, width: 1.2),
                            ),
                            child: TextFormField(
                              controller: _descriptionController,
                              maxLines: 3,
                              style: TextStyle(
                                color: _textWhite,
                                fontSize: isTablet ? 16 : 14,
                              ),
                              decoration: InputDecoration(
                                labelText: 'Description',
                                labelStyle: TextStyle(
                                  color: _textMuted,
                                  fontSize: isTablet ? 14 : 12,
                                ),
                                alignLabelWithHint: true,
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.all(isTablet ? 18 : 14),
                                prefixIcon: Padding(
                                  padding: const EdgeInsets.only(top: 16),
                                  child: Icon(
                                    Icons.description_rounded,
                                    color: _primaryRed,
                                    size: isTablet ? 22 : 18,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: isTablet ? 16 : 12),

                          // Website and Business Hours
                          _buildTextField(
                            controller: _websiteController,
                            labelText: 'Website',
                            prefixIcon: Icons.language_rounded,
                            keyboardType: TextInputType.url,
                            isTablet: isTablet,
                          ),
                          SizedBox(height: isTablet ? 16 : 12),

                          _buildTextField(
                            controller: _businessHoursController,
                            labelText: 'Business Hours',
                            prefixIcon: Icons.access_time_rounded,
                            isTablet: isTablet,
                          ),
                          SizedBox(height: isTablet ? 16 : 12),

                          // Professional Information Section
                          _buildSectionTitle('Professional Information', isTablet),
                          SizedBox(height: isTablet ? 16 : 12),

                          // Professional Fields
                          _buildTextField(
                            controller: _yearsOfExperienceController,
                            labelText: 'Years of Experience',
                            prefixIcon: Icons.timeline_rounded,
                            isTablet: isTablet,
                          ),
                          SizedBox(height: isTablet ? 16 : 12),

                          _buildTextField(
                            controller: _licenseNumberController,
                            labelText: 'License Number',
                            prefixIcon: Icons.badge_rounded,
                            isTablet: isTablet,
                          ),
                          SizedBox(height: isTablet ? 16 : 12),

                          _buildTextField(
                            controller: _specialtiesController,
                            labelText: 'Specialties',
                            prefixIcon: Icons.star_rounded,
                            maxLines: 2,
                            isTablet: isTablet,
                          ),
                          SizedBox(height: isTablet ? 16 : 12),

                          _buildTextField(
                            controller: _consultationFeeController,
                            labelText: 'Consultation Fee (\$)',
                            prefixIcon: Icons.attach_money_rounded,
                            keyboardType: TextInputType.number,
                            isTablet: isTablet,
                          ),
                          SizedBox(height: isTablet ? 16 : 12),

                          // Availability Checkbox
                          _buildCheckbox(
                            value: _isAvailable,
                            label: 'Available for Service',
                            onChanged: (value) {
                              setState(() {
                                _isAvailable = value ?? true;
                              });
                            },
                            isTablet: isTablet,
                          ),
                          SizedBox(height: isTablet ? 16 : 12),

                          // Insurance Checkbox
                          _buildCheckbox(
                            value: _acceptsInsurance,
                            label: 'Accepts Insurance',
                            onChanged: (value) {
                              setState(() {
                                _acceptsInsurance = value ?? false;
                              });
                            },
                            isTablet: isTablet,
                          ),
                          SizedBox(height: isTablet ? 16 : 12),

                          // Multi-select Fields
                          _buildMultiSelectField(
                            title: 'Languages Spoken',
                            items: _languagesSpoken,
                            controller: _languageController,
                            hintText: 'Add language',
                            onAdd: (item) {
                              setState(() {
                                if (item.isNotEmpty && !_languagesSpoken.contains(item)) {
                                  _languagesSpoken.add(item);
                                  _languageController.clear();
                                }
                              });
                            },
                            onRemove: (item) {
                              setState(() {
                                _languagesSpoken.remove(item);
                              });
                            },
                            isTablet: isTablet,
                          ),
                          SizedBox(height: isTablet ? 16 : 12),

                          _buildMultiSelectField(
                            title: 'Service Tags',
                            items: _serviceTags,
                            controller: _serviceTagController,
                            hintText: 'Add tag',
                            onAdd: (item) {
                              setState(() {
                                if (item.isNotEmpty && !_serviceTags.contains(item)) {
                                  _serviceTags.add(item);
                                  _serviceTagController.clear();
                                }
                              });
                            },
                            onRemove: (item) {
                              setState(() {
                                _serviceTags.remove(item);
                              });
                            },
                            isTablet: isTablet,
                          ),
                          SizedBox(height: isTablet ? 16 : 12),

                          _buildMultiSelectField(
                            title: 'Service Areas',
                            items: _serviceAreas,
                            controller: _serviceAreaController,
                            hintText: 'Add service area',
                            onAdd: (item) {
                              setState(() {
                                if (item.isNotEmpty && !_serviceAreas.contains(item)) {
                                  _serviceAreas.add(item);
                                  _serviceAreaController.clear();
                                }
                              });
                            },
                            onRemove: (item) {
                              setState(() {
                                _serviceAreas.remove(item);
                              });
                            },
                            isTablet: isTablet,
                          ),
                          SizedBox(height: isTablet ? 16 : 12),

                          // Payment Methods
                          _buildPaymentMethods(isTablet, setState),
                        ],
                      ),
                    ),
                    SizedBox(height: isTablet ? 20 : 16),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _isEditing = false;
                                });
                                Navigator.pop(context);
                              },
                              borderRadius: BorderRadius.circular(isTablet ? 12 : 10),
                              child: Container(
                                padding: EdgeInsets.symmetric(vertical: isTablet ? 16 : 12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(isTablet ? 12 : 10),
                                  border: Border.all(color: _borderColor, width: 1.2),
                                ),
                                child: Center(
                                  child: Text(
                                    'Cancel',
                                    style: TextStyle(
                                      color: _textMuted,
                                      fontWeight: FontWeight.w800,
                                      fontSize: isTablet ? 16 : 14,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: isTablet ? 16 : 12),
                        Expanded(
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _isSaving ? null : () => _updateService(provider, setState),
                              borderRadius: BorderRadius.circular(isTablet ? 12 : 10),
                              child: Container(
                                padding: EdgeInsets.symmetric(vertical: isTablet ? 16 : 12),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [_primaryGreen, _darkGreen],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                                  borderRadius: BorderRadius.circular(isTablet ? 12 : 10),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _primaryGreen.withOpacity(0.4),
                                      blurRadius: 12,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: _isSaving
                                      ? SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            color: Colors.white,
                                          ),
                                        )
                                      : Text(
                                        'Save Changes',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                          fontSize: isTablet ? 15 : 13,
                                        ),
                                      ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title, bool isTablet) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: isTablet ? 18 : 16,
        fontWeight: FontWeight.w700,
        color: _textWhite,
      ),
      textAlign: TextAlign.left,
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required IconData prefixIcon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    required bool isTablet,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(isTablet ? 12 : 10),
        border: Border.all(color: _borderColor, width: 1.2),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        style: TextStyle(
          color: _textWhite,
          fontSize: isTablet ? 16 : 14,
        ),
        decoration: InputDecoration(
          labelText: labelText,
          labelStyle: TextStyle(
            color: _textMuted,
            fontSize: isTablet ? 14 : 12,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(isTablet ? 18 : 14),
          prefixIcon: Container(
            width: isTablet ? 20 : 18,
            height: isTablet ? 20 : 18,
            alignment: Alignment.center,
            child: Icon(
              prefixIcon,
              color: _primaryRed,
              size: isTablet ? 20 : 16,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownSection({
    required String title,
    required Widget child,
    required IconData icon,
    required bool isTablet,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 18 : 12,
        vertical: isTablet ? 14 : 10,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(isTablet ? 12 : 10),
        border: Border.all(color: _borderColor, width: 1.2),
      ),
      child: Row(
        children: [
          Container(
            width: isTablet ? 40 : 32,
            height: isTablet ? 40 : 32,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_primaryRed.withOpacity(0.2), _primaryGreen.withOpacity(0.2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(isTablet ? 10 : 8),
            ),
            child: Center(
              child: Icon(
                icon,
                color: _primaryRed,
                size: isTablet ? 20 : 16,
              ),
            ),
          ),
          SizedBox(width: isTablet ? 16 : 12),
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _buildImagePicker(bool isTablet, StateSetter setState) {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        padding: EdgeInsets.all(isTablet ? 18 : 14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(isTablet ? 12 : 10),
          border: Border.all(
            color: (_selectedImage != null || _base64Image != null) ? _primaryGreen : _borderColor,
            width: (_selectedImage != null || _base64Image != null) ? 2 : 1.2,
          ),
        ),
        child: Column(
          children: [
            if (_selectedImage != null || _base64Image != null)
              Column(
                children: [
                  Container(
                    height: isTablet ? 140 : 110,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(isTablet ? 10 : 8),
                      image: DecorationImage(
                        image: _selectedImage != null
                            ? FileImage(File(_selectedImage!.path))
                            : MemoryImage(base64Decode(_base64Image!.split(',').last)) as ImageProvider,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  SizedBox(height: isTablet ? 16 : 12),
                ],
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: isTablet ? 50 : 42,
                  height: isTablet ? 50 : 42,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: (_selectedImage != null || _base64Image != null)
                        ? [_primaryGreen, _darkGreen]
                        : [_primaryRed, _deepRed],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(isTablet ? 12 : 10),
                    boxShadow: [
                      BoxShadow(
                        color: ((_selectedImage != null || _base64Image != null) ? _primaryGreen : _primaryRed).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      (_selectedImage != null || _base64Image != null) ? Icons.image_rounded : Icons.add_photo_alternate_rounded,
                      color: Colors.white,
                      size: isTablet ? 24 : 20,
                    ),
                  ),
                ),
                SizedBox(width: isTablet ? 16 : 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (_selectedImage != null || _base64Image != null) ? 'Profile Image Selected' : 'Upload Profile Image',
                        style: TextStyle(
                          color: (_selectedImage != null || _base64Image != null) ? _primaryGreen : _textWhite,
                          fontSize: isTablet ? 16 : 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        (_selectedImage != null || _base64Image != null) ? 'Tap to change image' : 'Recommended headshot photo',
                        style: TextStyle(
                          color: _textMuted,
                          fontSize: isTablet ? 13 : 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (_isImageLoading)
              Padding(
                padding: EdgeInsets.only(top: isTablet ? 16 : 12),
                child: CircularProgressIndicator(
                  color: _primaryGreen,
                  strokeWidth: 2.5,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckbox({
    required bool value,
    required String label,
    required ValueChanged<bool?> onChanged,
    required bool isTablet,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onChanged(!value),
        borderRadius: BorderRadius.circular(isTablet ? 12 : 10),
        child: Container(
          padding: EdgeInsets.all(isTablet ? 16 : 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(isTablet ? 12 : 10),
            border: Border.all(
              color: value ? _primaryGreen : _borderColor,
              width: value ? 1.5 : 1.2,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: isTablet ? 24 : 20,
                height: isTablet ? 24 : 20,
                decoration: BoxDecoration(
                  color: value ? _primaryGreen : Colors.transparent,
                  borderRadius: BorderRadius.circular(isTablet ? 6 : 5),
                  border: Border.all(
                    color: value ? _primaryGreen : Colors.grey,
                    width: 1.5,
                  ),
                ),
                child: value
                    ? Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: isTablet ? 16 : 12,
                      )
                    : null,
              ),
              SizedBox(width: isTablet ? 16 : 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: _textWhite,
                    fontSize: isTablet ? 16 : 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMultiSelectField({
    required String title,
    required List<String> items,
    required TextEditingController controller,
    required String hintText,
    required Function(String) onAdd,
    required Function(String) onRemove,
    required bool isTablet,
  }) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 16 : 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(isTablet ? 12 : 10),
        border: Border.all(color: _borderColor, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: _textWhite,
              fontSize: isTablet ? 16 : 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(isTablet ? 10 : 8),
                    border: Border.all(color: _borderColor),
                  ),
                  child: TextFormField(
                    controller: controller,
                    style: TextStyle(
                      color: _textWhite,
                      fontSize: isTablet ? 14 : 12,
                    ),
                    decoration: InputDecoration(
                      hintText: hintText,
                      hintStyle: TextStyle(color: _textMuted),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(isTablet ? 14 : 10),
                    ),
                    onFieldSubmitted: (value) {
                      onAdd(value);
                    },
                  ),
                ),
              ),
              SizedBox(width: isTablet ? 10 : 8),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    onAdd(controller.text.trim());
                  },
                  borderRadius: BorderRadius.circular(isTablet ? 10 : 8),
                  child: Container(
                    width: isTablet ? 42 : 36,
                    height: isTablet ? 42 : 36,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_primaryRed, _primaryGreen],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(isTablet ? 10 : 8),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.add_rounded,
                        color: Colors.white,
                        size: isTablet ? 20 : 16,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (items.isNotEmpty) SizedBox(height: 10),
          if (items.isNotEmpty)
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: items.map((item) {
                return Chip(
                  label: Text(
                    item,
                    style: TextStyle(fontSize: isTablet ? 12 : 10),
                  ),
                  onDeleted: () => onRemove(item),
                  backgroundColor: _primaryGreen.withOpacity(0.2),
                  deleteIconColor: _primaryRed,
                  deleteIcon: Icon(Icons.close, size: isTablet ? 16 : 12),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethods(bool isTablet, StateSetter setState) {
    final paymentMethods = ['Cash', 'Credit Card', 'Debit Card', 'Check', 'Online Payment', 'Bank Transfer'];
    
    return Container(
      padding: EdgeInsets.all(isTablet ? 16 : 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(isTablet ? 12 : 10),
        border: Border.all(color: _borderColor, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Accepted Payment Methods',
            style: TextStyle(
              color: _textWhite,
              fontSize: isTablet ? 16 : 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: paymentMethods.map((method) {
              return FilterChip(
                label: Text(
                  method,
                  style: TextStyle(fontSize: isTablet ? 12 : 10),
                ),
                selected: _acceptedPaymentMethods.contains(method),
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _acceptedPaymentMethods.add(method);
                    } else {
                      _acceptedPaymentMethods.remove(method);
                    }
                  });
                },
                selectedColor: _primaryGreen.withOpacity(0.3),
                checkmarkColor: Colors.white,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Future<void> _updateService(ServiceProviderModel provider, StateSetter setState) async {
    if (_selectedCategory == null || _selectedServiceProvider == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select category and service provider'),
          backgroundColor: _primaryRed,
        ),
      );
      return;
    }

    if (_fullNameController.text.isEmpty ||
        _phoneController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _addressController.text.isEmpty ||
        _cityController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fill all required fields'),
          backgroundColor: _primaryRed,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final providerProvider = Provider.of<ServiceProviderProvider>(context, listen: false);
      
      final updatedProvider = provider.copyWith(
        fullName: _fullNameController.text.trim(),
        companyName: _companyNameController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        address: _addressController.text.trim(),
        state: _selectedState!,
        city: _cityController.text.trim(),
        serviceCategory: _selectedCategory!,
        serviceProvider: _selectedServiceProvider!,
        subServiceProvider: _selectedSubServiceProvider,
        profileImageBase64: _base64Image ?? provider.profileImageBase64,
        description: _descriptionController.text.trim(),
        website: _websiteController.text.trim(),
        businessHours: _businessHoursController.text.trim(),
        yearsOfExperience: _yearsOfExperienceController.text.trim(),
        languagesSpoken: _languagesSpoken,
        serviceTags: _serviceTags,
        serviceAreas: _serviceAreas,
        isAvailable: _isAvailable,
        acceptsInsurance: _acceptsInsurance,
        acceptedPaymentMethods: _acceptedPaymentMethods,
        licenseNumber: _licenseNumberController.text.trim(),
        specialties: _specialtiesController.text.trim(),
        consultationFee: double.tryParse(_consultationFeeController.text.trim()),
        updatedAt: DateTime.now(),
      );

      final success = await providerProvider.updateServiceProvider(provider.id!, updatedProvider);
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Service updated successfully!'),
            backgroundColor: _primaryGreen,
          ),
        );
        setState(() {
          _isEditing = false;
        });
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update service'),
            backgroundColor: _primaryRed,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: _primaryRed,
        ),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _showDeleteDialog(BuildContext context, ServiceProviderModel provider) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: EdgeInsets.all(isTablet ? 24 : 18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_bgGradient2, _primaryGreen.withOpacity(0.9)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(isTablet ? 24 : 20),
            border: Border.all(color: _borderColor, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 30,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: isTablet ? 64 : 52,
                height: isTablet ? 64 : 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: provider.isDeleted ? [_successGreen, const Color(0xFF2E7D32)] : [_primaryRed, _deepRed],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (provider.isDeleted ? _successGreen : _primaryRed).withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Icon(
                  provider.isDeleted ? Icons.restore_rounded : Icons.delete_forever_rounded,
                  color: Colors.white,
                  size: isTablet ? 32 : 26,
                ),
              ),
              SizedBox(height: isTablet ? 20 : 16),
              Text(
                provider.isDeleted ? 'Restore Service Provider' : 'Delete Service Provider',
                style: GoogleFonts.poppins(
                  fontSize: isTablet ? 22 : 18,
                  fontWeight: FontWeight.w800,
                  color: _textWhite,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: isTablet ? 12 : 10),
              Text(
                provider.isDeleted
                    ? 'Are you sure you want to restore ${provider.fullName}? This will make them available to users again.'
                    : 'Are you sure you want to delete ${provider.fullName}? This action cannot be undone.',
                style: GoogleFonts.inter(
                  fontSize: isTablet ? 15 : 13,
                  color: _textMuted,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: isTablet ? 24 : 20),
              Row(
                children: [
                  Expanded(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => Navigator.pop(context),
                        borderRadius: BorderRadius.circular(isTablet ? 12 : 10),
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: isTablet ? 14 : 10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(isTablet ? 12 : 10),
                            border: Border.all(color: _borderColor, width: 1.2),
                          ),
                          child: Center(
                            child: Text(
                              'Cancel',
                              style: GoogleFonts.inter(
                                fontSize: isTablet ? 16 : 14,
                                fontWeight: FontWeight.w700,
                                color: _textMuted,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: isTablet ? 16 : 12),
                  Expanded(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () async {
                          final providerProvider = Provider.of<ServiceProviderProvider>(context, listen: false);
                          if (provider.isDeleted) {
                            await providerProvider.updateServiceProvider(
                              provider.id!,
                              provider.copyWith(isDeleted: false, updatedAt: DateTime.now()),
                            );
                          } else {
                            await providerProvider.deleteServiceProvider(provider.id!);
                          }
                          Navigator.pop(context);
                          Navigator.pop(context);
                        },
                        borderRadius: BorderRadius.circular(isTablet ? 12 : 10),
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: isTablet ? 14 : 10),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: provider.isDeleted ? [_successGreen, const Color(0xFF2E7D32)] : [_primaryRed, _deepRed],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(isTablet ? 12 : 10),
                            boxShadow: [
                              BoxShadow(
                                color: (provider.isDeleted ? _successGreen : _primaryRed).withOpacity(0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              provider.isDeleted ? 'Restore' : 'Delete',
                              style: GoogleFonts.inter(
                                fontSize: isTablet ? 16 : 14,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isTablet = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: isTablet ? 8 : 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: isTablet ? 14 : 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: isTablet ? 16 : 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumDetailSection({
    required String title,
    required IconData icon,
    required Widget child,
    required bool isTablet,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: isTablet ? 36 : 30,
              height: isTablet ? 36 : 30,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_primaryRed, _primaryGreen],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(isTablet ? 10 : 8),
              ),
              child: Center(
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: isTablet ? 18 : 14,
                ),
              ),
            ),
            SizedBox(width: isTablet ? 10 : 8),
            Text(
              title,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: isTablet ? 20 : 16,
                fontWeight: FontWeight.w800,
                color: Colors.black,
              ),
            ),
          ],
        ),
        SizedBox(height: isTablet ? 16 : 12),
        child,
      ],
    );
  }

  Widget _buildPremiumDetailCard({
    required IconData icon,
    required String title,
    required String value,
    required List<Color> gradientColors,
    required bool isTablet,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
        child: Container(
          padding: EdgeInsets.all(isTablet ? 18 : 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
            border: Border.all(color: _borderColor, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: isTablet ? 48 : 40,
                height: isTablet ? 48 : 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradientColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(isTablet ? 12 : 10),
                  boxShadow: [
                    BoxShadow(
                      color: gradientColors.first.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: isTablet ? 22 : 18,
                  ),
                ),
              ),
              SizedBox(width: isTablet ? 16 : 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: isTablet ? 14 : 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: GoogleFonts.inter(
                        fontSize: isTablet ? 16 : 14,
                        fontWeight: FontWeight.w700,
                        color: onTap != null ? Colors.blue : Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.grey[400],
                  size: isTablet ? 22 : 18,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumContactItem({
    required IconData icon,
    required String title,
    required String value,
    required bool isTablet,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(isTablet ? 10 : 8),
        child: Container(
          padding: EdgeInsets.all(isTablet ? 14 : 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(isTablet ? 10 : 8),
            border: Border.all(color: _borderColor, width: 0.8),
          ),
          child: Row(
            children: [
              Container(
                width: isTablet ? 40 : 32,
                height: isTablet ? 40 : 32,
                decoration: BoxDecoration(
                  color: _primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(isTablet ? 10 : 8),
                ),
                child: Center(
                  child: Icon(
                    icon,
                    color: _primaryGreen,
                    size: isTablet ? 18 : 14,
                  ),
                ),
              ),
              SizedBox(width: isTablet ? 14 : 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: isTablet ? 12 : 10,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: GoogleFonts.inter(
                        fontSize: isTablet ? 16 : 14,
                        fontWeight: FontWeight.w600,
                        color: onTap != null ? Colors.blue : Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.grey[400],
                  size: isTablet ? 20 : 16,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChipGrid(List<String> items, bool isTablet) {
    return Wrap(
      spacing: isTablet ? 8 : 6,
      runSpacing: isTablet ? 8 : 6,
      children: items.map((item) {
        return Chip(
          label: Text(
            item,
            style: GoogleFonts.inter(
              fontSize: isTablet ? 13 : 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: _primaryGreen.withOpacity(0.1),
          side: BorderSide(color: _primaryGreen),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildGalleryImages(List<String> galleryImagesBase64, bool isTablet) {
    return SizedBox(
      height: isTablet ? 110 : 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: galleryImagesBase64.length,
        itemBuilder: (context, index) {
          try {
            final base64 = galleryImagesBase64[index];
            final cleanedBase64 = _cleanBase64String(base64);
            final bytes = base64Decode(cleanedBase64);
            return Container(
              width: isTablet ? 100 : 80,
              height: isTablet ? 100 : 80,
              margin: EdgeInsets.only(right: isTablet ? 12 : 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
                image: DecorationImage(
                  image: MemoryImage(bytes),
                  fit: BoxFit.cover,
                ),
                border: Border.all(color: _borderColor, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
            );
          } catch (e) {
            return Container(
              width: isTablet ? 100 : 80,
              height: isTablet ? 100 : 80,
              margin: EdgeInsets.only(right: isTablet ? 12 : 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
                color: Colors.grey.shade200,
                border: Border.all(color: _borderColor),
              ),
              child: Center(
                child: Icon(
                  Icons.broken_image_rounded,
                  color: Colors.grey[400],
                  size: isTablet ? 32 : 24,
                ),
              ),
            );
          }
        },
      ),
    );
  }

  String _cleanBase64String(String base64) {
    String cleaned = base64.trim();
    if (cleaned.contains(',')) {
      cleaned = cleaned.split(',').last;
    }
    return cleaned;
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ServiceProviderProvider>(context);
    final serviceProvider = provider.selectedProvider;
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenHeight < 700;
    final isTablet = screenWidth >= 600;

    if (_isEditing && serviceProvider != null) {
      _loadDataForEditing(serviceProvider);
      return _buildEditDialog(context, serviceProvider);
    }

    if (provider.isLoading && serviceProvider == null) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [_bgGradient1, _bgGradient2, _primaryGreen],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: isTablet ? 60 : 48,
                  height: isTablet ? 60 : 48,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: _primaryGreen,
                  ),
                ),
                SizedBox(height: isTablet ? 20 : 16),
                Text(
                  'Loading Service Provider...',
                  style: GoogleFonts.poppins(
                    fontSize: isTablet ? 20 : 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (serviceProvider == null) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [_bgGradient1, _bgGradient2, _primaryGreen],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: isTablet ? 100 : 80,
                  height: isTablet ? 100 : 80,
                  decoration: BoxDecoration(
                    color: _primaryRed.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.error_outline_rounded,
                    size: isTablet ? 48 : 40,
                    color: _primaryRed,
                  ),
                ),
                SizedBox(height: isTablet ? 20 : 16),
                Text(
                  'Service Provider Not Found',
                  style: GoogleFonts.poppins(
                    fontSize: isTablet ? 20 : 16,
                    fontWeight: FontWeight.w800,
                    color: _primaryRed,
                  ),
                ),
                SizedBox(height: isTablet ? 12 : 10),
                Text(
                  'The requested service provider could not be found',
                  style: GoogleFonts.inter(
                    fontSize: isTablet ? 14 : 12,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: isTablet ? 20 : 16),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(isTablet ? 12 : 10),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isTablet ? 28 : 20,
                        vertical: isTablet ? 14 : 10,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [_primaryGreen, _darkGreen],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(isTablet ? 12 : 10),
                        boxShadow: [
                          BoxShadow(
                            color: _primaryGreen.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Text(
                        'Go Back',
                        style: GoogleFonts.inter(
                          fontSize: isTablet ? 16 : 14,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      floatingActionButton: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _isEditing = true;
            });
          },
          borderRadius: BorderRadius.circular(isTablet ? 16 : 14),
          child: Container(
            width: isTablet ? 56 : 48,
            height: isTablet ? 56 : 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_primaryRed, _primaryGreen],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(isTablet ? 14 : 12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(
              Icons.edit_rounded,
              color: Colors.white,
              size: isTablet ? 26 : 22,
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              _bgGradient1,
              _bgGradient2,
              _primaryGreen,
            ],
          ),
        ),
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // Premium Sliver App Bar
            SliverAppBar(
              expandedHeight: isTablet ? 320 : 260,
              collapsedHeight: isTablet ? 100 : 80,
              floating: false,
              pinned: true,
              snap: false,
              elevation: 0,
              backgroundColor: Colors.transparent,
              leading: Container(
                margin: const EdgeInsets.only(left: 16),
                child: Material(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 40,
                      height: 40,
                      child: Center(
                        child: Icon(
                          Icons.arrow_back_rounded,
                          color: Colors.white,
                          size: isTablet ? 24 : 20,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              actions: [
                PopupMenuButton(
                  icon: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.more_vert_rounded,
                      color: Colors.white,
                      size: isTablet ? 22 : 18,
                    ),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
                  ),
                  color: _bgGradient2,
                  elevation: 6,
                  onSelected: (value) async {
                    final providerProvider = Provider.of<ServiceProviderProvider>(context, listen: false);
                    
                    switch (value) {
                      case 'edit':
                        setState(() {
                          _isEditing = true;
                        });
                        break;
                      case 'availability':
                        await providerProvider.toggleAvailability(
                          serviceProvider.id!,
                          !serviceProvider.isAvailable,
                        );
                        break;
                      case 'verification':
                        await providerProvider.toggleVerification(
                          serviceProvider.id!,
                          !serviceProvider.isVerified,
                        );
                        break;
                      case 'delete':
                        _showDeleteDialog(context, serviceProvider);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [_primaryRed, _primaryGreen],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(
                              Icons.edit_rounded,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Edit',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'availability',
                      child: Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: serviceProvider.isAvailable
                                  ? [_warningOrange, const Color(0xFFEF6C00)]
                                  : [_successGreen, const Color(0xFF2E7D32)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(
                              serviceProvider.isAvailable ? Icons.block : Icons.check_circle_rounded,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            serviceProvider.isAvailable ? 'Make Inactive' : 'Make Active',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'verification',
                      child: Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: serviceProvider.isVerified
                                  ? [_infoBlue, const Color(0xFF1565C0)]
                                  : [_warningOrange, const Color(0xFFEF6C00)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(
                              serviceProvider.isVerified ? Icons.verified_outlined : Icons.verified,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            serviceProvider.isVerified ? 'Unverify' : 'Verify',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: serviceProvider.isDeleted
                                  ? [_successGreen, const Color(0xFF2E7D32)]
                                  : [_primaryRed, _deepRed],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(
                              serviceProvider.isDeleted ? Icons.restore_rounded : Icons.delete_rounded,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            serviceProvider.isDeleted ? 'Restore' : 'Delete',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  children: [
                    // Profile Image - Centered
                    Center(
                      child: Container(
                        margin: EdgeInsets.only(top: isTablet ? 80 : 60),
                        width: isTablet ? 140 : 110,
                        height: isTablet ? 140 : 110,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: _goldAccent, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: serviceProvider.getProfileImageWidget(),
                        ),
                      ),
                    ),
                    
                    // Gradient Overlay
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.black.withOpacity(0.7),
                            Colors.black.withOpacity(0.4),
                            Colors.transparent,
                            Colors.black.withOpacity(0.6),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: const [0.0, 0.3, 0.6, 1.0],
                        ),
                      ),
                    ),
                    
                    // Verified Badge
                    if (serviceProvider.isVerified)
                      Positioned(
                        top: isTablet ? 140 : 110,
                        left: isTablet ? 40 : 20,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isTablet ? 16 : 12,
                            vertical: isTablet ? 8 : 6,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [_successGreen, const Color(0xFF2E7D32)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.verified_rounded,
                                color: Colors.white,
                                size: isTablet ? 16 : 12,
                              ),
                              SizedBox(width: isTablet ? 6 : 4),
                              Text(
                                'VERIFIED',
                                style: GoogleFonts.inter(
                                  fontSize: isTablet ? 12 : 10,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    
                    // Status Badge
                    Positioned(
                      top: isTablet ? 140 : 110,
                      right: isTablet ? 40 : 20,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isTablet ? 16 : 12,
                          vertical: isTablet ? 8 : 6,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: serviceProvider.isAvailable
                              ? [_successGreen, const Color(0xFF2E7D32)]
                              : [_warningOrange, const Color(0xFFEF6C00)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Text(
                          serviceProvider.isAvailable ? 'AVAILABLE' : 'NOT AVAILABLE',
                          style: GoogleFonts.inter(
                            fontSize: isTablet ? 12 : 10,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ),
                    
                    // Deleted Badge
                    if (serviceProvider.isDeleted)
                      Positioned(
                        bottom: isTablet ? 100 : 80,
                        left: isTablet ? 40 : 20,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isTablet ? 20 : 16,
                            vertical: isTablet ? 10 : 8,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [_primaryRed, _deepRed],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.delete_rounded,
                                color: Colors.white,
                                size: isTablet ? 16 : 12,
                              ),
                              SizedBox(width: isTablet ? 6 : 4),
                              Text(
                                'DELETED',
                                style: GoogleFonts.inter(
                                  fontSize: isTablet ? 12 : 10,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    
                    // Profile Info Overlay
                    Positioned(
                      bottom: isTablet ? 30 : 20,
                      left: isTablet ? 40 : 20,
                      right: isTablet ? 40 : 20,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            serviceProvider.fullName,
                            style: GoogleFonts.poppins(
                              fontSize: isTablet ? 28 : 22,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.5,
                              shadows: [
                                Shadow(
                                  blurRadius: 8,
                                  color: Colors.black.withOpacity(0.5),
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: isTablet ? 8 : 6),
                          Text(
                            serviceProvider.companyName,
                            style: GoogleFonts.inter(
                              fontSize: isTablet ? 16 : 14,
                              color: Colors.white.withOpacity(0.9),
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: isTablet ? 12 : 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isTablet ? 14 : 10,
                                  vertical: isTablet ? 6 : 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(isTablet ? 10 : 8),
                                  border: Border.all(color: Colors.red),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.favorite_rounded,
                                      color: Colors.red,
                                      size: isTablet ? 16 : 12,
                                    ),
                                    SizedBox(width: isTablet ? 4 : 2),
                                    Text(
                                      '${serviceProvider.totalLikes}',
                                      style: GoogleFonts.inter(
                                        fontSize: isTablet ? 14 : 12,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: isTablet ? 10 : 8),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isTablet ? 14 : 10,
                                  vertical: isTablet ? 6 : 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _primaryGreen.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(isTablet ? 10 : 8),
                                  border: Border.all(color: _primaryGreen),
                                ),
                                child: Text(
                                  '⭐ ${serviceProvider.rating ?? 4.5}',
                                  style: GoogleFonts.inter(
                                    fontSize: isTablet ? 14 : 12,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Premium Content
            SliverToBoxAdapter(
              child: Container(
                decoration: BoxDecoration(
                  color: _surfaceColor,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(isTablet ? 40 : 32),
                    topRight: Radius.circular(isTablet ? 40 : 32),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 30,
                      spreadRadius: 3,
                    ),
                  ],
                ),
                child: Padding(
                  padding: EdgeInsets.all(isTablet ? 24 : 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: isTablet ? 16 : 12),
                      
                      // Service Details Section
                      _buildPremiumDetailSection(
                        title: 'Service Details',
                        icon: Icons.handyman_rounded,
                        child: Column(
                          children: [
                            // Service Category Card
                            _buildPremiumDetailCard(
                              icon: serviceProvider.serviceCategory.icon,
                              title: 'Service Category',
                              value: serviceProvider.serviceCategory.displayName,
                              gradientColors: [_primaryRed, _primaryGreen],
                              isTablet: isTablet,
                            ),
                            SizedBox(height: isTablet ? 16 : 12),
                            
                            // Service Provider Card
                            _buildPremiumDetailCard(
                              icon: Icons.work_rounded,
                              title: 'Service Provider',
                              value: serviceProvider.serviceProvider,
                              gradientColors: [_primaryGreen, _darkGreen],
                              isTablet: isTablet,
                            ),
                            SizedBox(height: isTablet ? 16 : 12),
                            
                            // Sub-Service Provider Card
                            if (serviceProvider.subServiceProvider != null)
                              Column(
                                children: [
                                  _buildPremiumDetailCard(
                                    icon: Icons.work_outline_rounded,
                                    title: 'Sub-Service Provider',
                                    value: serviceProvider.subServiceProvider!,
                                    gradientColors: [_goldAccent, Colors.orange],
                                    isTablet: isTablet,
                                  ),
                                  SizedBox(height: isTablet ? 16 : 12),
                                ],
                              ),
                            
                            // Years of Experience
                            if (serviceProvider.yearsOfExperience != null && serviceProvider.yearsOfExperience!.isNotEmpty)
                              Container(
                                padding: EdgeInsets.all(isTablet ? 18 : 14),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
                                  border: Border.all(color: _borderColor, width: 1.2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.08),
                                      blurRadius: 12,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: isTablet ? 48 : 40,
                                      height: isTablet ? 48 : 40,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [_infoBlue, const Color(0xFF1565C0)],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(isTablet ? 12 : 10),
                                        boxShadow: [
                                          BoxShadow(
                                            color: _infoBlue.withOpacity(0.3),
                                            blurRadius: 8,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: Icon(
                                          Icons.timeline_rounded,
                                          color: Colors.white,
                                          size: isTablet ? 22 : 18,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: isTablet ? 16 : 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Years of Experience',
                                            style: GoogleFonts.inter(
                                              fontSize: isTablet ? 14 : 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            serviceProvider.yearsOfExperience!,
                                            style: GoogleFonts.inter(
                                              fontSize: isTablet ? 20 : 16,
                                              fontWeight: FontWeight.w800,
                                              color: Colors.black,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        isTablet: isTablet,
                      ),
                      
                      SizedBox(height: isTablet ? 24 : 20),
                      
                      // Contact Information Section
                      _buildPremiumDetailSection(
                        title: 'Contact Information',
                        icon: Icons.contact_phone_rounded,
                        child: Column(
                          children: [
                            // Phone Card
                            _buildPremiumContactItem(
                              icon: Icons.phone_rounded,
                              title: 'Phone',
                              value: serviceProvider.phone,
                              isTablet: isTablet,
                            ),
                            SizedBox(height: isTablet ? 12 : 10),
                            
                            // Email Card
                            _buildPremiumContactItem(
                              icon: Icons.email_rounded,
                              title: 'Email',
                              value: serviceProvider.email,
                              isTablet: isTablet,
                            ),
                            SizedBox(height: isTablet ? 12 : 10),
                            
                            // Address Card
                            _buildPremiumContactItem(
                              icon: Icons.location_on_rounded,
                              title: 'Address',
                              value: serviceProvider.formattedAddress,
                              isTablet: isTablet,
                            ),
                          ],
                        ),
                        isTablet: isTablet,
                      ),
                      
                      SizedBox(height: isTablet ? 24 : 20),
                      
                      // Professional Information Section
                      if (serviceProvider.description != null || 
                          serviceProvider.website != null || 
                          serviceProvider.businessHours != null)
                        _buildPremiumDetailSection(
                          title: 'Professional Information',
                          icon: Icons.business_center_rounded,
                          child: Column(
                            children: [
                              if (serviceProvider.description != null && serviceProvider.description!.isNotEmpty)
                                Container(
                                  padding: EdgeInsets.all(isTablet ? 18 : 14),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
                                    border: Border.all(color: _borderColor, width: 1.2),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.06),
                                        blurRadius: 12,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            width: isTablet ? 32 : 28,
                                            height: isTablet ? 32 : 28,
                                            decoration: BoxDecoration(
                                              color: _primaryGreen.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(isTablet ? 8 : 6),
                                            ),
                                            child: Center(
                                              child: Icon(
                                                Icons.description_rounded,
                                                color: _primaryGreen,
                                                size: isTablet ? 16 : 14,
                                              ),
                                            ),
                                          ),
                                          SizedBox(width: isTablet ? 12 : 10),
                                          Text(
                                            'Description',
                                            style: GoogleFonts.inter(
                                              fontSize: isTablet ? 16 : 14,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.black,
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: isTablet ? 12 : 10),
                                      Text(
                                        serviceProvider.description!,
                                        style: GoogleFonts.inter(
                                          fontSize: isTablet ? 14 : 12,
                                          color: Colors.grey[700],
                                          height: 1.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              
                              if (serviceProvider.description != null && serviceProvider.description!.isNotEmpty)
                                SizedBox(height: isTablet ? 12 : 10),
                              
                              if (serviceProvider.website != null && serviceProvider.website!.isNotEmpty)
                                _buildPremiumDetailCard(
                                  icon: Icons.language_rounded,
                                  title: 'Website',
                                  value: serviceProvider.website!,
                                  gradientColors: [_primaryRed, _deepRed],
                                  isTablet: isTablet,
                                ),
                              
                              if (serviceProvider.website != null && serviceProvider.website!.isNotEmpty)
                                SizedBox(height: isTablet ? 12 : 10),
                              
                              if (serviceProvider.businessHours != null && serviceProvider.businessHours!.isNotEmpty)
                                Container(
                                  padding: EdgeInsets.all(isTablet ? 18 : 14),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
                                    border: Border.all(color: _borderColor, width: 1.2),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.06),
                                        blurRadius: 12,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            width: isTablet ? 32 : 28,
                                            height: isTablet ? 32 : 28,
                                            decoration: BoxDecoration(
                                              color: _infoBlue.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(isTablet ? 8 : 6),
                                            ),
                                            child: Center(
                                              child: Icon(
                                                Icons.access_time_rounded,
                                                color: _infoBlue,
                                                size: isTablet ? 16 : 14,
                                              ),
                                            ),
                                          ),
                                          SizedBox(width: isTablet ? 12 : 10),
                                          Text(
                                            'Business Hours',
                                            style: GoogleFonts.inter(
                                              fontSize: isTablet ? 16 : 14,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.black,
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: isTablet ? 12 : 10),
                                      Text(
                                        serviceProvider.businessHours!,
                                        style: GoogleFonts.inter(
                                          fontSize: isTablet ? 14 : 12,
                                          color: Colors.grey[700],
                                          height: 1.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          isTablet: isTablet,
                        ),
                      
                      if ((serviceProvider.description != null || 
                          serviceProvider.website != null || 
                          serviceProvider.businessHours != null))
                        SizedBox(height: isTablet ? 24 : 20),
                      
                      // Additional Information Section
                      if (serviceProvider.licenseNumber != null || 
                          serviceProvider.specialties != null || 
                          serviceProvider.consultationFee != null)
                        _buildPremiumDetailSection(
                          title: 'Additional Information',
                          icon: Icons.info_outline_rounded,
                          child: Column(
                            children: [
                              if (serviceProvider.licenseNumber != null && serviceProvider.licenseNumber!.isNotEmpty)
                                Container(
                                  padding: EdgeInsets.all(isTablet ? 16 : 12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
                                    border: Border.all(color: _borderColor, width: 0.8),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: isTablet ? 32 : 28,
                                        height: isTablet ? 32 : 28,
                                        decoration: BoxDecoration(
                                          color: _primaryGreen.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(isTablet ? 8 : 6),
                                        ),
                                        child: Center(
                                          child: Icon(
                                            Icons.badge_rounded,
                                            color: _primaryGreen,
                                            size: isTablet ? 16 : 14,
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: isTablet ? 12 : 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'License Number',
                                              style: GoogleFonts.inter(
                                                fontSize: isTablet ? 12 : 10,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              serviceProvider.licenseNumber!,
                                              style: GoogleFonts.inter(
                                                fontSize: isTablet ? 16 : 14,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.black,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              
                              if (serviceProvider.licenseNumber != null && serviceProvider.licenseNumber!.isNotEmpty)
                                SizedBox(height: isTablet ? 10 : 8),
                              
                              if (serviceProvider.consultationFee != null && serviceProvider.consultationFee! > 0)
                                Container(
                                  padding: EdgeInsets.all(isTablet ? 16 : 12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
                                    border: Border.all(color: _borderColor, width: 0.8),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: isTablet ? 32 : 28,
                                        height: isTablet ? 32 : 28,
                                        decoration: BoxDecoration(
                                          color: _primaryRed.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(isTablet ? 8 : 6),
                                        ),
                                        child: Center(
                                          child: Icon(
                                            Icons.attach_money_rounded,
                                            color: _primaryRed,
                                            size: isTablet ? 16 : 14,
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: isTablet ? 12 : 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Consultation Fee',
                                              style: GoogleFonts.inter(
                                                fontSize: isTablet ? 12 : 10,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '\$${serviceProvider.consultationFee!.toStringAsFixed(2)}',
                                              style: GoogleFonts.inter(
                                                fontSize: isTablet ? 20 : 16,
                                                fontWeight: FontWeight.w800,
                                                color: _primaryRed,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              
                              if (serviceProvider.consultationFee != null && serviceProvider.consultationFee! > 0)
                                SizedBox(height: isTablet ? 10 : 8),
                              
                              if (serviceProvider.specialties != null && serviceProvider.specialties!.isNotEmpty)
                                Container(
                                  padding: EdgeInsets.all(isTablet ? 16 : 12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
                                    border: Border.all(color: _borderColor, width: 0.8),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            width: isTablet ? 32 : 28,
                                            height: isTablet ? 32 : 28,
                                            decoration: BoxDecoration(
                                              color: _goldAccent.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(isTablet ? 8 : 6),
                                            ),
                                            child: Center(
                                              child: Icon(
                                                Icons.star_rounded,
                                                color: _goldAccent,
                                                size: isTablet ? 16 : 14,
                                              ),
                                            ),
                                          ),
                                          SizedBox(width: isTablet ? 12 : 10),
                                          Text(
                                            'Specialties',
                                            style: GoogleFonts.inter(
                                              fontSize: isTablet ? 16 : 14,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.black,
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: isTablet ? 10 : 8),
                                      Text(
                                        serviceProvider.specialties!,
                                        style: GoogleFonts.inter(
                                          fontSize: isTablet ? 14 : 12,
                                          color: Colors.grey[700],
                                          height: 1.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          isTablet: isTablet,
                        ),
                      
                      if ((serviceProvider.licenseNumber != null || 
                          serviceProvider.specialties != null || 
                          serviceProvider.consultationFee != null))
                        SizedBox(height: isTablet ? 24 : 20),
                      
                      // Statistics Section
                      _buildPremiumDetailSection(
                        title: 'Statistics',
                        icon: Icons.analytics_rounded,
                        child: Container(
                          padding: EdgeInsets.all(isTablet ? 18 : 14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
                            border: Border.all(color: _borderColor, width: 1.2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              _buildDetailRow('Rating', '${serviceProvider.rating ?? 0.0}/5 (${serviceProvider.totalReviews} reviews)', isTablet: isTablet),
                              Divider(height: 16, color: _borderColor),
                              _buildDetailRow('Total Likes', serviceProvider.totalLikes.toString(), isTablet: isTablet),
                              Divider(height: 16, color: _borderColor),
                              _buildDetailRow('Accepts Insurance', serviceProvider.acceptsInsurance == true ? 'Yes' : 'No', isTablet: isTablet),
                              Divider(height: 16, color: _borderColor),
                              _buildDetailRow('Created On', DateFormat('MMM dd, yyyy HH:mm').format(serviceProvider.createdAt), isTablet: isTablet),
                              Divider(height: 16, color: _borderColor),
                              _buildDetailRow('Last Updated', DateFormat('MMM dd, yyyy HH:mm').format(serviceProvider.updatedAt), isTablet: isTablet),
                            ],
                          ),
                        ),
                        isTablet: isTablet,
                      ),
                      
                      SizedBox(height: isTablet ? 24 : 20),
                      
                      // Languages Spoken Section
                      if (serviceProvider.languagesSpoken.isNotEmpty)
                        _buildPremiumDetailSection(
                          title: 'Languages Spoken',
                          icon: Icons.language_rounded,
                          child: Container(
                            padding: EdgeInsets.all(isTablet ? 16 : 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
                              border: Border.all(color: _borderColor, width: 1.2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: _buildChipGrid(serviceProvider.languagesSpoken, isTablet),
                          ),
                          isTablet: isTablet,
                        ),
                      
                      if (serviceProvider.languagesSpoken.isNotEmpty)
                        SizedBox(height: isTablet ? 24 : 20),
                      
                      // Service Tags Section
                      if (serviceProvider.serviceTags.isNotEmpty)
                        _buildPremiumDetailSection(
                          title: 'Service Tags',
                          icon: Icons.tag_rounded,
                          child: Container(
                            padding: EdgeInsets.all(isTablet ? 16 : 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
                              border: Border.all(color: _borderColor, width: 1.2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: _buildChipGrid(serviceProvider.serviceTags, isTablet),
                          ),
                          isTablet: isTablet,
                        ),
                      
                      if (serviceProvider.serviceTags.isNotEmpty)
                        SizedBox(height: isTablet ? 24 : 20),
                      
                      // Service Areas Section
                      if (serviceProvider.serviceAreas.isNotEmpty)
                        _buildPremiumDetailSection(
                          title: 'Service Areas',
                          icon: Icons.map_rounded,
                          child: Container(
                            padding: EdgeInsets.all(isTablet ? 16 : 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
                              border: Border.all(color: _borderColor, width: 1.2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: _buildChipGrid(serviceProvider.serviceAreas, isTablet),
                          ),
                          isTablet: isTablet,
                        ),
                      
                      if (serviceProvider.serviceAreas.isNotEmpty)
                        SizedBox(height: isTablet ? 24 : 20),
                      
                      // Accepted Payment Methods
                      if (serviceProvider.acceptedPaymentMethods?.isNotEmpty == true)
                        _buildPremiumDetailSection(
                          title: 'Accepted Payment Methods',
                          icon: Icons.payment_rounded,
                          child: Container(
                            padding: EdgeInsets.all(isTablet ? 16 : 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
                              border: Border.all(color: _borderColor, width: 1.2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Wrap(
                              spacing: isTablet ? 8 : 6,
                              runSpacing: isTablet ? 8 : 6,
                              children: serviceProvider.acceptedPaymentMethods!.map((method) {
                                return Chip(
                                  label: Text(
                                    method,
                                    style: GoogleFonts.inter(
                                      fontSize: isTablet ? 13 : 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  backgroundColor: _primaryRed.withOpacity(0.1),
                                  side: BorderSide(color: _primaryRed),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                          isTablet: isTablet,
                        ),
                      
                      if (serviceProvider.acceptedPaymentMethods?.isNotEmpty == true)
                        SizedBox(height: isTablet ? 24 : 20),
                      
                      // Gallery Section
                      if (serviceProvider.galleryImagesBase64 != null && serviceProvider.galleryImagesBase64!.isNotEmpty)
                        _buildPremiumDetailSection(
                          title: 'Gallery',
                          icon: Icons.photo_library_rounded,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildGalleryImages(serviceProvider.galleryImagesBase64!, isTablet),
                              SizedBox(height: isTablet ? 12 : 10),
                              Text(
                                '${serviceProvider.galleryImagesBase64!.length} photos',
                                style: GoogleFonts.inter(
                                  fontSize: isTablet ? 12 : 10,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          isTablet: isTablet,
                        ),
                      
                      if (serviceProvider.galleryImagesBase64 != null && serviceProvider.galleryImagesBase64!.isNotEmpty)
                        SizedBox(height: isTablet ? 24 : 20),
                      
                      // Admin Action Buttons
                      Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () async {
                                      final providerProvider = Provider.of<ServiceProviderProvider>(context, listen: false);
                                      await providerProvider.toggleVerification(
                                        serviceProvider.id!,
                                        !serviceProvider.isVerified,
                                      );
                                    },
                                    borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
                                    child: Container(
                                      padding: EdgeInsets.symmetric(vertical: isTablet ? 16 : 12),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: serviceProvider.isVerified
                                            ? [_infoBlue, const Color(0xFF1565C0)]
                                            : [_warningOrange, const Color(0xFFEF6C00)],
                                          begin: Alignment.centerLeft,
                                          end: Alignment.centerRight,
                                        ),
                                        borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: (serviceProvider.isVerified ? _infoBlue : _warningOrange).withOpacity(0.4),
                                            blurRadius: 16,
                                            offset: const Offset(0, 8),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            serviceProvider.isVerified ? Icons.verified_rounded : Icons.pending_rounded,
                                            color: Colors.white,
                                            size: isTablet ? 20 : 16,
                                          ),
                                          SizedBox(width: isTablet ? 10 : 8),
                                          Text(
                                            serviceProvider.isVerified ? 'VERIFIED' : 'VERIFY NOW',
                                            style: GoogleFonts.poppins(
                                              fontSize: isTablet ? 16 : 14,
                                              fontWeight: FontWeight.w800,
                                              color: Colors.white,
                                              letterSpacing: 1.0,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          
                          SizedBox(height: isTablet ? 12 : 10),
                          
                          Row(
                            children: [
                              Expanded(
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () async {
                                      final providerProvider = Provider.of<ServiceProviderProvider>(context, listen: false);
                                      await providerProvider.toggleAvailability(
                                        serviceProvider.id!,
                                        !serviceProvider.isAvailable,
                                      );
                                    },
                                    borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
                                    child: Container(
                                      padding: EdgeInsets.symmetric(vertical: isTablet ? 14 : 10),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: serviceProvider.isAvailable
                                            ? [_warningOrange, const Color(0xFFEF6C00)]
                                            : [_successGreen, const Color(0xFF2E7D32)],
                                          begin: Alignment.centerLeft,
                                          end: Alignment.centerRight,
                                        ),
                                        borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
                                        boxShadow: [
                                          BoxShadow(
                                            color: (serviceProvider.isAvailable ? _warningOrange : _successGreen).withOpacity(0.3),
                                            blurRadius: 12,
                                            offset: const Offset(0, 6),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            serviceProvider.isAvailable ? Icons.block_rounded : Icons.check_circle_rounded,
                                            color: Colors.white,
                                            size: isTablet ? 18 : 14,
                                          ),
                                          SizedBox(width: isTablet ? 8 : 6),
                                          Text(
                                            serviceProvider.isAvailable ? 'MAKE INACTIVE' : 'MAKE ACTIVE',
                                            style: GoogleFonts.poppins(
                                              fontSize: isTablet ? 14 : 12,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: isTablet ? 12 : 10),
                              Expanded(
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () => _showDeleteDialog(context, serviceProvider),
                                    borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
                                    child: Container(
                                      padding: EdgeInsets.symmetric(vertical: isTablet ? 14 : 10),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
                                        border: Border.all(color: serviceProvider.isDeleted ? _successGreen : _primaryRed, width: 1.5),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.08),
                                            blurRadius: 8,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            serviceProvider.isDeleted ? Icons.restore_rounded : Icons.delete_rounded,
                                            color: serviceProvider.isDeleted ? _successGreen : _primaryRed,
                                            size: isTablet ? 18 : 14,
                                          ),
                                          SizedBox(width: isTablet ? 8 : 6),
                                          Text(
                                            serviceProvider.isDeleted ? 'RESTORE' : 'DELETE',
                                            style: GoogleFonts.poppins(
                                              fontSize: isTablet ? 14 : 12,
                                              fontWeight: FontWeight.w700,
                                              color: serviceProvider.isDeleted ? _successGreen : _primaryRed,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      
                      SizedBox(height: isTablet ? 28 : 24),
                      
                      // Admin Footer
                      Container(
                        padding: EdgeInsets.all(isTablet ? 24 : 18),
                        decoration: BoxDecoration(
                          color: _cardColor,
                          borderRadius: BorderRadius.circular(isTablet ? 24 : 20),
                          border: Border.all(color: _borderColor, width: 1.2),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: isTablet ? 48 : 40,
                              height: isTablet ? 48 : 40,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [_primaryRed, _primaryGreen],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.admin_panel_settings_rounded,
                                  color: Colors.white,
                                  size: isTablet ? 22 : 18,
                                ),
                              ),
                            ),
                            SizedBox(width: isTablet ? 16 : 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Admin Control Panel',
                                    style: GoogleFonts.poppins(
                                      fontSize: isTablet ? 16 : 14,
                                      fontWeight: FontWeight.w800,
                                      color: _primaryGreen,
                                    ),
                                  ),
                                  SizedBox(height: isTablet ? 6 : 4),
                                  Text(
                                    'Full administrative control over this service provider',
                                    style: GoogleFonts.inter(
                                      fontSize: isTablet ? 14 : 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      SizedBox(height: isTablet ? 32 : 24),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}