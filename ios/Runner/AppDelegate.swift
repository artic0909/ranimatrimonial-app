import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private let securityChannelName = "com.rani.matrimonial/security"
  private var isSecurityEnabled = false
  private var blurView: UIVisualEffectView?
  private var secureTextField: UITextField?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller = window?.rootViewController as? FlutterViewController
    if let controller = controller {
      let channel = FlutterMethodChannel(name: securityChannelName, binaryMessenger: controller.binaryMessenger)
      channel.setMethodCallHandler { [weak self] (call, result) in
        guard let self = self else { return }
        switch call.method {
        case "enableSecureScreen":
          self.isSecurityEnabled = true
          self.applySecureTextField()
          result(true)
        case "disableSecureScreen":
          self.isSecurityEnabled = false
          self.removeSecureTextField()
          self.removePrivacyShield()
          result(true)
        default:
          result(FlutterMethodNotImplemented)
        }
      }
    }

    NotificationCenter.default.addObserver(
      self,
      selector: #selector(screenCaptureChanged),
      name: UIScreen.capturedDidChangeNotification,
      object: nil
    )

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }

  private func applySecureTextField() {
    guard secureTextField == nil, let window = self.window else { return }
    let field = UITextField()
    field.isSecureTextEntry = true
    field.isUserInteractionEnabled = false
    field.translatesAutoresizingMaskIntoConstraints = false
    window.addSubview(field)
    field.centerYAnchor.constraint(equalTo: window.centerYAnchor).isActive = true
    field.centerXAnchor.constraint(equalTo: window.centerXAnchor).isActive = true
    window.layer.superlayer?.addSublayer(field.layer)
    field.layer.sublayers?.first?.addSublayer(window.layer)
    self.secureTextField = field
  }

  private func removeSecureTextField() {
    if let field = secureTextField {
      field.removeFromSuperview()
      self.secureTextField = nil
    }
  }

  @objc private func screenCaptureChanged() {
    guard isSecurityEnabled else { return }
    if UIScreen.main.isCaptured {
      showPrivacyShield()
    } else {
      removePrivacyShield()
    }
  }

  override func applicationWillResignActive(_ application: UIApplication) {
    super.applicationWillResignActive(application)
    if isSecurityEnabled {
      showPrivacyShield()
    }
  }

  override func applicationDidBecomeActive(_ application: UIApplication) {
    super.applicationDidBecomeActive(application)
    removePrivacyShield()
  }

  private func showPrivacyShield() {
    guard blurView == nil, let window = self.window else { return }
    let blurEffect = UIBlurEffect(style: .dark)
    let blur = UIVisualEffectView(effect: blurEffect)
    blur.frame = window.bounds
    blur.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    window.addSubview(blur)
    self.blurView = blur
  }

  private func removePrivacyShield() {
    blurView?.removeFromSuperview()
    blurView = nil
  }
}
