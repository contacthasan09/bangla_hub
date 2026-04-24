import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:bangla_hub/providers/auth_provider.dart';
import 'package:bangla_hub/screens/auth/login_screen.dart';
import 'package:bangla_hub/screens/user_app/home_screen.dart';
import 'package:bangla_hub/screens/user_app/webview_screen.dart';
import 'package:bangla_hub/screens/user_app/welcome_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:country_picker/country_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:provider/provider.dart';
import 'package:bangla_hub/services/cloudinary_service.dart';


class RegisterScreen extends StatefulWidget {
  final String role;

  const RegisterScreen({Key? key, required this.role}) : super(key: key);

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  
  String? _profileImagePath;
  File? _profileImageFile;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String _selectedCountryCode = '+1'; // Default to Bangladesh
  
  // Bangladesh flag colors
  final Color _bangladeshGreen = Color(0xFF006A4E);
  final Color _bangladeshRed = Color(0xFFF42A41);
  final Color _bangladeshDarkGreen = Color(0xFF004D38);
  final Color _goldAccent = Color(0xFFFFD700);
  final Color _offWhite = Color(0xFFF8F8F8);
  final Color _lightGreen = Color(0xFFE8F5E9);
  
  // Country and Location fields
  Country? _selectedCountry;
  String? _selectedLocation;
  double? _latitude;
  double? _longitude;
  bool _isLoadingLocation = false;
  
  // Animation controllers
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _slideAnimation;
  late Animation<Color?> _gradientAnimation;
  
  // Form focus nodes
  final List<FocusNode> _focusNodes = List.generate(10, (_) => FocusNode());
  bool _isFormValid = false;
  bool _isTermsAccepted = false;
  
  // Debounce timer for form validation
  Timer? _validationDebounce;
  
  // Track app lifecycle
  AppLifecycleState _appLifecycleState = AppLifecycleState.resumed;

  @override
  void initState() {
    super.initState();
    
    // ✅ Add WidgetsBindingObserver
    WidgetsBinding.instance.addObserver(this);
    
    // Initialize animations
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.0, 0.6, curve: Curves.easeInOut),
      ),
    );
    
    _slideAnimation = Tween<double>(begin: 80.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.2, 0.8, curve: Curves.easeOutQuint),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.3, 0.9, curve: Curves.elasticOut),
      ),
    );
    
    _gradientAnimation = ColorTween(
      begin: _bangladeshDarkGreen,
      end: _bangladeshGreen,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    
    _animationController.forward();
    
    // Listen to form changes for validation animation (with debounce)
    _firstNameController.addListener(_debouncedValidateForm);
    _lastNameController.addListener(_debouncedValidateForm);
    _emailController.addListener(_debouncedValidateForm);
    _phoneController.addListener(_debouncedValidateForm);
    _passwordController.addListener(_debouncedValidateForm);
    _confirmPasswordController.addListener(_debouncedValidateForm);
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    setState(() {
      _appLifecycleState = state;
    });
  }
  
  void _debouncedValidateForm() {
    _validationDebounce?.cancel();
    _validationDebounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        _validateForm();
      }
    });
  }

  void _validateForm() {
    final isValid = _firstNameController.text.isNotEmpty &&
        _lastNameController.text.isNotEmpty &&
        _emailController.text.isNotEmpty &&
        RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(_emailController.text) &&
        _phoneController.text.isNotEmpty &&
        _passwordController.text.length >= 6 &&
        _passwordController.text == _confirmPasswordController.text &&
        _selectedCountry != null &&
        _selectedLocation != null &&
        _isTermsAccepted;
    
    if (_isFormValid != isValid) {
      setState(() {
        _isFormValid = isValid;
      });
    }
  }

  // Toggle terms checkbox
  void _toggleTermsAccepted() {
    setState(() {
      _isTermsAccepted = !_isTermsAccepted;
      _validateForm(); // Re-validate form when checkbox changes
    });
  }

  @override
  void dispose() {
    print('🗑️ RegisterScreen disposing...');
    
    // ✅ Remove observer
    WidgetsBinding.instance.removeObserver(this);
    
    // ✅ Cancel debounce timer
    _validationDebounce?.cancel();
    
    // ✅ Dispose animation controller
    _animationController.dispose();
    
    // ✅ Dispose all focus nodes
    for (var node in _focusNodes) {
      node.dispose();
    }
    
    // ✅ Dispose all text controllers
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    
    super.dispose();
  }

  void _showCountryPickerForPhone() {
    showCountryPicker(
      context: context,
      showPhoneCode: true,
      countryListTheme: CountryListThemeData(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        inputDecoration: InputDecoration(
          labelText: 'Search Country',
          hintText: 'Start typing country name...',
          hintStyle: GoogleFonts.inter(color: Colors.grey[500]),
          prefixIcon: Icon(Icons.search, color: _bangladeshGreen),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: _bangladeshGreen, width: 2),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
      onSelect: (Country country) {
        if (mounted) {
          setState(() {
            _selectedCountryCode = '+${country.phoneCode}';
            _selectedCountry = country;
          });
          _validateForm();
        }
      },
    );
  }

  void _formatPhoneNumber(String value) {
    // Remove all non-digits
    String digits = value.replaceAll(RegExp(r'\D'), '');
    
    if (digits.length > 10) {
      digits = digits.substring(0, 10);
    }
    
    // Format as XXX-XXX-XXXX
    String formatted = '';
    for (int i = 0; i < digits.length; i++) {
      if (i == 3 || i == 6) {
        formatted += '-';
      }
      formatted += digits[i];
    }
    
    if (formatted != _phoneController.text) {
      _phoneController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 380;

    return Scaffold(
      body: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _gradientAnimation.value!,
                  _bangladeshGreen,
                  _bangladeshDarkGreen,
                ],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Container(
                  padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
                  child: Opacity(
                    opacity: _fadeAnimation.value,
                    child: Transform.translate(
                      offset: Offset(0, _slideAnimation.value),
                      child: Transform.scale(
                        scale: _scaleAnimation.value,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Premium Welcome Section
                            _buildPremiumWelcomeSection(),
                            SizedBox(height: isSmallScreen ? 30 : 40),

                            // Luxury Registration Form
                            _buildLuxuryRegistrationForm(isSmallScreen, authProvider),
                            SizedBox(height: isSmallScreen ? 20 : 30),

                            // Sign In Link
                            _buildPremiumSignInSection(),
                            SizedBox(height: isSmallScreen ? 10 : 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPremiumWelcomeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Bangladeshi Flag Inspired Logo
        Center(
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  _bangladeshRed,
                  _bangladeshRed.withOpacity(0.8),
                  _bangladeshGreen,
                ],
                stops: [0.0, 0.7, 1.0],
                center: Alignment.center,
                radius: 0.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: _bangladeshRed.withOpacity(0.4),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/logo/logo.png',
                fit: BoxFit.cover,
                width: 100,
                height: 100,
                errorBuilder: (context, error, stackTrace) {
                  print('Error loading logo: $error');
                  // Fallback with the original icon design if image fails to load
                  return Center(
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withOpacity(0.5),
                            blurRadius: 15,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.person_add_alt_1_rounded,
                        size: 24,
                        color: _bangladeshRed,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),

        const SizedBox(height: 30),
        
        // Welcome Text
        Text(
          'Create New Account',
          style: GoogleFonts.poppins(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            height: 1.2,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: 60,
          height: 4,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_bangladeshRed, _goldAccent],
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Be part of the BanglaHub community',
          style: GoogleFonts.inter(
            fontSize: 13,
            color: Colors.white.withOpacity(0.9),
            fontWeight: FontWeight.w400,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildLuxuryRegistrationForm(bool isSmallScreen, AuthProvider authProvider) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 20 : 32),
      decoration: BoxDecoration(
        color: _offWhite,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 40,
            offset: Offset(0, 20),
            spreadRadius: -10,
          ),
          BoxShadow(
            color: _bangladeshGreen.withOpacity(0.1),
            blurRadius: 30,
            offset: Offset(0, 10),
            spreadRadius: 5,
          ),
        ],
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            // Profile Picture Section
            _buildLuxuryProfilePicture(),
            const SizedBox(height: 24),

            // Stacked for small screens
            _buildLuxuryTextField(
              controller: _firstNameController,
              label: 'First Name',
              hintText: 'Enter first name',
              prefixIcon: Icons.person_outline_rounded,
              focusNode: _focusNodes[0],
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            
            _buildLuxuryTextField(
              controller: _lastNameController,
              label: 'Last Name',
              hintText: 'Enter last name',
              prefixIcon: Icons.person_outline_rounded,
              focusNode: _focusNodes[1],
              textCapitalization: TextCapitalization.words,
            ),
            
            const SizedBox(height: 16),
            
            // Email Field
            _buildLuxuryTextField(
              controller: _emailController,
              label: 'Email Address',
              hintText: 'Enter your email',
              prefixIcon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              focusNode: _focusNodes[2],
            ),
            const SizedBox(height: 16),

            // Phone Number Field
            _buildLuxuryPhoneNumberField(),
            const SizedBox(height: 16),

            // Country Picker
            _buildLuxuryCountryPicker(),
            const SizedBox(height: 16),

            // Location Picker (City & Country only)
            _buildLuxuryLocationPicker(),
            const SizedBox(height: 16),

            // Password Fields
            _buildLuxuryTextField(
              controller: _passwordController,
              label: 'Password',
              hintText: 'Enter your password',
              prefixIcon: Icons.lock_outline_rounded,
              obscureText: _obscurePassword,
              suffixIcon: IconButton(
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Icon(
                    _obscurePassword 
                        ? Icons.visibility_outlined 
                        : Icons.visibility_off_outlined,
                    key: ValueKey<bool>(_obscurePassword),
                    color: _bangladeshGreen,
                  ),
                ),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
              focusNode: _focusNodes[6],
            ),
            const SizedBox(height: 16),
            
            _buildLuxuryTextField(
              controller: _confirmPasswordController,
              label: 'Confirm Password',
              hintText: 'Confirm your password',
              prefixIcon: Icons.lock_outline_rounded,
              obscureText: _obscureConfirmPassword,
              suffixIcon: IconButton(
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Icon(
                    _obscureConfirmPassword 
                        ? Icons.visibility_outlined 
                        : Icons.visibility_off_outlined,
                    key: ValueKey<bool>(_obscureConfirmPassword),
                    color: _bangladeshGreen,
                  ),
                ),
                onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
              ),
              focusNode: _focusNodes[7],
            ),
            const SizedBox(height: 24),

            // Terms and Conditions
            _buildLuxuryTermsAndConditions(),
            const SizedBox(height: 24),

            // Register Button
            _buildLuxuryRegisterButton(isSmallScreen, authProvider),
          ],
        ),
      ),
    );
  }

  Widget _buildLuxuryProfilePicture() {
    return Column(
      children: [
        Stack(
          children: [
            // Flag-inspired circular background
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    _bangladeshRed.withOpacity(0.2),
                    _bangladeshGreen.withOpacity(0.2),
                  ],
                  center: Alignment.center,
                  radius: 0.8,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _bangladeshGreen.withOpacity(0.3),
                    blurRadius: 20,
                    offset: Offset(0, 10),
                  ),
                ],
                border: Border.all(
                  color: _bangladeshGreen.withOpacity(0.4),
                  width: 2,
                ),
              ),
              child: Center(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _bangladeshRed,
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: _profileImagePath != null
                        ? Image.file(
                            File(_profileImagePath!),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return _buildDefaultAvatar();
                            },
                          )
                        : _buildDefaultAvatar(),
                  ),
                ),
              ),
            ),
            
            // Camera button
            Positioned(
              bottom: 0,
              right: 0,
              child: GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_bangladeshRed, _bangladeshGreen],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _bangladeshRed.withOpacity(0.5),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                    border: Border.all(
                      color: Colors.white,
                      width: 3,
                    ),
                  ),
                  child: Icon(
                    Icons.camera_alt_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
     /*   const SizedBox(height: 8),
        Text(
          'Profile Picture (Optional)',
          style: GoogleFonts.inter(
            color: Colors.grey[600],
            fontSize: 12,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.3,
          ),
        ), */
        if (_profileImagePath != null) ...[
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: _bangladeshGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _bangladeshGreen.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  size: 12,
                  color: _bangladeshGreen,
                ),
                const SizedBox(width: 6),
                Text(
                  'Image selected',
                  style: GoogleFonts.inter(
                    color: _bangladeshGreen,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _bangladeshRed.withOpacity(0.1),
            _bangladeshGreen.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Icon(
        Icons.groups,
        size: 40,
        color: _bangladeshGreen,
      ),
    );
  }

  Widget _buildLuxuryTextField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    required IconData prefixIcon,
    required FocusNode focusNode,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: focusNode.hasFocus
            ? [
                BoxShadow(
                  color: _bangladeshGreen.withOpacity(0.15),
                  blurRadius: 20,
                  spreadRadius: 3,
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
      ),
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: keyboardType,
        obscureText: obscureText,
        textCapitalization: textCapitalization,
        style: GoogleFonts.inter(
          color: Colors.black87,
          fontSize: 15,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.3,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.inter(
            color: focusNode.hasFocus ? _bangladeshGreen : Colors.grey[600],
            fontWeight: FontWeight.w500,
            fontSize: 14,
            letterSpacing: 0.3,
          ),
          hintText: hintText,
          hintStyle: GoogleFonts.inter(
            color: Colors.grey[500],
            fontSize: 15,
            letterSpacing: 0.3,
          ),
          prefixIcon: Container(
            width: 60,
            child: Icon(
              prefixIcon,
              color: focusNode.hasFocus ? _bangladeshGreen : Colors.grey[600],
              size: 22,
            ),
          ),
          suffixIcon: suffixIcon,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: Colors.grey[300]!,
              width: 1.5,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: _bangladeshGreen,
              width: 2,
            ),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'This field is required';
          }
          if (label.toLowerCase().contains('email') && 
              !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
            return 'Please enter a valid email';
          }
          if (label.toLowerCase().contains('password') && value.length < 6) {
            return 'Password must be at least 6 characters';
          }
          if (label.toLowerCase().contains('confirm') && 
              value != _passwordController.text) {
            return 'Passwords do not match';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildLuxuryPhoneNumberField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Phone Number',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: _focusNodes[3].hasFocus ? Colors.white : Colors.white,
            border: Border.all(
              color: _focusNodes[3].hasFocus ? _bangladeshGreen : Colors.grey[300]!,
              width: _focusNodes[3].hasFocus ? 2 : 1.5,
            ),
            boxShadow: _focusNodes[3].hasFocus
                ? [
                    BoxShadow(
                      color: _bangladeshGreen.withOpacity(0.15),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              // Country Code Picker
              GestureDetector(
                onTap: _showCountryPickerForPhone,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _bangladeshGreen.withOpacity(0.1),
                        _bangladeshRed.withOpacity(0.1),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                    ),
                    border: Border(
                      right: BorderSide(
                        color: Colors.grey[300]!,
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_selectedCountry != null)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Text(
                            _selectedCountry!.flagEmoji,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      Text(
                        _selectedCountryCode,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _bangladeshGreen,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_drop_down_rounded,
                        color: _bangladeshGreen,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
              
              // Phone Number Input
              Expanded(
                child: TextFormField(
                  controller: _phoneController,
                  focusNode: _focusNodes[3],
                  keyboardType: TextInputType.phone,
                  style: GoogleFonts.inter(
                    color: Colors.black87,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.3,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Enter phone number',
                    hintStyle: GoogleFonts.inter(
                      color: Colors.grey[500],
                      fontSize: 15,
                      letterSpacing: 0.3,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 18,
                    ),
                    prefixIcon: Container(
                      width: 50,
                      child: Icon(
                        Icons.phone_outlined,
                        color: _focusNodes[3].hasFocus ? _bangladeshGreen : Colors.grey[600],
                        size: 22,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your phone number';
                    }
                    
                    String digits = value.replaceAll(RegExp(r'\D'), '');
                    if (digits.length < 7) {
                      return 'Phone number is too short';
                    }
                    if (digits.length > 15) {
                      return 'Phone number is too long';
                    }
                    
                    return null;
                  },
                  onChanged: _formatPhoneNumber,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLuxuryCountryPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Country',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _showCountryPicker,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            decoration: BoxDecoration(
              gradient: _selectedCountry != null
                  ? LinearGradient(
                      colors: [
                        _bangladeshGreen.withOpacity(0.1),
                        _bangladeshRed.withOpacity(0.1),
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    )
                  : null,
              color: _selectedCountry != null ? null : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _selectedCountry != null 
                    ? _bangladeshGreen.withOpacity(0.3)
                    : Colors.grey[300]!,
                width: 1.5,
              ),
              boxShadow: _selectedCountry != null
                  ? [
                      BoxShadow(
                        color: _bangladeshGreen.withOpacity(0.1),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.flag_outlined,
                  color: _selectedCountry != null ? _bangladeshGreen : Colors.grey[600],
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Text(
                      _selectedCountry != null 
                          ? '${_selectedCountry!.flagEmoji} ${_selectedCountry!.name}'
                          : 'Select your country',
                      key: ValueKey<String>(_selectedCountry?.name ?? 'empty'),
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: _selectedCountry != null 
                            ? Colors.black87
                            : Colors.grey[600],
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_drop_down_rounded,
                  color: _selectedCountry != null ? _bangladeshGreen : Colors.grey[600],
                  size: 28,
                ),
              ],
            ),
          ),
        ),
        if (_selectedCountry == null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.info_outline, size: 14, color: _bangladeshRed),
              const SizedBox(width: 6),
              Text(
                'Please select your country',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: _bangladeshRed,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildLuxuryLocationPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Location',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: _selectedLocation != null
                ? LinearGradient(
                    colors: [
                      _lightGreen,
                      Colors.white,
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  )
                : null,
            color: _selectedLocation != null ? null : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _selectedLocation != null
                  ? _bangladeshGreen.withOpacity(0.3)
                  : Colors.grey[300]!,
              width: 1.5,
            ),
            boxShadow: _selectedLocation != null
                ? [
                    BoxShadow(
                      color: _bangladeshGreen.withOpacity(0.1),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    color: _selectedLocation != null
                        ? _bangladeshGreen
                        : Colors.grey[600],
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Text(
                        _selectedLocation ?? 'No location selected',
                        key: ValueKey<String>(_selectedLocation ?? 'empty'),
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: _selectedLocation != null
                              ? Colors.black87
                              : Colors.grey[600],
                          letterSpacing: 0.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoadingLocation ? null : _getCurrentLocation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _bangladeshGreen.withOpacity(0.1),
                    foregroundColor: _bangladeshGreen,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: _bangladeshGreen.withOpacity(0.3)),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                  ),
                  icon: _isLoadingLocation
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(_bangladeshGreen),
                          ),
                        )
                      : Icon(Icons.my_location, size: 18),
                  label: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Text(
                      _isLoadingLocation ? 'Getting location...' : 'Use Current Location',
                      key: ValueKey<bool>(_isLoadingLocation),
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_selectedLocation == null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.info_outline, size: 14, color: _bangladeshRed),
              const SizedBox(width: 6),
              Text(
                'Please select your location',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: _bangladeshRed,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildLuxuryTermsAndConditions() {
  return GestureDetector(
    onTap: _toggleTermsAccepted,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Checkbox
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          width: 22,
          height: 22,
          margin: const EdgeInsets.only(top: 2),
          decoration: BoxDecoration(
            color: _isTermsAccepted 
                ? _bangladeshGreen 
                : _bangladeshGreen.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: _isTermsAccepted 
                  ? _bangladeshGreen 
                  : _bangladeshGreen.withOpacity(0.3),
              width: _isTermsAccepted ? 0 : 1.5,
            ),
            boxShadow: _isTermsAccepted 
                ? [
                    BoxShadow(
                      color: _bangladeshGreen.withOpacity(0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _isTermsAccepted
                  ? Icon(
                      Icons.check_rounded,
                      size: 16,
                      color: Colors.white,
                      key: const ValueKey('checked'),
                    )
                  : const SizedBox.shrink(key: ValueKey('unchecked')),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: GoogleFonts.inter(
                fontSize: 13,
                color: Colors.grey[700],
                height: 1.5,
                letterSpacing: 0.3,
              ),
              children: [
                const TextSpan(text: 'By registering, you agree to our '),
                WidgetSpan(
                  child: GestureDetector(
                    onTap: () {
                      _navigateToTermsOfService();
                    },
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: Text(
                        'Terms of Service',
                        style: TextStyle(
                          color: _bangladeshGreen,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                ),
                const TextSpan(text: ' and '),
                WidgetSpan(
                  child: GestureDetector(
                    onTap: () {
                      _navigateToPrivacyPolicy();
                    },
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: Text(
                        'Privacy Policy',
                        style: TextStyle(
                          color: _bangladeshGreen,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                ),
                const TextSpan(text: '.'),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

// Navigation methods
void _navigateToTermsOfService() {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => WebViewScreen(
        title: 'Terms of Service',
        url: 'https://contacthasan09.github.io/banglahub-us/terms_of_service.html',
      ),
    ),
  );
}



void _navigateToPrivacyPolicy() {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => WebViewScreen(
        title: 'Privacy Policy',
        url: 'https://contacthasan09.github.io/banglahub-us/privacy_policy.html',
      ),
    ),
  );
}
  
  Widget _buildLuxuryRegisterButton(bool isSmallScreen, AuthProvider authProvider) {
    // The button is enabled only when ALL conditions are met including checkbox
    final bool isButtonEnabled = _isFormValid && !authProvider.isLoading;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        gradient: isButtonEnabled
            ? LinearGradient(
                colors: [_bangladeshRed, _bangladeshGreen],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                stops: const [0.0, 0.8],
              )
            : LinearGradient(
                colors: [Colors.grey[400]!, Colors.grey[500]!],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: isButtonEnabled
            ? [
                BoxShadow(
                  color: _bangladeshRed.withOpacity(0.4),
                  blurRadius: 25,
                  offset: Offset(0, 10),
                  spreadRadius: 3,
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 15,
                  offset: Offset(0, 5),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: isButtonEnabled ? () => _register(context, authProvider) : null,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: authProvider.isLoading
                  ? Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      ),
                      key: const ValueKey('loading'),
                    )
                  : isButtonEnabled
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Create Account',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Icon(
                              Icons.arrow_forward_rounded,
                              color: Colors.white,
                              size: isSmallScreen ? 18 : 20,
                            ),
                          ],
                          key: const ValueKey('enabled'),
                        )
                      : Center(
                          child: Text(
                            // Show appropriate message based on what's missing
                            !_isTermsAccepted 
                                ? 'Accept terms & conditions'
                                : 'Fill all required fields',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withOpacity(0.8),
                              letterSpacing: 0.5,
                            ),
                          ),
                          key: ValueKey(!_isTermsAccepted ? 'terms_not_accepted' : 'form_invalid'),
                        ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumSignInSection() {
    final Color _primaryRed = Color(0xFFF42A41);
    final Color _primaryGreen = Color(0xFF006A4E);
    final Color _goldAccent = Color(0xFFFFD700);
    
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "Already have an account?",
            style: GoogleFonts.inter(
              fontSize: 16,
              color: Colors.white.withOpacity(0.95),
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
              shadows: [
                Shadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 3,
                  offset: Offset(0, 1),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const LoginScreen(),
                ),
              ),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                transform: Matrix4.identity()..scale(1.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_primaryRed, _primaryGreen],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.4),
                      width: 1.8,
                    ),
                    boxShadow: [
                      // Deep shadow
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 15,
                        offset: Offset(0, 5),
                      ),
                      // Red glow
                      BoxShadow(
                        color: _primaryRed.withOpacity(0.5),
                        blurRadius: 20,
                        offset: Offset(-3, 0),
                      ),
                      // Green glow
                      BoxShadow(
                        color: _primaryGreen.withOpacity(0.5),
                        blurRadius: 20,
                        offset: Offset(3, 0),
                      ),
                      // Gold inner glow
                      BoxShadow(
                        color: _goldAccent.withOpacity(0.2),
                        blurRadius: 10,
                        offset: Offset(0, 0),
                        blurStyle: BlurStyle.inner,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Sign In",
                        style: GoogleFonts.inter(
                          fontSize: 17,
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.4),
                              blurRadius: 3,
                              offset: Offset(0, 2),
                            ),
                            Shadow(
                              color: _goldAccent.withOpacity(0.3),
                              blurRadius: 8,
                              offset: Offset(0, 0),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
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

  void _showCountryPicker() {
    showCountryPicker(
      context: context,
      showPhoneCode: false,
      countryListTheme: CountryListThemeData(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        inputDecoration: InputDecoration(
          labelText: 'Search Country',
          hintText: 'Start typing country name...',
          hintStyle: GoogleFonts.inter(color: Colors.grey[500]),
          prefixIcon: Icon(Icons.search, color: _bangladeshGreen),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: _bangladeshGreen, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
      onSelect: (Country country) {
        if (mounted) {
          setState(() {
            _selectedCountry = country;
          });
          _validateForm();
        }
      },
    );
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      // Check if location service is enabled
      if (!await Geolocator.isLocationServiceEnabled()) {
        if (mounted) {
          _showLocationError('Location services are disabled. Please enable them.');
          setState(() => _isLoadingLocation = false);
        }
        return;
      }

      // Check permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            _showLocationError('Location permissions are denied.');
            setState(() => _isLoadingLocation = false);
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          _showLocationError(
            'Location permissions are permanently denied. Please enable them in app settings.');
          setState(() => _isLoadingLocation = false);
        }
        return;
      }

      // Get current position safely
      Position position;
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 30),
        );
      } on TimeoutException {
        if (mounted) {
          _showLocationError('Location request timed out. Please try again.');
          setState(() => _isLoadingLocation = false);
        }
        return;
      } catch (e) {
        if (mounted) {
          _showLocationError('Failed to get current location: $e');
          setState(() => _isLoadingLocation = false);
        }
        return;
      }

      // Get City & Country
      String locationText = '';
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (placemarks.isNotEmpty) {
          Placemark place = placemarks.first;
          List<String> parts = [];
          if (place.locality != null && place.locality!.isNotEmpty) {
            parts.add(place.locality!);
          }
          if (place.country != null && place.country!.isNotEmpty) {
            parts.add(place.country!);
          }
          locationText = parts.join(', ');
        }

        if (locationText.isEmpty) {
          // fallback to coordinates
          locationText =
              '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
        }
      } catch (_) {
        // fallback to coordinates if geocoding fails
        locationText =
            '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
      }

      if (mounted) {
        setState(() {
          _selectedLocation = locationText;
          _latitude = position.latitude;
          _longitude = position.longitude;
          _isLoadingLocation = false;
        });

        _validateForm();
        _showLocationSuccessAnimation();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
        });

        _showLocationError('Failed to get location: $e');
      }
    }
  }

  void _showLocationError(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.inter(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: _bangladeshRed,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        action: SnackBarAction(
          label: 'Settings',
          textColor: Colors.white,
          onPressed: () async {
            if (Platform.isAndroid) {
              await Geolocator.openLocationSettings();
            } else if (Platform.isIOS) {
              await Geolocator.openAppSettings();
            }
          },
        ),
      ),
    );
  }

  void _showLocationSuccessAnimation() {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Location found!',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  if (_selectedLocation != null)
                    Text(
                      _selectedLocation!,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.9),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: _bangladeshGreen,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final result = await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildImageSourceBottomSheet(),
    );
    
    if (result == null || !mounted) return;
    
    final ImageSource source = result;
    
    try {
      final picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (pickedFile != null && mounted) {
        final file = File(pickedFile.path);
        final fileSize = await file.length();
        const maxSize = 5 * 1024 * 1024;
        
        if (fileSize > maxSize) {
          _showImageError('Image size should be less than 5MB');
          return;
        }
        
        final extension = pickedFile.path.split('.').last.toLowerCase();
        final allowedExtensions = ['jpg', 'jpeg', 'png', 'gif', 'webp'];
        
        if (!allowedExtensions.contains(extension)) {
          _showImageError('Please select a valid image (JPG, PNG, GIF, WebP)');
          return;
        }
        
        setState(() {
          _profileImagePath = pickedFile.path;
          _profileImageFile = File(pickedFile.path);
        });
        
        _showImageSuccessAnimation();
      }
    } catch (e) {
      if (mounted) {
        _handleImagePickerError(e);
      }
    }
  }

  
  
  Widget _buildImageSourceBottomSheet() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Choose Profile Picture',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              _buildImageSourceOption(
                icon: Icons.camera_alt_rounded,
                title: 'Take Photo',
                subtitle: 'Use your camera',
                color: _bangladeshGreen,
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              const SizedBox(height: 12),
              _buildImageSourceOption(
                icon: Icons.photo_library_rounded,
                title: 'Choose from Gallery',
                subtitle: 'Select from your photos',
                color: _bangladeshRed,
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
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

  Widget _buildImageSourceOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withOpacity(0.2),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.grey[400],
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  void _handleImagePickerError(dynamic error) {
    String errorMessage = 'Failed to pick image';
    
    if (error is PlatformException) {
      switch (error.code) {
        case 'photo_access_denied':
          errorMessage = 'Photo access denied. Please enable photo permissions.';
          break;
        case 'camera_access_denied':
          errorMessage = 'Camera access denied. Please enable camera permissions.';
          break;
        case 'no_media_selected':
          errorMessage = 'No image selected';
          break;
        case 'cancelled':
          errorMessage = 'Image selection cancelled';
          break;
        default:
          errorMessage = error.message ?? 'Unknown error occurred';
      }
    }
    
    _showImageError(errorMessage);
  }

  void _showImageError(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.inter(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: _bangladeshRed,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _showImageSuccessAnimation() {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.2),
              ),
              child: Icon(
                Icons.check_rounded,
                size: 16,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Profile Picture Selected',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  if (_profileImagePath != null)
                    Text(
                      'Image size: ${(_profileImageFile?.lengthSync() ?? 0) ~/ 1024} KB',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: _bangladeshGreen,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

Future<void> _register(BuildContext context, AuthProvider authProvider) async {
  if (_formKey.currentState!.validate()) {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_bangladeshGreen, _bangladeshRed],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              ),
              const SizedBox(height: 20),
              Text(
                'Creating your account...',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
    
    try {
      String? profileImageUrl;
      
      // Upload profile image to Cloudinary if selected
      if (_profileImageFile != null) {
        print('📸 Uploading profile image to Cloudinary...');
        
        String userId = CloudinaryService.sanitizeEmailForFolder(
          _emailController.text.trim()
        );
        
        profileImageUrl = await CloudinaryService.uploadImage(
          _profileImageFile!,
          customFolder: 'profile_images/$userId',
        );
        if (profileImageUrl != null) {
          print('✅ Profile image uploaded: $profileImageUrl');
        } else {
          print('⚠️ Profile image upload failed, continuing without image');
        }
      }
      
      // Register user with Cloudinary URL
      await authProvider.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        location: _selectedLocation!,
        profileImageUrl: profileImageUrl,
        country: _selectedCountry?.name,
        countryCode: _selectedCountry?.phoneCode,
        latitude: _latitude,
        longitude: _longitude,
        context: context,
      );
      
      // Close loading dialog if still open
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      
      // ✅ DO NOT NAVIGATE - AuthProvider will show verification dialog
      // The user will stay on the verification dialog until they verify or go back
      
    } catch (e) {
      // Close loading dialog
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      
      String errorMessage = 'Registration failed. Please try again.';
      
      if (e.toString().contains('email-already-in-use')) {
        errorMessage = 'Email already in use. Please use a different email or login.';
      } else if (e.toString().contains('too-many-requests')) {
        errorMessage = 'Too many attempts. Please try again later.';
      } else if (e.toString().contains('weak-password')) {
        errorMessage = 'Password is too weak. Please use a stronger password.';
      } else if (e.toString().contains('network-request-failed')) {
        errorMessage = 'Network error. Please check your internet connection.';
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: _bangladeshRed,
            content: Text(errorMessage),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}

}