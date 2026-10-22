import AVFoundation
import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private let synthesizer = AVSpeechSynthesizer()

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // flutter_local_notifications: hiện thông báo nhắc học cả khi app đang mở
    UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    // Phát âm nội dung thẻ bằng giọng đọc có sẵn của iOS (không cần thư viện ngoài)
    guard let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "SpeechChannel") else { return }
    let channel = FlutterMethodChannel(name: "flashcard_app/speech", binaryMessenger: registrar.messenger())
    channel.setMethodCallHandler { [weak self] call, result in
      guard call.method == "speak",
            let args = call.arguments as? [String: Any],
            let text = args["text"] as? String,
            let self = self else {
        result(FlutterMethodNotImplemented)
        return
      }
      let utterance = AVSpeechUtterance(string: text)
      utterance.voice = AVSpeechSynthesisVoice(language: args["language"] as? String ?? "en-US")
      self.synthesizer.stopSpeaking(at: .immediate)
      self.synthesizer.speak(utterance)
      result(true)
    }
  }
}
