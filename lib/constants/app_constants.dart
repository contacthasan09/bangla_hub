class AppConstants {
  static const String appName = 'BanglaHub';
  static const String slogan = 'Connecting Bengalis Across North America';
  static const String tagline = 'One Platform. One Community. One Identity.';
  
  // Firebase Collections
  static const String usersCollection = 'users';
  static const String eventsCollection = 'events';
  static const String servicesCollection = 'community_services';
  static const String jobsCollection = 'job_postings';
  static const String businessesCollection = 'businesses';
  static const String businessPartnersCollection = 'business_partners';
  
  // Shared Preferences Keys
  static const String prefIsLoggedIn = 'isLoggedIn';
  static const String prefUserId = 'userId';
  static const String prefUserEmail = 'userEmail';
  static const String prefThemeMode = 'themeMode';
  
  // Categories
  static const List<String> serviceCategories = [
    'Accountants & Tax Preparers',
    'Legal Services',
    'Healthcare Needs',
    'Religious',
    'Restaurants & Grocery Stores',
    'Real Estate Agents',
    'Plumbers, Electricians, Mechanics',
  ];
  
  static const List<String> eventTypes = [
    'Cultural',
    'Religious',
    'Social',
    'Business',
    'Educational',
    'Sports',
  ];
  
  // Error Messages
  static const String errorGeneric = 'Something went wrong. Please try again.';
  static const String errorNoInternet = 'No internet connection.';
  static const String errorInvalidCredentials = 'Invalid email or password.';
  static const String errorEmailInUse = 'Email already in use.';
  static const String errorWeakPassword = 'Password is too weak.';
  
  // Success Messages
  static const String successAccountCreated = 'Account created successfully!';
  static const String successPasswordReset = 'Password reset email sent!';
  static const String successEventCreated = 'Event created successfully!';
  static const String successJobPosted = 'Job posted successfully!';
}