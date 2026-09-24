import Flutter
import UIKit
import Vision

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
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "TextRecognition") {
      TextRecognition.register(with: registrar)
    }
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "AppSettings") {
      // Libre Tab's page in Settings, to allow a refused permission again.
      FlutterMethodChannel(name: "libre_tab/app_settings", binaryMessenger: registrar.messenger())
        .setMethodCallHandler { call, result in
          guard call.method == "open", let url = URL(string: UIApplication.openSettingsURLString)
          else {
            result(FlutterMethodNotImplemented)
            return
          }
          UIApplication.shared.open(url) { opened in result(opened) }
        }
    }
  }
}

/// Reads the words in a photo with Apple Vision, on the device, for camera
/// import (lib/core/ocr/text_recognizer.dart). Each word comes back with its
/// box in pixels of the upright image; lib/core/ocr/ocr_layout.dart lines
/// chords up with the lyrics from those boxes.
final class TextRecognition: NSObject, FlutterPlugin {
  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "libre_tab/text_recognition", binaryMessenger: registrar.messenger())
    registrar.addMethodCallDelegate(TextRecognition(), channel: channel)
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard call.method == "recognize",
      let path = (call.arguments as? [String: Any])?["path"] as? String
    else {
      result(FlutterMethodNotImplemented)
      return
    }
    DispatchQueue.global(qos: .userInitiated).async {
      do {
        let words = try Self.recognize(path: path)
        DispatchQueue.main.async { result(words) }
      } catch {
        DispatchQueue.main.async {
          result(
            FlutterError(
              code: "unreadable", message: error.localizedDescription, details: nil))
        }
      }
    }
  }

  private struct Unreadable: Error {}

  static func recognize(path: String) throws -> [[String: Any]] {
    guard let image = uprightImage(path: path) else { throw Unreadable() }
    return try PageReader.read(image).map { word in
      [
        "text": word.text,
        "left": Double(word.rect.minX),
        "top": Double(word.rect.minY),
        "right": Double(word.rect.maxX),
        "bottom": Double(word.rect.maxY),
      ]
    }
  }

  /// The photo turned upright: photos can be stored sideways with an
  /// orientation tag, and lines must run left to right.
  private static func uprightImage(path: String) -> CGImage? {
    let url = URL(fileURLWithPath: path)
    guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
      let image = CGImageSourceCreateImageAtIndex(source, 0, nil)
    else { return nil }
    let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any]
    let tag = (properties?[kCGImagePropertyOrientation] as? UInt32) ?? 1
    let orientations: [UInt32: UIImage.Orientation] = [
      2: .upMirrored, 3: .down, 4: .downMirrored, 5: .leftMirrored, 6: .right,
      7: .rightMirrored, 8: .left,
    ]
    guard let orientation = orientations[tag] else { return image }
    let turned = UIImage(cgImage: image, scale: 1, orientation: orientation)
    let format = UIGraphicsImageRendererFormat()
    format.scale = 1
    return UIGraphicsImageRenderer(size: turned.size, format: format)
      .image { _ in turned.draw(at: .zero) }.cgImage
  }
}

// MARK: - Page reader (Vision and CoreGraphics only, no UIKit)

/// Reads the words on an upright page with Apple Vision. Vision sometimes
/// skips a lone letter ("C" over a word), which on a song sheet is a whole
/// chord, so a second pass looks for marks left unread in the chord rows,
/// crops each one out, enlarges it and reads it on its own, keeping what
/// reads as a chord.
enum PageReader {
  struct Word {
    var text: String
    /// Pixels, origin at the top left.
    var rect: CGRect
  }

  static func read(_ image: CGImage) throws -> [Word] {
    let words = try recognize(image, level: .accurate)
    return words + missedChords(in: image, words: words)
  }

  static func recognize(
    _ image: CGImage, level: VNRequestTextRecognitionLevel
  ) throws -> [Word] {
    let request = VNRecognizeTextRequest()
    request.recognitionLevel = level
    // Language correction "fixes" chords (Em7, Bb, F#m) into words.
    request.usesLanguageCorrection = false
    request.recognitionLanguages = ["en-US", "es-ES"]
    try VNImageRequestHandler(cgImage: image, orientation: .up).perform([request])

    let width = CGFloat(image.width)
    let height = CGFloat(image.height)
    var words: [Word] = []
    for observation in request.results ?? [] {
      guard let candidate = observation.topCandidates(1).first else { continue }
      let text = candidate.string
      // Words are runs of non-spaces: chords keep their # and /.
      var index = text.startIndex
      while index < text.endIndex {
        guard let start = text[index...].firstIndex(where: { !$0.isWhitespace }) else { break }
        let end = text[start...].firstIndex(where: { $0.isWhitespace }) ?? text.endIndex
        index = end
        guard let box = try? candidate.boundingBox(for: start..<end)?.boundingBox
        else { continue }
        // Vision boxes are 0–1 with the origin at the bottom left.
        words.append(
          Word(
            text: String(text[start..<end]),
            rect: CGRect(
              x: box.minX * width, y: (1 - box.maxY) * height,
              width: box.width * width, height: box.height * height)))
      }
    }
    return words
  }

  private static let chord = try! NSRegularExpression(
    pattern: "^[A-G](#|b)?(m|maj|min|dim|aug|sus|add)?[0-9]*(/[A-G](#|b)?)?$")

  static func isChord(_ text: String) -> Bool {
    chord.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) != nil
  }

  /// Chords Vision didn't read: marks in chord rows (rows of chords it did
  /// read, and the space just above each lyric line) that no word covers.
  static func missedChords(in image: CGImage, words: [Word]) -> [Word] {
    guard let page = GrayPage(image) else { return [] }
    let lines = self.lines(words)
    let chordLine = { (line: [Word]) in line.allSatisfy { isChord($0.text) } }
    let lyricHeights = lines.filter { !chordLine($0) }.map { $0.map(\.rect.height).max()! }
    guard !lyricHeights.isEmpty else { return [] }
    let lyricHeight = lyricHeights.sorted()[lyricHeights.count / 2]

    var bands: [(top: CGFloat, bottom: CGFloat)] = []
    for (i, line) in lines.enumerated() {
      let top = line.map(\.rect.minY).min()!
      let bottom = line.map(\.rect.maxY).max()!
      if chordLine(line) {
        bands.append((top - 2, bottom + 2))
      } else if i == 0 || !chordLine(lines[i - 1]) {
        // No chords read above this lyric line: look there too.
        let above = i > 0 ? lines[i - 1].map(\.rect.maxY).max()! : 0
        let gap = top - above
        if gap >= lyricHeight * 0.8 {
          bands.append((max(above, top - lyricHeight * 1.4), top - lyricHeight * 0.1))
        }
      }
    }

    var unread: [CGRect] = []
    for band in bands where band.bottom - band.top > 4 {
      let covered = words.filter { $0.rect.midY > band.top && $0.rect.midY < band.bottom }
      unread += page.marks(top: band.top, bottom: band.bottom).filter { mark in
        !covered.contains { $0.rect.intersects(mark.insetBy(dx: 1, dy: 0)) }
      }
    }
    // Each read takes a moment; do them side by side.
    var read = [String?](repeating: nil, count: unread.count)
    let lock = NSLock()
    DispatchQueue.concurrentPerform(iterations: unread.count) { i in
      let text = readAlone(image, page: page, rect: unread[i])
      lock.lock()
      read[i] = text
      lock.unlock()
    }
    return zip(unread, read).compactMap { mark, text in
      text.map { Word(text: $0, rect: mark) }
    }
  }

  /// A mark cropped out, enlarged and read on its own: first drawn three
  /// times in a row ("C C C"), since alone a letter like "C" looks like a
  /// bracket, keeping a chord at least two copies agree on; then once.
  private static func readAlone(_ image: CGImage, page: GrayPage, rect: CGRect) -> String? {
    for copies in [3, 1] {
      if let chord = readCopies(image, page: page, rect: rect, copies: copies) {
        return chord
      }
    }
    return nil
  }

  private static func readCopies(
    _ image: CGImage, page: GrayPage, rect: CGRect, copies: Int
  ) -> String? {
    let pad = rect.height * 0.3
    let area = rect.insetBy(dx: -pad, dy: -pad)
      .intersection(CGRect(x: 0, y: 0, width: image.width, height: image.height))
    guard let crop = image.cropping(to: area) else { return nil }
    let factor = max(1, 80 / rect.height)
    let copyWidth = Double(crop.width) * factor
    let copyHeight = Double(crop.height) * factor
    let gap = copyHeight * 0.6
    let margin = 40.0
    let width = Int(copyWidth * Double(copies) + gap * Double(copies - 1) + margin * 2)
    let height = Int(copyHeight + margin * 2)
    guard
      let context = CGContext(
        data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
        space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
    else { return nil }
    let background = CGFloat(page.background) / 255
    context.setFillColor(CGColor(red: background, green: background, blue: background, alpha: 1))
    context.fill(CGRect(x: 0, y: 0, width: width, height: height))
    context.interpolationQuality = .high
    for copy in 0..<copies {
      let x = margin + Double(copy) * (copyWidth + gap)
      context.draw(crop, in: CGRect(x: x, y: margin, width: copyWidth, height: copyHeight))
    }
    guard let tripled = context.makeImage() else { return nil }
    for level in [VNRequestTextRecognitionLevel.accurate, .fast] {
      let tokens = ((try? recognize(tripled, level: level)) ?? []).map { word in
        // A lone chord letter sometimes comes back in lower case.
        word.text.count == 1 ? word.text.uppercased() : word.text
      }
      let votes = Dictionary(grouping: tokens.filter(isChord), by: { $0 })
      if let (chord, agreeing) = votes.max(by: { $0.value.count < $1.value.count }),
        agreeing.count >= (copies + 1) / 2
      {
        return chord
      }
    }
    return nil
  }

  /// Words grouped into lines by vertical overlap, top to bottom.
  static func lines(_ words: [Word]) -> [[Word]] {
    var lines: [[Word]] = []
    for word in words.sorted(by: { $0.rect.midY < $1.rect.midY }) {
      if let i = lines.firstIndex(where: { line in
        line.contains { other in
          let shared = min(other.rect.maxY, word.rect.maxY) - max(other.rect.minY, word.rect.minY)
          return shared > 0.5 * min(other.rect.height, word.rect.height)
        }
      }) {
        lines[i].append(word)
      } else {
        lines.append([word])
      }
    }
    return lines.sorted { $0[0].rect.midY < $1[0].rect.midY }
  }
}

/// The page in shades of gray, to find marks (runs of ink) in a row.
struct GrayPage {
  let width: Int
  let height: Int
  private let pixels: [UInt8]
  /// The page's usual shade: paper on a photo, the background of a screenshot.
  let background: UInt8

  init?(_ image: CGImage) {
    let w = image.width
    let h = image.height
    width = w
    height = h
    var pixels = [UInt8](repeating: 255, count: w * h)
    let drawn = pixels.withUnsafeMutableBytes { buffer -> Bool in
      guard
        let context = CGContext(
          data: buffer.baseAddress, width: w, height: h, bitsPerComponent: 8,
          bytesPerRow: w, space: CGColorSpaceCreateDeviceGray(),
          bitmapInfo: CGImageAlphaInfo.none.rawValue)
      else { return false }
      context.draw(image, in: CGRect(x: 0, y: 0, width: w, height: h))
      return true
    }
    guard drawn else { return nil }
    self.pixels = pixels
    let sample = stride(from: 0, to: pixels.count, by: 97).map { pixels[$0] }.sorted()
    background = sample[sample.count / 2]
  }

  private func isInk(_ x: Int, _ y: Int) -> Bool {
    abs(Int(pixels[y * width + x]) - Int(background)) > 70
  }

  /// Boxes around runs of ink between [top] and [bottom]. Letters of one
  /// chord sit close together; chords are further apart.
  func marks(top: CGFloat, bottom: CGFloat) -> [CGRect] {
    let y0 = max(0, Int(top))
    let y1 = min(height - 1, Int(bottom))
    guard y1 > y0 else { return [] }
    let maxGap = max(3, (y1 - y0) / 2)
    var marks: [CGRect] = []
    var start: Int?
    var last = -1
    func close() {
      guard let s = start else { return }
      var minY = y1
      var maxY = y0
      for x in s...last {
        for y in y0...y1 where isInk(x, y) {
          minY = min(minY, y)
          maxY = max(maxY, y)
        }
      }
      // Ignore specks and underline-like smudges.
      if maxY - minY >= (y1 - y0) / 4 && last - s >= 2 {
        marks.append(CGRect(x: s, y: minY, width: last - s + 1, height: maxY - minY + 1))
      }
      start = nil
    }
    for x in 0..<width {
      var ink = false
      for y in y0...y1 where isInk(x, y) {
        ink = true
        break
      }
      if ink {
        if start != nil, x - last > maxGap { close() }
        if start == nil { start = x }
        last = x
      }
    }
    close()
    return marks
  }
}

// MARK: - End of page reader

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
      // Check the size before reading, so a huge file is never loaded.
      let size = (try? url.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? Int.max
      guard size <= Self.maxBytes, let data = try? Data(contentsOf: url),
        data.count <= Self.maxBytes
      else { continue }
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
