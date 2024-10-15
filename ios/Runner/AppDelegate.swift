import Flutter
import UIKit
import GoogleMaps
// import NaverMaps

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GMSServices.provideAPIKey("AIzaSyB9AJNblm0diEm0aJvp4Pt8ysLm-4GPDTk")
    // NaverMapServices.provideAPIKey("dl87qvo0wp")
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
