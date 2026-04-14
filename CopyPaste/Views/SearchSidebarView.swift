import Defaults
import SwiftUI

struct SearchSidebarView: View {
  @FocusState.Binding var searchFocused: Bool
  @Binding var searchQuery: String
  @Bindable var footer: Footer

  @Environment(AppState.self) private var appState
  @Environment(\.scenePhase) private var scenePhase

  @Default(.showTitle) private var showTitle
  @Default(.showFooter) private var showFooter

  var body: some View {
    VStack(spacing: 8) {
      if showTitle {
        Text("CopyPaste")
          .font(.headline)
          .foregroundStyle(.secondary)
      }

      SearchFieldView(placeholder: "search_placeholder", query: $searchQuery)
        .focused($searchFocused)
        .onChange(of: scenePhase) {
          if scenePhase == .background && !searchQuery.isEmpty {
            searchQuery = ""
          }
        }

      Spacer()

      if showFooter {
        VStack(spacing: 4) {
          ForEach(footer.items) { item in
            if item.isVisible {
              FooterItemView(item: item)
            }
          }
        }
      }
    }
    .frame(width: 160)
    .padding(.trailing, 8)
  }
}
