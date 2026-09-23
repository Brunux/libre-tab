import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "IncomingFiles") {
      IncomingFiles.register(with: registrar)
    }
  }
}

/// Song files other apps open in Libre Tab ("Open in…" from Files, Safari,
/// Mail, chat apps). Info.plist declares the file types. Files are queued
/// and Dart collects them (lib/core/files/incoming_files.dart), so one that
/// arrives while Flutter is still starting isn't lost.
final class IncomingFiles: NSObject, FlutterPlugin, FlutterSceneLifeCycleDelegate {
  /// Bigger than any song; stops a wrong file from filling memory.
  private static let maxBytes = 5_000_000

  private let channel: FlutterMethodChannel
  private var pending: [[String: Any]] = []

  init(channel: FlutterMethodChannel) {
    self.channel = channel
  }

  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "libre_tab/incoming_files", binaryMessenger: registrar.messenger())
    let instance = IncomingFiles(channel: channel)
    registrar.addMethodCallDelegate(instance, channel: channel)
    registrar.addSceneDelegate(instance)
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard call.method == "takePending" else {
      result(FlutterMethodNotImplemented)
      return
    }
    result(pending)
    pending = []
  }

  // Launched by opening a file.
  func scene(
    _ scene: UIScene, willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions?
  ) -> Bool {
    return receive(connectionOptions?.urlContexts ?? [])
  }

  // A file opened while the app is running.
  func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) -> Bool {
    return receive(URLContexts)
  }

  private func receive(_ contexts: Set<UIOpenURLContext>) -> Bool {
    var received = false
    for url in contexts.map(\.url) where url.isFileURL {
      let scoped = url.startAccessingSecurityScopedResource()
      defer { if scoped { url.stopAccessingSecurityScopedResource() } }
      guard let data = try? Data(contentsOf: url), data.count <= Self.maxBytes else {
        continue
      }
      pending.append([
        "name": url.lastPathComponent,
        "bytes": FlutterStandardTypedData(bytes: data),
      ])
      received = true
      // iOS hands over a copy in Documents/Inbox; it's in the songbook now
      // (or discarded), so don't keep it around.
      if url.path.contains("/Inbox/") {
        try? FileManager.default.removeItem(at: url)
      }
    }
    if received { channel.invokeMethod("filesAvailable", arguments: nil) }
    return received
  }
}
