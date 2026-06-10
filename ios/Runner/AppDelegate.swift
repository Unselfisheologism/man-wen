import UIKit
import Flutter

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    
    private var siteBlockerEnabled = false
    
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        
        let controller = window?.rootViewController as! FlutterViewController
        
        // Setup method channel for site blocker
        let channel = FlutterMethodChannel(
            name: "com.manwen.app/manwen",
            binaryMessenger: controller.binaryMessenger
        )
        
        channel.setMethodCallHandler { [weak self] (call, result) in
            switch call.method {
            case "startSiteBlocking":
                self?.startSiteBlocking()
                result(true)
            case "stopSiteBlocking":
                self?.stopSiteBlocking()
                result(true)
            case "startMonitoring":
                // Legacy - treat as site blocking
                self?.startSiteBlocking()
                result(true)
            case "stopMonitoring":
                // Legacy - treat as stop site blocking
                self?.stopSiteBlocking()
                result(true)
            default:
                result(FlutterMethodNotImplemented)
            }
        }
        
        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    private func startSiteBlocking() {
        siteBlockerEnabled = true
        
        // Enable Content Blocker extension
        SiteBlocker.shared.reloadContentBlocker { error in
            if let error = error {
                print("[SiteBlocker] Failed to enable: \(error)")
            } else {
                print("[SiteBlocker] Enabled successfully")
            }
        }
        
        // Save state
        UserDefaults.standard.set(true, forKey: "site_blocker_enabled")
    }
    
    private func stopSiteBlocking() {
        siteBlockerEnabled = false
        
        // Save state
        UserDefaults.standard.set(false, forKey: "site_blocker_enabled")
        
        // Note: Content Blocker cannot be dynamically disabled on iOS
        // The user would need to go to Settings > Safari > Content Blockers
        // to manually disable it, or use a different approach
    }
}