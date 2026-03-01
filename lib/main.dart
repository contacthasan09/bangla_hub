import 'dart:async';

import 'package:bangla_hub/firebase_options.dart';
import 'package:bangla_hub/providers/auth_provider.dart';
import 'package:bangla_hub/providers/education_provider.dart';
import 'package:bangla_hub/providers/entrepreneurship_provider.dart';
import 'package:bangla_hub/providers/event_provider.dart';
import 'package:bangla_hub/providers/job_sites_browse_provider.dart';
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
        ChangeNotifierProvider(create: (_) => JobSitesBrowseProvider())



      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
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
      home: AuthWrapper(),
      routes: {
        '/splash': (context) => SplashScreen(),
        '/login': (context) => LoginScreen(),
        '/register': (context) => RegisterScreen(role: 'user'),
        '/home': (context) => HomeScreen(),
        '/admin': (context) => AdminHomeScreen(),
        '/welcome': (context) => WelcomeScreen(
              onComplete: () {
                Navigator.of(context).pushReplacementNamed('/home');
              },
            ),
                    '/events': (context) => EventsScreen(), // Add events route

      },
    );
  }
}

class AuthWrapper extends StatefulWidget {
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
    await Future.delayed(Duration(seconds: 4));

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
          return SplashScreen(
            onAnimationComplete: () {
              // Optional: Animation completed callback
            },
          );
        }

        // Handle errors
        if (snapshot.hasError) {
          return LoginScreen(); // Fallback to login on error
        }

        // Show appropriate screen based on auth state
        final authState = snapshot.data!;
        
        if (authState is ReadyAuthState) {
          if (authState.isLoggedIn) {
            return authState.isAdmin ? AdminHomeScreen() : HomeScreen();
          } else {
            return LoginScreen();
          }
        }

        // Fallback - should never reach here
        return SplashScreen();
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