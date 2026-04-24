import UIKit
import Flutter
import GoogleMaps  // ✅ Add this import

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // ✅ ONLY place where API key goes (BEST PRACTICE)
    GMSServices.provideAPIKey("AIzaSyDw-QLRFJrFCKUxNapNwjp2UhK_xk7aEiU")
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}