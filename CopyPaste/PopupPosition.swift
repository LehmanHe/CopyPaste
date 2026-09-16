import AppKit.NSEvent
import Defaults
import Foundation

enum PopupPosition: String, CaseIterable, Identifiable, CustomStringConvertible, Defaults.Serializable {
  case bottom

  var id: Self { self }

  var description: String {
    return NSLocalizedString("PopupAtScreenBottom", tableName: "AppearanceSettings", comment: "")
  }

  static let panelHeight: CGFloat = 284
  static let horizontalMargin: CGFloat = 12

  func origin(size: NSSize, statusBarButton: NSStatusBarButton?) -> NSPoint {
    let screen = NSScreen.forPopup ?? NSScreen.main ?? NSScreen.screens.first
    guard let visibleFrame = screen?.visibleFrame else {
      return .zero
    }

    return NSPoint(
      x: visibleFrame.minX + Self.horizontalMargin,
      y: visibleFrame.minY
    )
  }

  func panelSize() -> NSSize {
    let screen = NSScreen.forPopup ?? NSScreen.main ?? NSScreen.screens.first
    guard let visibleFrame = screen?.visibleFrame else {
      return NSSize(width: 800, height: Self.panelHeight)
    }

    return NSSize(
      width: visibleFrame.width - Self.horizontalMargin * 2,
      height: Self.panelHeight
    )
  }
}
