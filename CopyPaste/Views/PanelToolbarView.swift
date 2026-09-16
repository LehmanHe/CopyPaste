import AppKit
import Defaults
import SwiftUI

struct PanelToolbarView: View {
  @FocusState.Binding var searchFocused: Bool

  @Environment(AppState.self) private var appState
  @Default(.ignoreEvents) private var ignoreEvents

  @State private var searchExpanded = false
  @State private var moreButtonFrame: CGRect = .zero

  private var searchShown: Bool {
    appState.searchVisible || searchExpanded
  }

  var body: some View {
    ZStack {
      centerControls

      HStack(spacing: 0) {
        Spacer()
        moreButton
      }
    }
    .frame(height: Popup.toolbarHeight)
    .padding(.horizontal, 18)
    .onChange(of: searchShown) {
      if !searchShown {
        appState.history.searchQuery = ""
      }
    }
  }

  private var centerControls: some View {
    HStack(spacing: 6) {
      if searchShown {
        SearchFieldView(placeholder: "search_placeholder", query: searchQuery)
          .focused($searchFocused)
          .frame(width: 240)
          .transition(.scale(scale: 0.9, anchor: .center).combined(with: .opacity))
      } else {
        ToolbarIconButton(symbol: "magnifyingglass", help: "search_tooltip") {
          searchExpanded = true
          searchFocused = true
        }
      }

      filterChip
      recordingChip
      pinButton
    }
    .animation(.easeInOut(duration: 0.15), value: searchShown)
  }

  private var pinButton: some View {
    ToolbarIconButton(
      symbol: appState.navigator.selection.items.allSatisfy(\.isPinned) ? "pin.slash" : "pin",
      help: "pin_tooltip"
    ) {
      withAnimation {
        appState.togglePin()
      }
    }
    .disabled(appState.navigator.selection.isEmpty)
  }

  private var moreButton: some View {
    ToolbarIconButton(symbol: "ellipsis", help: "more_tooltip") {
      PanelMenu.shared.show(below: moreButtonFrame)
    }
    .background(
      GeometryReader { proxy in
        Color.clear
          .onAppear { moreButtonFrame = proxy.frame(in: .global) }
          .onChange(of: proxy.frame(in: .global)) { moreButtonFrame = proxy.frame(in: .global) }
      }
    )
  }

  private var searchQuery: Binding<String> {
    Binding(
      get: { appState.history.searchQuery },
      set: { appState.history.searchQuery = $0 }
    )
  }

  private var filterChip: some View {
    let filter = appState.history.filter

    return ToolbarChip(isActive: filter != .all) {
      appState.history.apply(filter: filter.next)
    } label: {
      Image(systemName: filter.symbol)
        .font(.system(size: 10, weight: .semibold))
      Text(filter.title)
    }
    .help(Text("filter_tooltip"))
  }

  private var recordingChip: some View {
    ToolbarChip(isActive: false) {
      ignoreEvents.toggle()
    } label: {
      Circle()
        .fill(ignoreEvents ? Color.secondary : Color.red)
        .frame(width: 7, height: 7)
      Text(ignoreEvents ? LocalizedStringKey("recording_paused") : LocalizedStringKey("recording_active"))
    }
    .help(Text("recording_tooltip"))
  }
}

struct ToolbarIconButton: View {
  let symbol: String
  let help: LocalizedStringKey
  let action: @MainActor () -> Void

  @State private var isHovered = false
  @Environment(\.isEnabled) private var isEnabled

  var body: some View {
    Button(action: action) {
      Image(systemName: symbol)
        .font(.system(size: 12.5, weight: .medium))
        .foregroundStyle(isEnabled ? Color.primary.opacity(0.75) : Color.primary.opacity(0.3))
        .frame(width: 27, height: 25)
        .background(
          Capsule().fill(Color.primary.opacity(isHovered && isEnabled ? 0.1 : 0))
        )
    }
    .buttonStyle(.plain)
    .onHover { isHovered = $0 }
    .help(Text(help))
  }
}

struct ToolbarChip<Label: View>: View {
  var isActive: Bool
  let action: @MainActor () -> Void
  @ViewBuilder let label: () -> Label

  @State private var isHovered = false

  var body: some View {
    Button(action: action) {
      HStack(spacing: 4) {
        label()
      }
      .font(.system(size: 11.5, weight: .medium))
      .foregroundStyle(isActive ? Color.accentColor : Color.primary.opacity(0.75))
      .lineLimit(1)
      .padding(.horizontal, 10)
      .frame(height: 25)
      .background(
        Capsule().fill(
          isActive
            ? Color.accentColor.opacity(isHovered ? 0.2 : 0.14)
            : Color.primary.opacity(isHovered ? 0.12 : 0.07)
        )
      )
    }
    .buttonStyle(.plain)
    .onHover { isHovered = $0 }
  }
}

/// The panel closes as soon as it resigns key, so menus are presented through AppKit
/// with a flag that keeps the panel open while the menu is tracking.
@MainActor
final class PanelMenu: NSObject {
  static let shared = PanelMenu()

  func show(below frame: CGRect) {
    guard let panel = AppState.shared.appDelegate?.panel,
          let contentView = panel.contentView else {
      return
    }

    let origin = NSPoint(
      x: frame.minX,
      y: contentView.isFlipped ? frame.maxY + 4 : contentView.bounds.height - frame.maxY - 4
    )

    panel.isMenuPresented = true
    menu().popUp(positioning: nil, at: origin, in: contentView)
    panel.isMenuPresented = false
  }

  private func menu() -> NSMenu {
    let menu = NSMenu()

    menu.addItem(item(title: "clear", action: #selector(clearHistory)))
    menu.addItem(item(title: "clear_all", action: #selector(clearAllHistory)))
    menu.addItem(.separator())
    menu.addItem(item(title: "preferences", action: #selector(openPreferences), key: ","))
    menu.addItem(item(title: "about", action: #selector(openAbout)))
    menu.addItem(.separator())
    menu.addItem(item(title: "quit", action: #selector(quit), key: "q"))

    return menu
  }

  private func item(title: String, action: Selector, key: String = "") -> NSMenuItem {
    let item = NSMenuItem(
      title: NSLocalizedString(title, comment: ""),
      action: action,
      keyEquivalent: key
    )
    item.target = self
    return item
  }

  @objc private func clearHistory() {
    AppState.shared.history.clear()
  }

  @objc private func clearAllHistory() {
    AppState.shared.history.clearAll()
  }

  @objc private func openPreferences() {
    AppState.shared.openPreferences()
  }

  @objc private func openAbout() {
    AppState.shared.openAbout()
  }

  @objc private func quit() {
    AppState.shared.quit()
  }
}
