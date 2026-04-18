import 'dart:math';

import 'package:bangla_hub/screens/admin_app/screens/home/admin_homescreen.dart';
import 'package:bangla_hub/screens/auth/forgot_password_screen.dart';
import 'package:bangla_hub/screens/auth/signup_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:bangla_hub/constants/app_constants.dart';
import 'package:bangla_hub/providers/auth_provider.dart';
import 'package:bangla_hub/providers/location_filter_provider.dart';
import 'package:bangla_hub/screens/user_app/home_screen.dart';
import 'package:provider/provider.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback? onRegisterPressed;
  final VoidCallback? onForgotPasswordPressed;
  
  const LoginScreen({
    Key? key,
    this.onRegisterPressed,
    this.onForgotPasswordPressed,
  }) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _isHovered = false;
  bool _isGuestHovered = false;

  // Animation controllers
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _gradientAnimation;
  
  // Form focus nodes
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  
  // Track app lifecycle
  AppLifecycleState _appLifecycleState = AppLifecycleState.resumed;
  
  // Color scheme
  final Color _primaryRed = Color(0xFFF42A41);
  final Color _primaryGreen = Color(0xFF006A4E);
  final Color _darkGreen = Color(0xFF004D38);
  final Color _goldAccent = Color(0xFFFFD700);
  final Color _offWhite = Color(0xFFF8F8F8);
  final Color _lightGreen = Color(0xFFE8F5E9);

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
      begin: _darkGreen,
      end: _primaryGreen,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    
    // Start animation
    if (_appLifecycleState == AppLifecycleState.resumed) {
      _animationController.forward();
    }
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    setState(() {
      _appLifecycleState = state;
    });
    
    if (state == AppLifecycleState.resumed) {
      // App is visible - restart animation
      _animationController.forward(from: 0);
    } else {
      // App is not visible - stop animation to save resources
      _animationController.stop();
    }
  }

  @override
  void dispose() {
    print('🗑️ LoginScreen disposing...');
    
    // ✅ Remove observer
    WidgetsBinding.instance.removeObserver(this);
    
    // ✅ Dispose animation controller
    _animationController.dispose();
    
    // ✅ Dispose focus nodes
    _emailFocus.dispose();
    _passwordFocus.dispose();
    
    // ✅ Dispose text controllers
    _emailController.dispose();
    _passwordController.dispose();
    
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;

    return Scaffold(
      body: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  _gradientAnimation.value ?? _primaryGreen,
                  _primaryGreen,
                  _darkGreen,
                ],
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                physics: BouncingScrollPhysics(),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 16 : 24,
                    vertical: 16,
                  ),
                  constraints: BoxConstraints(
                    minHeight: screenHeight -
                        MediaQuery.of(context).padding.top -
                        MediaQuery.of(context).padding.bottom,
                  ),
                  child: Opacity(
                    opacity: _fadeAnimation.value,
                    child: Transform.translate(
                      offset: Offset(0, _slideAnimation.value),
                      child: Transform.scale(
                        scale: _scaleAnimation.value,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Welcome Section
                            _buildWelcomeSection(isSmallScreen),
                            SizedBox(height: isSmallScreen ? 10 : 15),

                            // Login Form
                            _buildLoginForm(isSmallScreen, authProvider),
                            
                            // Guest Mode Section
                            SizedBox(height: isSmallScreen ? 10 : 12),
                            _buildGuestModeSection(isSmallScreen, authProvider),
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

  // Updated Guest Mode section with TextButton instead of fancy button
  Widget _buildGuestModeSection(bool isSmallScreen, AuthProvider authProvider) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // OR Divider
        Padding(
          padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 20 : 32),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Colors.white.withOpacity(0.3),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 16 : 20),
                child: Text(
                  'OR',
                  style: GoogleFonts.poppins(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: isSmallScreen ? 12 : 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Colors.white.withOpacity(0.3),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Continue as Guest TextButton - Simple and instant
        TextButton(
          onPressed: () => _continueAsGuest(context, authProvider),
          style: TextButton.styleFrom(
            padding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 24 : 32,
              vertical: isSmallScreen ? 8 : 10,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.person_outline_rounded,
                color: Colors.white,
                size: isSmallScreen ? 18 : 20,
              ),
              SizedBox(width: isSmallScreen ? 8 : 10),
              Text(
                "Continue as Guest",
                style: GoogleFonts.poppins(
                  fontSize: isSmallScreen ? 14 : 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  decoration: TextDecoration.underline,
                ),
              ),
            ],
          ),
        ),
        
        SizedBox(height: isSmallScreen ? 2 : 3),
        
        // Guest info text
        Text(
          'Browse all features without an account',
          style: GoogleFonts.inter(
            fontSize: isSmallScreen ? 11 : 12,
            color: Colors.white.withOpacity(0.7),
            fontWeight: FontWeight.w500,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  // Updated _continueAsGuest method - no loading state
  Future<void> _continueAsGuest(BuildContext context, AuthProvider authProvider) async {
    try {
      await authProvider.continueAsGuest(context);
      // Navigation is handled in authProvider.continueAsGuest
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Color(0xFFF42A41),
            content: Text('Failed to continue as guest: $e'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Widget _buildWelcomeSection(bool isSmallScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Logo Circle - Fills Entire Circle
        Center(
          child: Container(
            width: isSmallScreen ? 70 : 90,
            height: isSmallScreen ? 70 : 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  _primaryRed,
                  _primaryRed.withOpacity(0.8),
                  _primaryGreen,
                ],
                center: Alignment.center,
                radius: 0.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: _primaryRed.withOpacity(0.3),
                  blurRadius: 25,
                  spreadRadius: 3,
                ),
              ],
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/logo/logo.png',
                fit: BoxFit.cover,
                width: isSmallScreen ? 70 : 90,
                height: isSmallScreen ? 70 : 90,
                errorBuilder: (context, error, stackTrace) {
                  print('Error loading logo: $error');
                  // Fallback with icon only (no inner white circle)
                  return Center(
                    child: Icon(
                      Icons.groups,
                      size: isSmallScreen ? 30 : 40,
                      color: Colors.white,
                    ),
                  );
                },
              ),
            ),
          ),
        ),

        SizedBox(height: isSmallScreen ? 17 : 25),
        
        // Welcome Text
        Text(
          'BanglaHub',
          style: GoogleFonts.poppins(
            fontSize: isSmallScreen ? 28 : 35,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            height: 1.1,
            letterSpacing: 0.5,
          ),
        ),
        SizedBox(height: isSmallScreen ? 6 : 8),
        Container(
          width: 60,
          height: 4,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_primaryRed, _goldAccent],
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        SizedBox(height: isSmallScreen ? 12 : 18),
        Text(
          'Sign in to connect with the BanglaHub community',
          style: GoogleFonts.inter(
            fontSize: isSmallScreen ? 12 : 14,
            color: Colors.white.withOpacity(0.9),
            fontWeight: FontWeight.w400,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginForm(bool isSmallScreen, AuthProvider authProvider) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Form Container
        Container(
          padding: EdgeInsets.all(isSmallScreen ? 14 : 18),
          decoration: BoxDecoration(
            color: _offWhite,
            borderRadius: BorderRadius.circular(isSmallScreen ? 18 : 22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 20,
                offset: Offset(0, 10),
                spreadRadius: -3,
              ),
              BoxShadow(
                color: _primaryGreen.withOpacity(0.08),
                blurRadius: 15,
                offset: Offset(0, 5),
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
              mainAxisSize: MainAxisSize.min,
              children: [
                // Email Field
                _buildTextField(
                  controller: _emailController,
                  label: 'Email Address',
                  hintText: 'Enter your email',
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  focusNode: _emailFocus,
                  isSmallScreen: isSmallScreen,
                ),
                SizedBox(height: isSmallScreen ? 10 : 12),

                // Password Field
                _buildTextField(
                  controller: _passwordController,
                  label: 'Password',
                  hintText: 'Enter your password',
                  prefixIcon: Icons.lock_outline_rounded,
                  obscureText: _obscurePassword,
                  suffixIcon: IconButton(
                    icon: AnimatedSwitcher(
                      duration: Duration(milliseconds: 300),
                      child: Icon(
                        _obscurePassword 
                            ? Icons.visibility_outlined 
                            : Icons.visibility_off_outlined,
                        key: ValueKey<bool>(_obscurePassword),
                        color: _primaryGreen,
                        size: isSmallScreen ? 18 : 20,
                      ),
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    constraints: BoxConstraints(minWidth: 32, minHeight: 32),
                    padding: EdgeInsets.zero,
                  ),
                  focusNode: _passwordFocus,
                  isSmallScreen: isSmallScreen,
                ),
                SizedBox(height: isSmallScreen ? 8 : 10),

                // Remember Me & Forgot Password
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Remember Me
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _rememberMe = !_rememberMe;
                        });
                      },
                      child: Row(
                        children: [
                          AnimatedContainer(
                            duration: Duration(milliseconds: 200),
                            width: isSmallScreen ? 14 : 16,
                            height: isSmallScreen ? 14 : 16,
                            decoration: BoxDecoration(
                              gradient: _rememberMe
                                  ? LinearGradient(
                                      colors: [_primaryRed, _primaryGreen],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    )
                                  : null,
                              color: _rememberMe ? null : Colors.transparent,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: _rememberMe ? Colors.transparent : Colors.grey[400]!,
                                width: 1.5,
                              ),
                              boxShadow: _rememberMe
                                  ? [
                                      BoxShadow(
                                        color: _primaryRed.withOpacity(0.15),
                                        blurRadius: 6,
                                        offset: Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: _rememberMe
                                ? Center(
                                    child: Icon(
                                      Icons.check_rounded,
                                      size: isSmallScreen ? 9 : 10,
                                      color: Colors.white,
                                    ),
                                  )
                                : null,
                          ),
                          SizedBox(width: isSmallScreen ? 4 : 6),
                          Text(
                            'Remember me',
                            style: GoogleFonts.inter(
                              fontSize: isSmallScreen ? 9 : 11,
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Forgot Password
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ResetPasswordScreen(),
                          ),
                        );
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size(0, 24),
                      ),
                      child: Text(
                        'Forgot Password?',
                        style: GoogleFonts.inter(
                          fontSize: isSmallScreen ? 11 : 13,
                          fontWeight: FontWeight.w600,
                          color: _primaryRed,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: isSmallScreen ? 12 : 15),

                // Login Button
                _buildLoginButton(isSmallScreen, authProvider),
              ],
            ),
          ),
        ),
     
        SizedBox(height: isSmallScreen ? 12 : 16),

        // Or Divider
        _buildOrDivider(isSmallScreen),
        SizedBox(height: isSmallScreen ? 12 : 15),

        // Register Section
        _buildRegisterSection(isSmallScreen),
        SizedBox(height: isSmallScreen ? 4 : 6),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    required IconData prefixIcon,
    required FocusNode focusNode,
    bool isSmallScreen = false,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 14),
        boxShadow: focusNode.hasFocus
            ? [
                BoxShadow(
                  color: _primaryGreen.withOpacity(0.15),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 6,
                  offset: Offset(0, 3),
                ),
              ],
      ),
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: keyboardType,
        obscureText: obscureText,
        style: GoogleFonts.inter(
          color: Colors.black87,
          fontSize: isSmallScreen ? 14 : 15,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.3,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.inter(
            color: focusNode.hasFocus ? _primaryGreen : Colors.grey[600],
            fontWeight: FontWeight.w500,
            fontSize: isSmallScreen ? 12 : 13,
          ),
          hintText: hintText,
          hintStyle: GoogleFonts.inter(
            color: Colors.grey[500],
            fontSize: isSmallScreen ? 13 : 14,
          ),
          prefixIcon: Padding(
            padding: EdgeInsets.only(left: 14, right: 10),
            child: Icon(
              prefixIcon,
              color: focusNode.hasFocus ? _primaryGreen : Colors.grey[600],
              size: isSmallScreen ? 20 : 22,
            ),
          ),
          suffixIcon: suffixIcon != null
              ? Padding(
                  padding: EdgeInsets.only(right: 6),
                  child: suffixIcon,
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 14),
            borderSide: BorderSide(
              color: Colors.grey[300]!,
              width: 1.2,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 14),
            borderSide: BorderSide(
              color: _primaryGreen,
              width: 2.0,
            ),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 16,
            vertical: isSmallScreen ? 12 : 14,
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter your $label';
          }
          if (label.toLowerCase().contains('email') && 
              !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
            return 'Please enter a valid email address';
          }
          if (label.toLowerCase().contains('password') && value.length < 6) {
            return 'Password must be at least 6 characters';
          }
          return null;
        },
      ),
    );
  }



/*  Widget _buildLoginButton(bool isSmallScreen, AuthProvider authProvider) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 500),
      width: double.infinity,
      height: isSmallScreen ? 56 : 64,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_primaryRed, _primaryGreen],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          stops: [0.0, 1.0],
        ),
        borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 20),
        boxShadow: [
          BoxShadow(
            color: _primaryRed.withOpacity(0.3),
            blurRadius: 20,
            offset: Offset(0, 8),
            spreadRadius: 2,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 20),
        child: InkWell(
          onTap: authProvider.isLoading ? null : () => _login(context, authProvider),
          borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 20),
          splashColor: Colors.white.withOpacity(0.2),
          highlightColor: Colors.white.withOpacity(0.1),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: AnimatedSwitcher(
              duration: Duration(milliseconds: 300),
              child: authProvider.isLoading
                  ? Center(
                      child: SizedBox(
                        width: isSmallScreen ? 24 : 28,
                        height: isSmallScreen ? 24 : 28,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Sign In',
                          style: GoogleFonts.poppins(
                            fontSize: isSmallScreen ? 17 : 19,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.8,
                          ),
                        ),
                        SizedBox(width: isSmallScreen ? 12 : 16),
                        Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: isSmallScreen ? 18 : 20,
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }


*/


Widget _buildLoginButton(bool isSmallScreen, AuthProvider authProvider) {
  final isLoading = authProvider.isLoading;
  
  return AnimatedContainer(
    duration: const Duration(milliseconds: 500),
    width: double.infinity,
    height: isSmallScreen ? 56 : 64,
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [_primaryRed, _primaryGreen],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        stops: const [0.0, 1.0],
      ),
      borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 20),
      boxShadow: [
        BoxShadow(
          color: _primaryRed.withOpacity(0.3),
          blurRadius: 20,
          offset: const Offset(0, 8),
          spreadRadius: 2,
        ),
      ],
    ),
    child: Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 20),
      child: InkWell(
        onTap: isLoading ? null : () => _login(context, authProvider),
        borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 20),
        splashColor: Colors.white.withOpacity(0.2),
        highlightColor: Colors.white.withOpacity(0.1),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            switchInCurve: Curves.easeInOut,
            switchOutCurve: Curves.easeInOut,
            child: isLoading
                ? Center(
                    key: const ValueKey('loading'),
                    child: SizedBox(
                      width: isSmallScreen ? 24 : 28,
                      height: isSmallScreen ? 24 : 28,
                      child: const CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                  )
                : Row(
                    key: const ValueKey('button'),
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Sign In',
                        style: GoogleFonts.poppins(
                          fontSize: isSmallScreen ? 17 : 19,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.8,
                        ),
                      ),
                      SizedBox(width: isSmallScreen ? 12 : 16),
                      Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white,
                        size: isSmallScreen ? 18 : 20,
                      ),
                    ],
                  ),
          ),
        ),
      ),
    ),
  );
}








  Widget _buildOrDivider(bool isSmallScreen) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 20 : 32),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Colors.white.withOpacity(0.3),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 16 : 20),
            child: Text(
              'OR',
              style: GoogleFonts.poppins(
                color: Colors.white.withOpacity(0.7),
                fontSize: isSmallScreen ? 12 : 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.5,
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Colors.white.withOpacity(0.3),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterSection(bool isSmallScreen) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          "Don't have an account?",
          style: GoogleFonts.inter(
            fontSize: isSmallScreen ? 12 : 14,
            color: Colors.white.withOpacity(0.95),
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 4,
                offset: Offset(0, 1),
              ),
            ],
          ),
        ),
        SizedBox(height: isSmallScreen ? 10 : 12),
        MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: AnimatedContainer(
            duration: Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            transform: Matrix4.identity()
              ..scale(_isHovered ? 1.02 : 1.0),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(isSmallScreen ? 18 : 22),
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RegisterScreen(role: 'user'),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(isSmallScreen ? 18 : 22),
                splashColor: _primaryRed.withOpacity(0.7),
                highlightColor: _primaryGreen.withOpacity(0.3),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 24 : 32,
                    vertical: isSmallScreen ? 8 : 10,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_primaryRed, _primaryGreen],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(isSmallScreen ? 18 : 22),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.4),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 25,
                        offset: Offset(0, 10),
                        spreadRadius: 0,
                      ),
                      BoxShadow(
                        color: _primaryRed.withOpacity(0.5),
                        blurRadius: 30,
                        offset: Offset(-8, 0),
                        spreadRadius: 0,
                      ),
                      BoxShadow(
                        color: _primaryGreen.withOpacity(0.5),
                        blurRadius: 30,
                        offset: Offset(8, 0),
                        spreadRadius: 0,
                      ),
                      BoxShadow(
                        color: _goldAccent.withOpacity(0.2),
                        blurRadius: 15,
                        offset: Offset(0, 0),
                        spreadRadius: 0,
                        blurStyle: BlurStyle.inner,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Create New Account",
                        style: GoogleFonts.poppins(
                          fontSize: isSmallScreen ? 12 : 14,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                          color: Colors.white,
                          height: 1.2,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.5),
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                            Shadow(
                              color: _goldAccent.withOpacity(0.3),
                              blurRadius: 10,
                              offset: Offset(0, 0),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: isSmallScreen ? 12 : 16),
                      Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white,
                        size: isSmallScreen ? 18 : 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }


/*  Future<void> _login(BuildContext context, AuthProvider authProvider) async {
    if (_formKey.currentState!.validate()) {
      try {
        await authProvider.signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          context: context,
        );

        // Login successful
        if (authProvider.user != null && mounted) {
          if (authProvider.user!.isAdmin) {
            // Admin dashboard
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => AdminHomeScreen()),
              (_) => false,
            );
          } else {
            // User home
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const HomeScreen()),
              (_) => false,
            );
          }
        }
      } catch (e) {
        // Generic error handling only
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: _primaryRed,
              content: Text(e.toString()),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

*/


Future<void> _login(BuildContext context, AuthProvider authProvider) async {
  if (_formKey.currentState!.validate()) {
    // Remove focus from fields
    FocusScope.of(context).unfocus();
    
    try {
      await authProvider.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        context: context,
      );

      // Login successful - check if user exists
      if (mounted && authProvider.user != null) {
        if (authProvider.user!.isAdmin) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const AdminHomeScreen()),
            (route) => false,
          );
        } else {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
            (route) => false,
          );
        }
      } else if (mounted && authProvider.user == null) {
        // This case shouldn't happen, but handle it
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.orange,
            content: Text('Login successful but user data not loaded. Please try again.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      // Show error message - this will catch "No account found" etc.
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars(); // Clear any existing snackbars
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: _primaryRed,
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white, size: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    e.toString(),
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  } else {
    // Form validation failed - show validation errors
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.orange,
          content: Text('Please fill all fields correctly'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
}


  void _showEmailVerificationDialog(BuildContext context, AuthProvider authProvider) {
    print('🟡 Dialog triggered - Email: ${_emailController.text}');
    
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (context) {
        print('🟢 Dialog builder called - Context: ${context.widget.runtimeType}');
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.symmetric(
            horizontal: max(20, MediaQuery.of(context).size.width * 0.05),
            vertical: 20,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 500,
              minWidth: 300,
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 40,
                    spreadRadius: 0,
                    offset: Offset(0, 15),
                  ),
                  BoxShadow(
                    color: _primaryGreen.withOpacity(0.08),
                    blurRadius: 20,
                    offset: Offset(0, 5),
                  ),
                ],
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header with gradient
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(vertical: 28, horizontal: 24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            _primaryRed,
                            _primaryGreen,
                          ],
                          stops: [0.0, 1.0],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _primaryRed.withOpacity(0.3),
                            blurRadius: 20,
                            offset: Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Animated icon container
                          Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.25),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.2),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Center(
                              child: Icon(
                                Icons.verified_outlined,
                                size: 34,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          SizedBox(height: 20),
                          Text(
                            'Email Verification Required',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: MediaQuery.of(context).size.width < 400 ? 18 : 22,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                              height: 1.3,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Secure your account access',
                            style: GoogleFonts.inter(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Scrollable content area
                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Instruction text
                            Text(
                              'To ensure your security, please verify your email address before accessing your account.',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                height: 1.6,
                                color: Colors.grey[800],
                              ),
                            ),
                            SizedBox(height: 28),
                            
                            // Email display
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.mark_email_read_outlined,
                                      color: _primaryGreen,
                                      size: 18,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Verification link sent to:',
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 12),
                                Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: _primaryGreen.withOpacity(0.3),
                                      width: 1.5,
                                    ),
                                    color: _primaryGreen.withOpacity(0.05),
                                    boxShadow: [
                                      BoxShadow(
                                        color: _primaryGreen.withOpacity(0.08),
                                        blurRadius: 10,
                                        offset: Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: _primaryGreen.withOpacity(0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Center(
                                          child: Icon(
                                            Icons.email_rounded,
                                            color: _primaryGreen,
                                            size: 20,
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Email Address',
                                              style: GoogleFonts.inter(
                                                fontSize: 12,
                                                color: Colors.grey[600],
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            SizedBox(height: 4),
                                            Text(
                                              _emailController.text,
                                              overflow: TextOverflow.ellipsis,
                                              style: GoogleFonts.inter(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600,
                                                color: _primaryGreen,
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
                            SizedBox(height: 28),
                            
                            // Steps
                            Container(
                              padding: EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                color: _lightGreen,
                                border: Border.all(
                                  color: _primaryGreen.withOpacity(0.15),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.checklist_rounded,
                                        color: _darkGreen,
                                        size: 20,
                                      ),
                                      SizedBox(width: 10),
                                      Text(
                                        'Complete these steps:',
                                        style: GoogleFonts.inter(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: _darkGreen,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 16),
                                  _buildStep(
                                    number: 1,
                                    icon: Icons.inbox_outlined,
                                    text: 'Open your email inbox',
                                    context: context,
                                  ),
                                  _buildStep(
                                    number: 2,
                                    icon: Icons.link_rounded,
                                    text: 'Click the verification link',
                                    context: context,
                                  ),
                                  _buildStep(
                                    number: 3,
                                    icon: Icons.login_rounded,
                                    text: 'Return and sign in again',
                                    context: context,
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 16),
                            
                            // Note
                            Container(
                              padding: EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: Colors.orange[50],
                                border: Border.all(
                                  color: Colors.orange[200]!,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.info_outline_rounded,
                                    color: Colors.orange[700],
                                    size: 18,
                                  ),
                                  SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'If you don\'t see the email, check your spam folder or click "Resend Email" below.',
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        color: Colors.orange[800],
                                        height: 1.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 8),
                          ],
                        ),
                      ),
                    ),
                    
                    // Action buttons
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 22),
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(
                            color: Colors.grey[200]!,
                            width: 1.5,
                          ),
                        ),
                        color: _offWhite,
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(28),
                          bottomRight: Radius.circular(28),
                        ),
                      ),
                      child: Row(
                        children: [
                          // Back button
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                print('🔴 Back button pressed - Closing dialog...');
                                if (mounted) {
                                  Navigator.pop(context);
                                }
                              },
                              style: OutlinedButton.styleFrom(
                                padding: EdgeInsets.symmetric(vertical: 17),
                                side: BorderSide(
                                  color: Colors.grey[400]!,
                                  width: 1.5,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                backgroundColor: Colors.white,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.arrow_back_rounded,
                                    size: 18,
                                    color: Colors.grey[700],
                                  ),
                                  SizedBox(width: 10),
                                  Text(
                                    'Back to Login',
                                    style: GoogleFonts.inter(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(width: 16),
                          
                          // Resend button
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                print('🟢 Resend button pressed - Closing dialog...');
                                if (mounted) {
                                  Navigator.pop(context);
                                }
                                
                                try {
                                  print('🟡 Sending verification email...');
                                  await authProvider.sendVerificationEmail();
                                  print('🟢 Email sent successfully');
                                  
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        backgroundColor: _primaryGreen,
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        content: Row(
                                          children: [
                                            Icon(Icons.check_circle, color: Colors.white, size: 22),
                                            SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Verification Email Sent!',
                                                    style: GoogleFonts.inter(
                                                      fontWeight: FontWeight.w700,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                  SizedBox(height: 2),
                                                  Text(
                                                    'Check your inbox and spam folder',
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
                                        duration: Duration(seconds: 4),
                                        margin: EdgeInsets.all(20),
                                        padding: EdgeInsets.all(16),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  print('🔴 Failed to send email: $e');
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        backgroundColor: _primaryRed,
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        content: Row(
                                          children: [
                                            Icon(Icons.error_outline, color: Colors.white, size: 22),
                                            SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Failed to Send Email',
                                                    style: GoogleFonts.inter(
                                                      fontWeight: FontWeight.w700,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                  SizedBox(height: 2),
                                                  Text(
                                                    'Please try again in a moment',
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
                                        duration: Duration(seconds: 4),
                                        margin: EdgeInsets.all(20),
                                        padding: EdgeInsets.all(16),
                                      ),
                                    );
                                  }
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _primaryGreen,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(vertical: 17),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                elevation: 0,
                                shadowColor: _primaryGreen.withOpacity(0.3),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.refresh_rounded, size: 20),
                                  SizedBox(width: 10),
                                  Text(
                                    'Resend Email',
                                    style: GoogleFonts.inter(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
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

  Widget _buildStep({required int number, required IconData icon, required String text, required BuildContext context}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _primaryRed.withOpacity(0.3),
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Center(
              child: Text(
                '$number',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      icon,
                      color: _primaryGreen,
                      size: 16,
                    ),
                    SizedBox(width: 8),
                    Text(
                      text,
                      style: GoogleFonts.inter(
                        fontSize: MediaQuery.of(context).size.width < 400 ? 14 : 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Container(
                  height: 1,
                  color: _primaryGreen.withOpacity(0.1),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Social Login Methods
  Future<void> _signInWithGoogle() async {
    _showSocialLoginMessage('Google');
  }

  Future<void> _signInWithApple() async {
    _showSocialLoginMessage('Apple');
  }

  Future<void> _signInWithFacebook() async {
    _showSocialLoginMessage('Facebook');
  }

  void _showSocialLoginMessage(String provider) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        backgroundColor: _primaryGreen,
        elevation: 10,
        margin: EdgeInsets.all(20),
        content: Row(
          children: [
            Icon(Icons.info_outline_rounded, color: Colors.white),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                '$provider sign in coming soon',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        duration: Duration(seconds: 3),
      ),
    );
  }
}