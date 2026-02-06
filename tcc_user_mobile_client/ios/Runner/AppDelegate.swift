import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    // Register for remote notifications
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // Handle deep link (URL scheme) - for Stripe 3DS redirects
  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey : Any] = [:]
  ) -> Bool {
    NSLog("[AppDelegate] URL callback received: scheme=%@, host=%@, url=%@",
          url.scheme ?? "nil", url.host ?? "nil", url.absoluteString)
    // Forward ALL URLs to super so Flutter plugins (including flutter_stripe)
    // receive the callback via StripeAPI.handleURLCallback(with:)
    let handled = super.application(app, open: url, options: options)
    NSLog("[AppDelegate] URL handled by Flutter plugins: %@", handled ? "true" : "false")
    return handled
  }

  // Handle notification presentation when app is in foreground
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    completionHandler([[.alert, .sound, .badge]])
  }
}
