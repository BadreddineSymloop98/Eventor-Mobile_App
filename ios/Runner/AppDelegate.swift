import Flutter
import QuickLook
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private let downloads = Downloads()

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "EventorDownloads") {
      downloads.register(with: registrar.messenger())
    }
  }
}

/// `eventor/downloads` — see lib/core/services/device_files.dart.
///
/// iOS has no Downloads folder: a PDF goes into the app's Documents, which
/// `UIFileSharingEnabled` + `LSSupportsOpeningDocumentsInPlace` (Info.plist)
/// show in Files › On My iPhone › Eventor. Open previews it with Quick Look.
private final class Downloads: NSObject, QLPreviewControllerDataSource {
  private var previewing: URL?

  func register(with messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: "eventor/downloads", binaryMessenger: messenger)
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self = self else { return }
      switch call.method {
      case "savePdf": self.savePdf(call.arguments, result)
      case "open": self.open(call.arguments, result)
      default: result(FlutterMethodNotImplemented)
      }
    }
  }

  private func savePdf(_ arguments: Any?, _ result: @escaping FlutterResult) {
    guard let args = arguments as? [String: Any],
          let data = (args["bytes"] as? FlutterStandardTypedData)?.data,
          let name = args["name"] as? String else {
      result(FlutterError(code: "failed", message: "Bad arguments", details: nil))
      return
    }
    do {
      let folder = try FileManager.default.url(
        for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
      // Numbered on a clash, as Android does: "INV-1 (1).pdf".
      let base = (name as NSString).deletingPathExtension
      var url = folder.appendingPathComponent(name)
      var n = 1
      while FileManager.default.fileExists(atPath: url.path) {
        url = folder.appendingPathComponent("\(base) (\(n)).pdf")
        n += 1
      }
      try data.write(to: url, options: .atomic)
      result(["uri": url.absoluteString, "name": url.lastPathComponent])
    } catch {
      result(FlutterError(code: "failed", message: error.localizedDescription, details: nil))
    }
  }

  private func open(_ arguments: Any?, _ result: @escaping FlutterResult) {
    guard let args = arguments as? [String: Any],
          let uri = args["uri"] as? String,
          let url = URL(string: uri),
          let top = Downloads.topViewController() else {
      result(false)
      return
    }
    previewing = url
    let preview = QLPreviewController()
    preview.dataSource = self
    top.present(preview, animated: true)
    result(true)
  }

  func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
    previewing == nil ? 0 : 1
  }

  func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
    previewing! as NSURL
  }

  private static func topViewController() -> UIViewController? {
    let window = UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .flatMap { $0.windows }
      .first { $0.isKeyWindow }
    var top = window?.rootViewController
    while let presented = top?.presentedViewController { top = presented }
    return top
  }
}
