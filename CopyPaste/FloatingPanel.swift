import Defaults
import SwiftUI

// An NSPanel subclass that implements floating panel traits.
class FloatingPanel<Content: View>: NSPanel, NSWindowDelegate {
  var isPresented: Bool = false
  var statusBarButton: NSStatusBarButton?
  // Menus take over event tracking, the panel must survive until they are dismissed.
  var isMenuPresented: Bool = false
  let onClose: () -> Void

  override var isMovable: Bool {
    get { false }
    set {}
  }

  init(
    contentRect: NSRect,
    identifier: String = "",
    statusBarButton: NSStatusBarButton? = nil,
    onClose: @escaping () -> Void,
    view: () -> Content
  ) {
    self.onClose = onClose

    super.init(
        contentRect: contentRect,
        styleMask: [.nonactivatingPanel, .closable, .fullSizeContentView],
        backing: .buffered,
        defer: false
    )

    self.statusBarButton = statusBarButton
    self.identifier = NSUserInterfaceItemIdentifier(identifier)

    delegate = self

    animationBehavior = .none
    isFloatingPanel = true
    level = .statusBar
    collectionBehavior = [.auxiliary, .stationary, .moveToActiveSpace, .fullScreenAuxiliary]
    titleVisibility = .hidden
    titlebarAppearsTransparent = true
    isMovableByWindowBackground = false
    hidesOnDeactivate = false
    backgroundColor = .clear
    titlebarSeparatorStyle = .none

    standardWindowButton(.closeButton)?.isHidden = true
    standardWindowButton(.miniaturizeButton)?.isHidden = true
    standardWindowButton(.zoomButton)?.isHidden = true

    contentView = NSHostingView(
      rootView: view()
        .ignoresSafeArea()
    )
    contentView?.wantsLayer = true
    contentView?.layer?.cornerRadius = Popup.panelCornerRadius
    contentView?.layer?.cornerCurve = .continuous
    contentView?.layer?.masksToBounds = true
  }

  func toggle(height: CGFloat, at popupPosition: PopupPosition = .bottom) {
    if isPresented {
      close()
    } else {
      open(height: height, at: popupPosition)
    }
  }

  func open(height: CGFloat, at popupPosition: PopupPosition = .bottom) {
    let panelSize = popupPosition.panelSize()
    setContentSize(panelSize)
    setFrameOrigin(popupPosition.origin(size: panelSize, statusBarButton: statusBarButton))
    orderFrontRegardless()
    makeKey()
    isPresented = true
  }

  // Close automatically when out of focus, e.g. outside click.
  override func resignKey() {
    super.resignKey()
    if NSApp.alertWindow == nil && !isMenuPresented {
      close()
    }
  }

  override func close() {
    super.close()
    isPresented = false
    statusBarButton?.isHighlighted = false
    onClose()
  }

  override var canBecomeKey: Bool {
    return true
  }
}
