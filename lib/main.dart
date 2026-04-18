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
        '/login': (context) => const LoginScreen(),
        '/register': (context) => RegisterScreen(role: 'user'),
        '/welcome': (context) => WelcomeScreen(
              onComplete: () {
                navigatorKey.currentState?.pushReplacementNamed('/home');
              },
            ),
      },
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  _AuthWrapperState createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _showSplash = true;
  
  // Store the screen instances at the class level
  late Widget _homeScreen;
  late Widget _adminScreen;
  bool _screensInitialized = false;

  @override
  void initState() {
    super.initState();
    
    // Initialize screens once
    _homeScreen = const HomeScreen();
    _adminScreen = const AdminHomeScreen();
    _screensInitialized = true;
    
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
    if (_showSplash) {
      return const SplashScreen();
    }

    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (authProvider.isLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (authProvider.isLoggedIn && authProvider.user != null) {
          if (authProvider.user!.isAdmin) {
            return _adminScreen;
          } else {
            // Return the SAME HomeScreen instance every time
            return _homeScreen;
          }
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}

