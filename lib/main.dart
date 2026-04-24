// main.dart

import 'dart:async';

import 'package:bangla_hub/firebase_options.dart';
import 'package:bangla_hub/providers/auth_provider.dart';
import 'package:bangla_hub/providers/education_provider.dart';
import 'package:bangla_hub/providers/entrepreneurship_provider.dart';
import 'package:bangla_hub/providers/event_provider.dart';
import 'package:bangla_hub/providers/job_sites_browse_provider.dart';
import 'package:bangla_hub/providers/location_filter_provider.dart';
import 'package:bangla_hub/providers/service_provider_provider.dart';
import 'package:bangla_hub/screens/admin_app/screens/home/admin_homescreen.dart';
import 'package:bangla_hub/screens/auth/landing_screen.dart';
import 'package:bangla_hub/screens/auth/login_screen.dart';
import 'package:bangla_hub/screens/auth/signup_screen.dart';
import 'package:bangla_hub/screens/user_app/home_screen.dart';
import 'package:bangla_hub/screens/user_app/welcome_screen.dart';
import 'package:bangla_hub/widgets/common/email_verification_dialog.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('🔥 Firebase initialized successfully');
  } catch (e) {
    debugPrint('❌ Firebase initialization failed: $e');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => EventProvider()),
        ChangeNotifierProvider(create: (_) => ServiceProviderProvider()),
        ChangeNotifierProvider(create: (_) => EntrepreneurshipProvider()),
        ChangeNotifierProvider(create: (_) => EducationProvider()),
        ChangeNotifierProvider(create: (_) => JobSitesBrowseProvider()),
        ChangeNotifierProvider(create: (_) => LocationFilterProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BanglaHub',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        useMaterial3: true,
      ),
      navigatorKey: navigatorKey,
      home: const SplashScreen(),
   
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => RegisterScreen(role: 'user'),
        '/home': (context) => const HomeScreen(),
        '/welcome': (context) => WelcomeScreen(
              onComplete: () {
                navigatorKey.currentState?.pushReplacementNamed('/home');
              },
            ),
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToAuthWrapper();
  }

  void _navigateToAuthWrapper() {
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AuthWrapper()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text('Loading...'),
          ],
        ),
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        print('🔐 AuthWrapper - isLoading: ${authProvider.isLoading}, isLoggedIn: ${authProvider.isLoggedIn}, user: ${authProvider.user?.email}, isEmailVerified: ${authProvider.user?.isEmailVerified}, isAdmin: ${authProvider.user?.isAdmin}');
        
        if (authProvider.isLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final isLoggedIn = authProvider.isLoggedIn && authProvider.user != null;
        final isEmailVerified = authProvider.user?.isEmailVerified ?? false;
        final isAdmin = authProvider.user?.isAdmin ?? false;
        
        // Admin always goes to admin screen
        if (isAdmin && isLoggedIn) {
          return const AdminHomeScreen();
        }
        
        // Regular user with verified email goes to home
        if (isLoggedIn && isEmailVerified) {
          return const HomeScreen();
        }
        
        // Regular user logged in but email not verified - show verification screen
        if (isLoggedIn && !isEmailVerified && !isAdmin) {
          return EmailVerificationScreen(
            email: authProvider.user!.email,
            onVerified: () async {
              await authProvider.syncEmailVerificationStatus();
              if (mounted) {
                // Force rebuild to check verification status
                setState(() {});
              }
            },
          );
        }
        
        // Not logged in - show login screen
        return const LoginScreen();
      },
    );
  }
}