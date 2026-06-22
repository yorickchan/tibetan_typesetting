import Cocoa
import CoreText
import FlutterMacOS

class MainFlutterWindow: NSWindow {
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
}
