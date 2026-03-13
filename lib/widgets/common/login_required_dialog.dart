import 'package:bangla_hub/providers/auth_provider.dart';
import 'package:bangla_hub/screens/auth/login_screen.dart';
import 'package:bangla_hub/screens/auth/signup_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class LoginRequiredDialog extends StatelessWidget {
  final String message;
  final String? featureName;

  const LoginRequiredDialog({
    Key? key,
    this.message = 'Please login to view details',
    this.featureName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Color _bangladeshGreen = Color(0xFF006A4E);
    final Color _bangladeshRed = Color(0xFFF42A41);
    final Color _goldAccent = Color(0xFFFFD700);
    
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.all(20),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Color(0xFFF8F8F8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 30,
              offset: Offset(0, 15),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with gradient
            Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_bangladeshRed, _bangladeshGreen],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.lock_rounded,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Login Required',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            
            Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                children: [
                  if (featureName != null) ...[
                    Text(
                      featureName!,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: _bangladeshGreen,
                      ),
                    ),
                    SizedBox(height: 8),
                  ],
                  Text(
                    message,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: Colors.grey[700],
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 24),
                  
                  // Login Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => LoginScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _bangladeshGreen,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 5,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.login_rounded),
                          SizedBox(width: 10),
                          Text(
                            'Login',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 12),
                  
                  // Sign Up Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RegisterScreen(role: 'user'),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _bangladeshGreen,
                        side: BorderSide(color: _bangladeshGreen, width: 2),
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.person_add_alt_1_rounded),
                          SizedBox(width: 10),
                          Text(
                            'Create Account',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 12),
                  
                  // Continue as Guest (if coming from guest mode)
                  Consumer<AuthProvider>(
                    builder: (context, authProvider, child) {
                      if (!authProvider.isGuestMode) return SizedBox.shrink();
                      
                      return TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Continue Browsing',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}