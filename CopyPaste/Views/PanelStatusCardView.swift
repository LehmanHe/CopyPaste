import Defaults
import SwiftUI

/// Leading block of the panel. It holds the app status instead of clipboard content,
/// so no copied text is ever rendered in it.
struct PanelStatusCardView: View {
  @Environment(AppState.self) private var appState
  @Environment(\.colorScheme) private var colorScheme

  @Default(.ignoreEvents) private var ignoreEvents

  @State private var isHovered = false

  private var shape: RoundedRectangle {
    RoundedRectangle(cornerRadius: Popup.cardCornerRadius, style: .continuous)
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      Image(systemName: ignoreEvents ? "pause.circle" : "sparkles")
        .font(.system(size: 18, weight: .light))
        .foregroundStyle(.secondary)
        .padding(.bottom, 12)

      Text("status_card_title")
        .font(.system(size: 13.5, weight: .semibold))
        .foregroundStyle(.primary.opacity(0.8))

      Text(ignoreEvents ? LocalizedStringKey("status_card_paused") : LocalizedStringKey("status_card_subtitle"))
        .font(.system(size: 11.5))
        .foregroundStyle(.secondary)
        .fixedSize(horizontal: false, vertical: true)
        .padding(.top, 2)

      Spacer(minLength: 8)

      Button {
        appState.openPreferences()
      } label: {
        Text("status_card_action")
          .font(.system(size: 11, weight: .medium))
          .foregroundStyle(.primary.opacity(0.75))
          .padding(.horizontal, 10)
          .frame(height: 22)
          .background(Capsule().fill(Color.primary.opacity(isHovered ? 0.12 : 0.07)))
      }
      .buttonStyle(.plain)
      .onHover { isHovered = $0 }
    }
    .multilineTextAlignment(.leading)
    .padding(14)
    .frame(width: Popup.cardWidth, alignment: .leading)
    .frame(maxHeight: .infinity, alignment: .leading)
    .background(shape.fill(Color.primary.opacity(colorScheme == .dark ? 0.09 : 0.05)))
  }
}
