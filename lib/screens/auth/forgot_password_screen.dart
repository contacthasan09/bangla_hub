import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:bangla_hub/providers/auth_provider.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({Key? key}) : super(key: key);

  @override
  _ResetPasswordScreenState createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final FocusNode _emailFocus = FocusNode();
  
  // Animation controllers
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<Color?> _gradientAnimation;
  
  // Track app lifecycle
  AppLifecycleState _appLifecycleState = AppLifecycleState.resumed;
  
  // Color scheme
  final Color _primaryRed = const Color(0xFFF42A41);
  final Color _primaryGreen = const Color(0xFF006A4E);
  final Color _darkGreen = const Color(0xFF004D38);
  final Color _goldAccent = const Color(0xFFFFD700);
  final Color _offWhite = const Color(0xFFF8F8F8);

  @override
  void initState() {
    super.initState();
    
    // Add WidgetsBindingObserver
    WidgetsBinding.instance.addObserver(this);
    
    // Initialize animations
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeInOut),
      ),
    );
    
    _slideAnimation = Tween<double>(begin: 80.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOutQuint),
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
    
    _animationController.forward();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    setState(() {
      _appLifecycleState = state;
    });
    
    // Pause animations when app is in background
    if (state == AppLifecycleState.paused || 
        state == AppLifecycleState.inactive || 
        state == AppLifecycleState.detached) {
      _animationController.stop();
    } else if (state == AppLifecycleState.resumed) {
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    print('🗑️ ResetPasswordScreen disposing...');
    
    // Remove observer
    WidgetsBinding.instance.removeObserver(this);
    
    // Dispose animation controller
    _animationController.dispose();
    
    // Dispose focus node
    _emailFocus.dispose();
    
    // Dispose text controller
    _emailController.dispose();
    
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenHeight < 700;
    final isVerySmallScreen = screenWidth < 350;

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
                physics: const BouncingScrollPhysics(),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isVerySmallScreen ? 12 : (isSmallScreen ? 16 : 24),
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Back Button
                          _buildBackButton(isSmallScreen, isVerySmallScreen),
                          SizedBox(height: isSmallScreen ? 15 : 20),
                          
                          // Header Section
                          _buildHeaderSection(isSmallScreen, isVerySmallScreen),
                          SizedBox(height: isSmallScreen ? 25 : 30),

                          // Reset Form
                          _buildResetForm(isSmallScreen, isVerySmallScreen, authProvider),
                          SizedBox(height: isSmallScreen ? 20 : 30),
                        ],
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

  Widget _buildBackButton(bool isSmallScreen, bool isVerySmallScreen) {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Icon(
        Icons.arrow_back_ios_new_rounded,
        color: Colors.white,
        size: isVerySmallScreen ? 16 : (isSmallScreen ? 18 : 22),
      ),
    );
  }

  Widget _buildHeaderSection(bool isSmallScreen, bool isVerySmallScreen) {
    final double logoSize = isVerySmallScreen ? 70.0 : (isSmallScreen ? 80.0 : 100.0);
    final double innerSize = isVerySmallScreen ? 32.0 : (isSmallScreen ? 38.0 : 48.0);
    final double iconSize = isVerySmallScreen ? 18.0 : (isSmallScreen ? 22.0 : 26.0);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Logo Circle with actual logo image
        Center(
          child: Container(
            width: logoSize,
            height: logoSize,
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
                width: logoSize,
                height: logoSize,
                errorBuilder: (context, error, stackTrace) {
                  print('Error loading logo: $error');
                  // Fallback with lock reset icon
                  return Center(
                    child: Icon(
                      Icons.lock_reset_rounded,
                      size: logoSize * 0.5,
                      color: Colors.white,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        SizedBox(height: isSmallScreen ? 20 : 32),
        
        // Header Text
        Text(
          'Reset Password',
          style: GoogleFonts.poppins(
            fontSize: isVerySmallScreen ? 24 : (isSmallScreen ? 28 : 35),
            fontWeight: FontWeight.w800,
            color: Colors.white,
            height: 1.1,
            letterSpacing: 0.5,
          ),
        ),
        SizedBox(height: isSmallScreen ? 8 : 12),
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
          'Enter your email to receive a password reset link',
          style: GoogleFonts.inter(
            fontSize: isVerySmallScreen ? 11 : (isSmallScreen ? 12 : 14),
            color: Colors.white.withOpacity(0.9),
            fontWeight: FontWeight.w400,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildResetForm(bool isSmallScreen, bool isVerySmallScreen, AuthProvider authProvider) {
    return Container(
      padding: EdgeInsets.all(isVerySmallScreen ? 16 : (isSmallScreen ? 22 : 28)),
      decoration: BoxDecoration(
        color: _offWhite,
        borderRadius: BorderRadius.circular(isVerySmallScreen ? 18 : (isSmallScreen ? 22 : 28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 30,
            offset: const Offset(0, 15),
            spreadRadius: -5,
          ),
          BoxShadow(
            color: _primaryGreen.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
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
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(isVerySmallScreen ? 12 : (isSmallScreen ? 14 : 16)),
                boxShadow: _emailFocus.hasFocus
                    ? [
                        BoxShadow(
                          color: _primaryGreen.withOpacity(0.15),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: TextFormField(
                controller: _emailController,
                focusNode: _emailFocus,
                keyboardType: TextInputType.emailAddress,
                style: GoogleFonts.inter(
                  color: Colors.black87,
                  fontSize: isVerySmallScreen ? 13 : (isSmallScreen ? 15 : 16),
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.3,
                ),
                decoration: InputDecoration(
                  labelText: 'Email Address',
                  labelStyle: GoogleFonts.inter(
                    color: _emailFocus.hasFocus ? _primaryGreen : Colors.grey[600],
                    fontWeight: FontWeight.w500,
                    fontSize: isVerySmallScreen ? 12 : (isSmallScreen ? 14 : 15),
                  ),
                  hintText: 'Enter your email',
                  hintStyle: GoogleFonts.inter(
                    color: Colors.grey[500],
                    fontSize: isVerySmallScreen ? 13 : (isSmallScreen ? 15 : 16),
                  ),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(left: 16, right: 12),
                    child: Icon(
                      Icons.email_outlined,
                      color: _emailFocus.hasFocus ? _primaryGreen : Colors.grey[600],
                      size: isVerySmallScreen ? 18 : (isSmallScreen ? 22 : 24),
                    ),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(isVerySmallScreen ? 12 : (isSmallScreen ? 14 : 16)),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(isVerySmallScreen ? 12 : (isSmallScreen ? 14 : 16)),
                    borderSide: BorderSide(
                      color: Colors.grey[300]!,
                      width: 1.5,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(isVerySmallScreen ? 12 : (isSmallScreen ? 14 : 16)),
                    borderSide: BorderSide(
                      color: _primaryGreen,
                      width: 2.5,
                    ),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: isVerySmallScreen ? 14 : (isSmallScreen ? 18 : 22),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email address';
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                    return 'Please enter a valid email address';
                  }
                  return null;
                },
              ),
            ),
            SizedBox(height: isVerySmallScreen ? 12 : (isSmallScreen ? 14 : 18)),

            // Instruction Text
            Container(
              padding: EdgeInsets.all(isVerySmallScreen ? 12 : (isSmallScreen ? 16 : 20)),
              decoration: BoxDecoration(
                color: _primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(isVerySmallScreen ? 12 : (isSmallScreen ? 14 : 16)),
                border: Border.all(
                  color: _primaryGreen.withOpacity(0.2),
                  width: 1.5,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: _primaryGreen,
                    size: isVerySmallScreen ? 14 : (isSmallScreen ? 18 : 20),
                  ),
                  SizedBox(width: isVerySmallScreen ? 8 : (isSmallScreen ? 12 : 16)),
                  Expanded(
                    child: Text(
                      'We will send you a link to reset your password. Please check your inbox and spam folder.',
                      style: GoogleFonts.inter(
                        fontSize: isVerySmallScreen ? 11 : (isSmallScreen ? 13 : 14),
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: isVerySmallScreen ? 20 : (isSmallScreen ? 28 : 36)),

            // Reset Button
            _buildResetButton(isSmallScreen, isVerySmallScreen, authProvider),
            SizedBox(height: isVerySmallScreen ? 12 : (isSmallScreen ? 16 : 20)),

            // Back to Login
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(
                  horizontal: isVerySmallScreen ? 12 : 20,
                  vertical: isVerySmallScreen ? 8 : 12,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.arrow_back_rounded,
                    color: _primaryGreen,
                    size: isVerySmallScreen ? 14 : (isSmallScreen ? 16 : 18),
                  ),
                  SizedBox(width: isVerySmallScreen ? 6 : (isSmallScreen ? 8 : 12)),
                  Text(
                    'Back to Login',
                    style: GoogleFonts.inter(
                      fontSize: isVerySmallScreen ? 13 : (isSmallScreen ? 15 : 16),
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
    );
  }

  Widget _buildResetButton(bool isSmallScreen, bool isVerySmallScreen, AuthProvider authProvider) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      width: double.infinity,
      height: isVerySmallScreen ? 44 : (isSmallScreen ? 56 : 64),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_primaryRed, _primaryGreen],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          stops: const [0.0, 1.0],
        ),
        borderRadius: BorderRadius.circular(isVerySmallScreen ? 12 : (isSmallScreen ? 16 : 20)),
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
        borderRadius: BorderRadius.circular(isVerySmallScreen ? 12 : (isSmallScreen ? 16 : 20)),
        child: InkWell(
          onTap: authProvider.isLoading ? null : () => _resetPassword(context, authProvider),
          borderRadius: BorderRadius.circular(isVerySmallScreen ? 12 : (isSmallScreen ? 16 : 20)),
          splashColor: Colors.white.withOpacity(0.2),
          highlightColor: Colors.white.withOpacity(0.1),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: isVerySmallScreen ? 12 : 24),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: authProvider.isLoading
                  ? Center(
                      child: SizedBox(
                        width: isVerySmallScreen ? 18 : (isSmallScreen ? 24 : 28),
                        height: isVerySmallScreen ? 18 : (isSmallScreen ? 24 : 28),
                        child: const CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Send Reset Link',
                          style: GoogleFonts.poppins(
                            fontSize: isVerySmallScreen ? 13 : (isSmallScreen ? 16 : 18),
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.8,
                          ),
                        ),
                        SizedBox(width: isVerySmallScreen ? 10 : (isSmallScreen ? 15 : 18)),
                        Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                          size: isVerySmallScreen ? 14 : (isSmallScreen ? 18 : 20),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _resetPassword(BuildContext context, AuthProvider authProvider) async {
    if (_formKey.currentState!.validate()) {
      try {
        await authProvider.resetPassword(_emailController.text.trim());
        
        // Show success dialog if widget is still mounted
        if (mounted) {
          _showSuccessDialog(context);
        }
      } catch (e) {
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

  void _showSuccessDialog(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isVerySmallScreen = screenWidth < 350;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        backgroundColor: Colors.white,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: isVerySmallScreen ? 60 : 80,
              height: isVerySmallScreen ? 60 : 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [_primaryGreen, _primaryRed],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Icon(
                Icons.check_rounded,
                size: isVerySmallScreen ? 30 : 40,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Email Sent!',
              style: GoogleFonts.poppins(
                fontSize: isVerySmallScreen ? 20 : 24,
                fontWeight: FontWeight.w700,
                color: _primaryGreen,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Password reset link has been sent to:',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: isVerySmallScreen ? 13 : 16,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _primaryGreen.withOpacity(0.3),
                ),
              ),
              child: Text(
                _emailController.text,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  color: _primaryGreen,
                  fontSize: isVerySmallScreen ? 12 : 14,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Please check your inbox and follow the instructions.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: isVerySmallScreen ? 12 : 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext); // Close dialog
                if (mounted) {
                  Navigator.pop(context); // Go back to login
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryGreen,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: isVerySmallScreen ? 24 : 32,
                  vertical: isVerySmallScreen ? 10 : 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Back to Login',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: isVerySmallScreen ? 13 : 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}