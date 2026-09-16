import Defaults
import SwiftUI

struct HistoryListView: View {
  @Binding var searchQuery: String
  @FocusState.Binding var searchFocused: Bool

  @Environment(AppState.self) private var appState
  @Environment(ModifierFlags.self) private var modifierFlags
  @Environment(\.scenePhase) private var scenePhase

  @Default(.pinTo) private var pinTo

  private var pinnedItems: [HistoryItemDecorator] {
    appState.history.pinnedItems.filter(\.isVisible)
  }
  private var unpinnedItems: [HistoryItemDecorator] {
    appState.history.unpinnedItems.filter(\.isVisible)
  }
  private var pinsVisible: Bool {
    return !pinnedItems.isEmpty
  }

  private var allVisibleItems: [HistoryItemDecorator] {
    if pinTo == .top {
      return pinnedItems + unpinnedItems
    } else {
      return unpinnedItems + pinnedItems
    }
  }

  var body: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      ScrollViewReader { proxy in
        LazyHStack(spacing: Popup.cardSpacing) {
          PanelStatusCardView()

          ForEach(Array(allVisibleItems.enumerated()), id: \.element.id) { (index, item) in
            let previous = index > 0 ? allVisibleItems[index - 1] : nil
            let next = index < allVisibleItems.count - 1 ? allVisibleItems[index + 1] : nil
            CardItemView(item: item, previous: previous, next: next, index: index)
          }
        }
        .padding(.horizontal, Popup.listHorizontalPadding)
        .padding(.top, Popup.listTopPadding)
        .padding(.bottom, Popup.listBottomPadding)
        .task(id: appState.navigator.scrollTarget) {
          guard appState.navigator.scrollTarget != nil else { return }

          try? await Task.sleep(for: .milliseconds(10))
          guard !Task.isCancelled else { return }

          if let selection = appState.navigator.scrollTarget {
            withAnimation(.easeInOut(duration: 0.2)) {
              proxy.scrollTo(selection, anchor: .center)
            }
            appState.navigator.scrollTarget = nil
          }
        }
        .onChange(of: scenePhase) {
          if scenePhase == .active {
            searchFocused = true
            appState.navigator.isKeyboardNavigating = true
            appState.navigator.select(
              item: appState.history.unpinnedItems.first ?? appState.history.pinnedItems.first
            )
          } else {
            modifierFlags.flags = []
            appState.navigator.isKeyboardNavigating = true
          }
        }
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .overlay {
      if allVisibleItems.isEmpty {
        emptyState
      }
    }
  }

  private var emptyState: some View {
    VStack(spacing: 6) {
      Image(systemName: searchQuery.isEmpty ? "doc.on.clipboard" : "magnifyingglass")
        .font(.system(size: 26, weight: .light))
        .foregroundStyle(.tertiary)

      Text(searchQuery.isEmpty ? LocalizedStringKey("history_empty") : LocalizedStringKey("search_empty"))
        .font(.system(size: 13))
        .foregroundStyle(.secondary)
    }
    .padding(.bottom, Popup.listBottomPadding)
  }
}
