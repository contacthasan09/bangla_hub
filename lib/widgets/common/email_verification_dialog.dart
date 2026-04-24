import 'dart:async';

import 'package:bangla_hub/screens/user_app/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:bangla_hub/providers/auth_provider.dart';
import 'package:bangla_hub/screens/auth/login_screen.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String email;
  final VoidCallback onVerified;

  const EmailVerificationScreen({
    Key? key,
    required this.email,
    required this.onVerified,
  }) : super(key: key);

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  
  bool _isResending = false;
  bool _isNavigating = false;
  int _checkCount = 0;
  bool _showEmailHelp = false;
  Timer? _checkTimer;
  bool _isActive = true;
  bool _isChecking = true;
  
  // Animation controllers
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _scaleAnimation;
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
    
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 0.9, curve: Curves.elasticOut),
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
    
    print('📧 [EmailVerificationScreen] Screen initialized for: ${widget.email}');
    _startVerificationCheck();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    setState(() {
      _appLifecycleState = state;
    });
    
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
    print('📧 [EmailVerificationScreen] Screen disposed');
    _isActive = false;
    _checkTimer?.cancel();
    _animationController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _startVerificationCheck() {
    print('📧 [EmailVerificationScreen] Starting verification check loop');
    _scheduleNextCheck(2);
  }

  void _scheduleNextCheck(int seconds) {
    if (!_isActive || _isNavigating) return;
    
    _checkTimer?.cancel();
    _checkTimer = Timer(Duration(seconds: seconds), () {
      if (_isActive && !_isNavigating) {
        _checkVerification();
      }
    });
  }

  Future<void> _checkVerification() async {
    if (!_isActive || _isNavigating) return;
    
    _checkCount++;
    if (mounted) setState(() {});
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.reload();
        print('📧 [EmailVerificationScreen] Verification check #$_checkCount - Email: ${user.email}, Verified: ${user.emailVerified}');
        
        if (user.emailVerified) {
          print('✅ [EmailVerificationScreen] Email verified successfully!');
          _isNavigating = true;
          _checkTimer?.cancel();
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Email verified! Redirecting...'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
            await Future.delayed(const Duration(seconds: 1));
            widget.onVerified();
            if (mounted) {
              print('🚀 [EmailVerificationScreen] Navigating to HomeScreen');
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const HomeScreen()),
                (route) => false,
              );
            }
          }
          return;
        }
      }
      
      if (mounted && !_isNavigating) {
        if (_checkCount >= 3 && !_showEmailHelp) {
          setState(() {
            _showEmailHelp = true;
          });
        }
        
        print('📧 [EmailVerificationScreen] Email not verified yet, checking again in 3 seconds');
        _scheduleNextCheck(3);
      }
    } catch (e) {
      print('❌ [EmailVerificationScreen] Error checking verification: $e');
      if (mounted && !_isNavigating) {
        _scheduleNextCheck(5);
      }
    }
  }

  Future<void> _resendVerificationEmail() async {
    if (_isResending || _isNavigating) return;
    
    print('📧 [EmailVerificationScreen] Resend verification email requested');
    _isResending = true;
    if (mounted) setState(() {});
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUser = authProvider.user;
      
      if (currentUser != null && currentUser.email == widget.email) {
        print('📧 [EmailVerificationScreen] User found, sending verification email...');
        
        await authProvider.sendVerificationEmail();
        
        print('✅ Verification email sent successfully to: ${widget.email}');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '✅ Verification Email Sent!',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'A new verification link has been sent to ${widget.email}',
                    style: GoogleFonts.inter(fontSize: 12),
                  ),
                  Text(
                    'Please check your email and verify your account.',
                    style: GoogleFonts.inter(fontSize: 11, color: Colors.white70),
                  ),
                ],
              ),
              backgroundColor: Colors.green.shade700,
              duration: const Duration(seconds: 4),
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
          
          _checkCount = 0;
          _showEmailHelp = false;
          
          if (mounted) {
            setState(() {});
          }
        }
      } else {
        print('❌ No user logged in - cannot resend');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Unable to resend. Please try logging in again.'),
              backgroundColor: Colors.orange.shade700,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Failed to send verification email: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to resend: ${e.toString()}'),
            backgroundColor: Colors.red.shade700,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      _isResending = false;
      if (mounted) setState(() {});
    }
  }

  void _goBackToLogin() async {
    if (_isNavigating) return;
    _isNavigating = true;
    _checkTimer?.cancel();
    
    print('📧 [EmailVerificationScreen] Going back to login screen');
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.signOut(context);
      print('✅ User signed out successfully');
    } catch (e) {
      print('❌ Error signing out: $e');
      await FirebaseAuth.instance.signOut();
    }
    
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  Widget _buildEmailHelpSection() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline, color: Colors.blue.shade700, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Tips to find your verification email:',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Colors.blue.shade700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildTipItem(
            icon: Icons.inbox,
            text: 'Check your spam/junk folder',
          ),
          _buildTipItem(
            icon: Icons.access_time,
            text: 'Wait 2-3 minutes - emails can be delayed',
          ),
          _buildTipItem(
            icon: Icons.refresh,
            text: 'Click "Resend Email" if you don\'t see it after 5 minutes',
          ),
        ],
      ),
    );
  }

  Widget _buildTipItem({required IconData icon, required String text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.blue.shade600),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade700),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 400;
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
                      child: Transform.scale(
                        scale: _scaleAnimation.value,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header Section
                            _buildHeaderSection(isSmallScreen, isVerySmallScreen),
                            SizedBox(height: isSmallScreen ? 25 : 30),
                            
                            // Verification Form
                            _buildVerificationForm(isSmallScreen, isVerySmallScreen),
                            SizedBox(height: isSmallScreen ? 20 : 30),
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

  Widget _buildHeaderSection(bool isSmallScreen, bool isVerySmallScreen) {
    final logoSize = isVerySmallScreen ? 80.0 : (isSmallScreen ? 90.0 : 110.0);
    
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
                  // Fallback with email icon instead of groups icon
                  return Center(
                    child: Icon(
                      Icons.mark_email_read_rounded,
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
          'Verify Your Email',
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
          'Please verify your email address to continue',
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

  Widget _buildVerificationForm(bool isSmallScreen, bool isVerySmallScreen) {
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Email Display
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(isVerySmallScreen ? 12 : 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_primaryGreen.withOpacity(0.1), _primaryRed.withOpacity(0.05)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _primaryGreen.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: isVerySmallScreen ? 40 : 48,
                  height: isVerySmallScreen ? 40 : 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_primaryGreen, _primaryRed],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.email_rounded,
                    color: Colors.white,
                    size: isVerySmallScreen ? 20 : 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Verification link sent to',
                        style: GoogleFonts.inter(
                          fontSize: isVerySmallScreen ? 10 : (isSmallScreen ? 12 : 13),
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.email,
                        style: GoogleFonts.inter(
                          fontSize: isVerySmallScreen ? 12 : (isSmallScreen ? 14 : 16),
                          fontWeight: FontWeight.w700,
                          color: _primaryGreen,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Instruction Text
          Container(
            padding: EdgeInsets.all(isVerySmallScreen ? 12 : (isSmallScreen ? 16 : 20)),
            decoration: BoxDecoration(
              color: _primaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
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
                  size: isVerySmallScreen ? 16 : (isSmallScreen ? 18 : 20),
                ),
                SizedBox(width: isVerySmallScreen ? 8 : (isSmallScreen ? 12 : 16)),
                Expanded(
                  child: Text(
                    'Click the verification link sent to your email to activate your account. Check your spam folder if you don\'t see it.',
                    style: GoogleFonts.inter(
                      fontSize: isVerySmallScreen ? 11 : (isSmallScreen ? 12 : 14),
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Continuous Checking Indicator
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isVerySmallScreen ? 12 : 20,
              vertical: isVerySmallScreen ? 12 : 16,
            ),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: isVerySmallScreen ? 18 : 24,
                  height: isVerySmallScreen ? 18 : 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: _primaryGreen,
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Waiting for verification...',
                        style: GoogleFonts.inter(
                          fontSize: isVerySmallScreen ? 11 : (isSmallScreen ? 13 : 14),
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (_checkCount > 0)
                        Text(
                          'Checking for verification (${_checkCount})...',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: Colors.grey.shade500,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Resend Button
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            width: double.infinity,
            height: isVerySmallScreen ? 48 : (isSmallScreen ? 56 : 64),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_primaryRed, _primaryGreen],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                stops: const [0.0, 1.0],
              ),
              borderRadius: BorderRadius.circular(isVerySmallScreen ? 14 : (isSmallScreen ? 16 : 20)),
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
              borderRadius: BorderRadius.circular(isVerySmallScreen ? 14 : (isSmallScreen ? 16 : 20)),
              child: InkWell(
                onTap: _isResending || _isNavigating ? null : _resendVerificationEmail,
                borderRadius: BorderRadius.circular(isVerySmallScreen ? 14 : (isSmallScreen ? 16 : 20)),
                splashColor: Colors.white.withOpacity(0.2),
                highlightColor: Colors.white.withOpacity(0.1),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: isVerySmallScreen ? 12 : 24),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _isResending
                        ? Center(
                            child: SizedBox(
                              width: isVerySmallScreen ? 20 : (isSmallScreen ? 24 : 28),
                              height: isVerySmallScreen ? 20 : (isSmallScreen ? 24 : 28),
                              child: const CircularProgressIndicator(
                                strokeWidth: 3,
                                valueColor: AlwaysStoppedAnimation(Colors.white),
                              ),
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.email_outlined,
                                color: Colors.white,
                                size: isVerySmallScreen ? 16 : (isSmallScreen ? 20 : 22),
                              ),
                              SizedBox(width: isVerySmallScreen ? 8 : (isSmallScreen ? 12 : 16)),
                              Flexible(
                                child: Text(
                                  'Resend Verification Email',
                                  style: GoogleFonts.poppins(
                                    fontSize: isVerySmallScreen ? 12 : (isSmallScreen ? 14 : 17),
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Back to Login Button
          TextButton(
            onPressed: _isNavigating ? null : _goBackToLogin,
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
                    fontSize: isVerySmallScreen ? 13 : (isSmallScreen ? 14 : 16),
                    fontWeight: FontWeight.w600,
                    color: _primaryGreen,
                  ),
                ),
              ],
            ),
          ),
          
          // Help Section
       /*   if (_showEmailHelp && !_isNavigating) ...[
            const SizedBox(height: 16),
            _buildEmailHelpSection(),
          ], */
        ],
      ),
    );
  }
}