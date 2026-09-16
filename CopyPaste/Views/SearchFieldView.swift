import SwiftUI

struct SearchFieldView: View {
  var placeholder: LocalizedStringKey
  @Binding var query: String

  @Environment(AppState.self) private var appState

  var body: some View {
    ZStack {
      Capsule()
        .fill(Color.primary)
        .opacity(0.07)
        .frame(height: 25)

      HStack(spacing: 5) {
        Image(systemName: "magnifyingglass")
          .font(.system(size: 11, weight: .medium))
          .padding(.leading, 10)
          .opacity(0.7)

        TextField(placeholder, text: $query)
          .font(.system(size: 12.5))
          .disableAutocorrection(true)
          .lineLimit(1)
          .textFieldStyle(.plain)
          .onSubmit {
            appState.select()
          }

        if !query.isEmpty {
          Button {
            query = ""
          } label: {
            Image(systemName: "xmark.circle.fill")
              .font(.system(size: 11))
              .padding(.trailing, 9)
          }
          .buttonStyle(.plain)
          .opacity(0.7)
        }
      }
      .frame(height: 25)
    }
  }
}

#Preview {
  return List {
    SearchFieldView(placeholder: "search_placeholder", query: .constant(""))
    SearchFieldView(placeholder: "search_placeholder", query: .constant("search"))
  }
  .frame(width: 300)
  .environment(\.locale, .init(identifier: "en"))
}
