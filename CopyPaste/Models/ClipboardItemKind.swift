import AppKit
import SwiftUI

extension Color {
  static func dynamic(light: NSColor, dark: NSColor) -> Color {
    Color(nsColor: NSColor(name: nil) { appearance in
      appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua ? dark : light
    })
  }
}

enum ClipboardItemKind: String, CaseIterable, Identifiable {
  case text
  case link
  case image
  case file
  case color

  var id: Self { self }

  var title: LocalizedStringKey {
    switch self {
    case .text: "kind_text"
    case .link: "kind_link"
    case .image: "kind_image"
    case .file: "kind_file"
    case .color: "kind_color"
    }
  }

  var symbol: String {
    switch self {
    case .text: "text.alignleft"
    case .link: "link"
    case .image: "photo"
    case .file: "doc"
    case .color: "paintpalette"
    }
  }

  var accentColor: Color {
    switch self {
    case .text:
      Color.dynamic(
        light: NSColor(red: 0.12, green: 0.12, blue: 0.14, alpha: 1),
        dark: NSColor(red: 0.27, green: 0.27, blue: 0.30, alpha: 1)
      )
    case .link: Color(red: 0.18, green: 0.49, blue: 0.96)
    case .image: Color(red: 0.31, green: 0.39, blue: 0.88)
    case .file: Color(red: 0.91, green: 0.53, blue: 0.23)
    case .color: Color(red: 0.56, green: 0.36, blue: 0.85)
    }
  }
}

enum HistoryFilter: String, CaseIterable, Identifiable {
  case all
  case text
  case link
  case image
  case file

  var id: Self { self }

  var kind: ClipboardItemKind? {
    self == .all ? nil : ClipboardItemKind(rawValue: rawValue)
  }

  var title: LocalizedStringKey {
    kind?.title ?? "filter_all"
  }

  var symbol: String {
    kind?.symbol ?? "square.grid.2x2"
  }

  var next: HistoryFilter {
    let all = Self.allCases
    let index = all.firstIndex(of: self) ?? 0
    return all[(index + 1) % all.count]
  }

  func matches(_ kind: ClipboardItemKind) -> Bool {
    guard let expected = self.kind else { return true }
    // Colors are rare enough to not deserve their own filter, they belong to text.
    return expected == kind || (expected == .text && kind == .color)
  }
}
