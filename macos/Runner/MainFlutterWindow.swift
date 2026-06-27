import Cocoa
import CoreText
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  private var securityScopedDatabaseUrls: [URL] = []

  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)
    let channel = FlutterMethodChannel(
      name: "tibetan_typesetting/system_fonts",
      binaryMessenger: flutterViewController.engine.binaryMessenger)
    channel.setMethodCallHandler { call, result in
      if call.method == "listFonts" {
        result(Self.listSystemFonts())
      } else if call.method == "getScreenDpi" {
        result(Self.getScreenDpi())
      } else {
        result(FlutterMethodNotImplemented)
      }
    }
    let bookmarkChannel = FlutterMethodChannel(
      name: "tibetan_typesetting/database_bookmarks",
      binaryMessenger: flutterViewController.engine.binaryMessenger)
    bookmarkChannel.setMethodCallHandler { [weak self] call, result in
      guard let self else {
        result(FlutterError(code: "window_unavailable", message: nil, details: nil))
        return
      }
      switch call.method {
      case "create":
        self.createDatabaseBookmark(call: call, result: result)
      case "resolveAndStartAccess":
        self.resolveDatabaseBookmark(call: call, result: result)
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    super.awakeFromNib()
  }

  private static func listSystemFonts() -> [[String: String]] {
    let supportedExtensions = Set(["ttf", "otf", "ttc"])
    let postScriptNames = CTFontManagerCopyAvailablePostScriptNames() as? [String] ?? []
    var seen = Set<String>()
    var fonts: [[String: String]] = []

    for postScriptName in postScriptNames {
      let font = CTFontCreateWithName(postScriptName as CFString, 12, nil)
      let descriptor = CTFontCopyFontDescriptor(font)
      guard let url = CTFontDescriptorCopyAttribute(
        descriptor,
        kCTFontURLAttribute
      ) as? URL else {
        continue
      }

      let path = url.path
      let fileType = url.pathExtension.lowercased()
      guard supportedExtensions.contains(fileType), !seen.contains(path) else {
        continue
      }

      let familyName = CTFontCopyFamilyName(font) as String
      guard !familyName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
        continue
      }

      seen.insert(path)
      fonts.append([
        "familyName": familyName,
        "filePath": path,
        "fileType": fileType,
      ])
    }

    return fonts
  }

  private static func getScreenDpi() -> Double {
    guard let screen = NSScreen.main else { return 96.0 }
    let screenFrame = screen.frame
    let displayID = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID ?? 0
    if displayID == 0 { return 96.0 }
    let screenSizeMM = CGDisplayScreenSize(displayID)
    if screenSizeMM.width <= 0 { return 96.0 }
    let dpi = screenFrame.size.width * 25.4 / screenSizeMM.width
    return Double(dpi)
  }

  private func createDatabaseBookmark(call: FlutterMethodCall, result: FlutterResult) {
    guard
      let arguments = call.arguments as? [String: Any],
      let path = arguments["path"] as? String
    else {
      result(FlutterError(code: "invalid_arguments", message: nil, details: nil))
      return
    }
    do {
      let data = try URL(fileURLWithPath: path).bookmarkData(
        options: .withSecurityScope,
        includingResourceValuesForKeys: nil,
        relativeTo: nil)
      result(data.base64EncodedString())
    } catch {
      result(FlutterError(
        code: "bookmark_creation_failed",
        message: error.localizedDescription,
        details: nil))
    }
  }

  private func resolveDatabaseBookmark(call: FlutterMethodCall, result: FlutterResult) {
    guard
      let arguments = call.arguments as? [String: Any],
      let encoded = arguments["bookmark"] as? String,
      let data = Data(base64Encoded: encoded)
    else {
      result(FlutterError(code: "invalid_arguments", message: nil, details: nil))
      return
    }
    do {
      var isStale = false
      let url = try URL(
        resolvingBookmarkData: data,
        options: .withSecurityScope,
        relativeTo: nil,
        bookmarkDataIsStale: &isStale)
      guard url.startAccessingSecurityScopedResource() else {
        result(FlutterError(code: "bookmark_access_denied", message: nil, details: nil))
        return
      }
      securityScopedDatabaseUrls.append(url)
      let refreshed = isStale
        ? try url.bookmarkData(
            options: .withSecurityScope,
            includingResourceValuesForKeys: nil,
            relativeTo: nil).base64EncodedString()
        : encoded
      result(["path": url.path, "bookmark": refreshed])
    } catch {
      result(FlutterError(
        code: "bookmark_resolution_failed",
        message: error.localizedDescription,
        details: nil))
    }
  }
}
