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
import 'package:bangla_hub/screens/user_app/event/events_screen.dart';
import 'package:bangla_hub/screens/user_app/home_screen.dart';
import 'package:bangla_hub/screens/user_app/welcome_screen.dart';
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

      home: const AuthWrapper(),
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => RegisterScreen(role: 'user'),
        '/home': (context) => const HomeScreen(),
        '/admin': (context) => const AdminHomeScreen(),
        '/welcome': (context) => WelcomeScreen(
              onComplete: () {
                Navigator.of(context).pushReplacementNamed('/home');
              },
            ),
        '/events': (context) => const EventsScreen(),
      },
    );
  }
}

/* class AuthWrapper extends StatefulWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  _AuthWrapperState createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  late Stream<AuthState> _authStream;

  @override
  void initState() {
    super.initState();
    _authStream = _initializeApp();
  }

  Stream<AuthState> _initializeApp() async* {
    // Always start with splash for 4 seconds
    yield ShowingSplashAuthState();

    // Start auth check in background
    final authProvider = Provider.of<AuthProvider>(
      context,
      listen: false,
    );

    try {
      // Run auth check
      await authProvider.checkCurrentAuthStatus();
    } catch (e) {
      print('Auth check error: $e');
      // Continue even if auth check fails
    }

    // Wait for minimum 4 seconds total (splash time)
    await Future.delayed(const Duration(seconds: 4));

    // After waiting, decide what to show next
    if (authProvider.isLoggedIn && authProvider.user != null) {
      yield ReadyAuthState(
        isLoggedIn: true,
        isAdmin: authProvider.user!.isAdmin,
      );
    } else {
      yield ReadyAuthState(isLoggedIn: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: _authStream,
      builder: (context, snapshot) {
        // Always show splash until we have ReadyAuthState
        if (snapshot.connectionState == ConnectionState.waiting ||
            !snapshot.hasData ||
            snapshot.data is ShowingSplashAuthState) {
          return const SplashScreen();
        }

        // Handle errors
        if (snapshot.hasError) {
          return const LoginScreen(); // Fallback to login on error
        }

        // Show appropriate screen based on auth state
        final authState = snapshot.data!;
        
        if (authState is ReadyAuthState) {
          if (authState.isLoggedIn) {
            return authState.isAdmin ? const AdminHomeScreen() : const HomeScreen();
          } else {
            return const LoginScreen();
          }
        }

        // Fallback - should never reach here
        return const SplashScreen();
      },
    );
  }
}  */

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  _AuthWrapperState createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    
    // Show splash for 4 seconds minimum
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() {
          _showSplash = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Show splash screen for first 4 seconds
    if (_showSplash) {
      return const SplashScreen();
    }

    // After splash, use Consumer to react to auth changes in REAL TIME
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // Show loading while checking auth
        if (authProvider.isLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Show appropriate screen based on auth state
        if (authProvider.isLoggedIn && authProvider.user != null) {
          return authProvider.user!.isAdmin 
              ? const AdminHomeScreen() 
              : const HomeScreen();
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}



// Auth State classes for better type safety
abstract class AuthState {}

class ShowingSplashAuthState extends AuthState {}

class ReadyAuthState extends AuthState {
  final bool isLoggedIn;
  final bool isAdmin;

  ReadyAuthState({
    required this.isLoggedIn,
    this.isAdmin = false,
  });
}

// Splash Screen Widget
/*class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF006A4E), Color(0xFF004D38)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.language,
                      color: Colors.white,
                      size: 60,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'BanglaHub',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Connecting Bengalis Worldwide',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}  */