import Flutter
import UIKit
import GoogleMaps 

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
      
    // 💡 1. GMSServices (s 붙임)
    // 💡 2. 여기에 발급받으신 '진짜 구글맵 iOS API 키'를 직접 적어주세요.
    GMSServices.provideAPIKey("AIzaSyCNYSv9LXcgTJSXJqBTqvmhzE1I5oxoVHM")
      
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}