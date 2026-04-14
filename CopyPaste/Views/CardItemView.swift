import Defaults
import SwiftUI

struct CardItemView: View {
  @Bindable var item: HistoryItemDecorator
  var previous: HistoryItemDecorator?
  var next: HistoryItemDecorator?
  var index: Int

  @Default(.showApplicationIcons) private var showIcons
  @Environment(AppState.self) private var appState

  var body: some View {
    VStack(spacing: 0) {
      cardContent
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()

      Divider()

      cardFooter
        .frame(height: 28)
    }
    .frame(width: Popup.cardWidth)
    .frame(maxHeight: .infinity)
    .background(
      RoundedRectangle(cornerRadius: Popup.cornerRadius + 2)
        .fill(item.isSelected ? Color.accentColor.opacity(0.15) : Color.secondary.opacity(0.08))
    )
    .overlay(
      RoundedRectangle(cornerRadius: Popup.cornerRadius + 2)
        .strokeBorder(item.isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
    )
    .clipShape(RoundedRectangle(cornerRadius: Popup.cornerRadius + 2))
    .id(item.id)
    .hoverSelectionId(item.id)
    .onAppear {
      item.ensureThumbnailImage()
    }
    .onTapGesture {
      if NSEvent.modifierFlags.contains(.command) && appState.multiSelectionEnabled {
        appState.navigator.addToSelection(item: item)
      } else {
        Task {
          appState.history.select(item)
        }
      }
    }
  }

  @ViewBuilder
  private var cardContent: some View {
    if let image = item.thumbnailImage {
      Image(nsImage: image)
        .resizable()
        .aspectRatio(contentMode: .fit)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(6)
    } else if let accessoryImage = ColorImage.from(item.title) {
      Image(nsImage: accessoryImage)
        .resizable()
        .aspectRatio(contentMode: .fit)
        .frame(width: 40, height: 40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    } else {
      VStack(alignment: .leading, spacing: 0) {
        if let attrTitle = item.attributedTitle {
          Text(attrTitle)
            .font(.system(size: 11))
            .lineLimit(nil)
            .multilineTextAlignment(.leading)
        } else {
          Text(verbatim: item.title)
            .font(.system(size: 11))
            .lineLimit(nil)
            .multilineTextAlignment(.leading)
        }
      }
      .foregroundStyle(item.isSelected ? Color.primary : .primary)
      .padding(8)
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
  }

  @ViewBuilder
  private var cardFooter: some View {
    HStack(spacing: 4) {
      if showIcons {
        AppImageView(appImage: item.applicationImage, size: NSSize(width: 14, height: 14))
      }

      if let app = item.application {
        Text(app)
          .font(.system(size: 10))
          .foregroundStyle(.secondary)
          .lineLimit(1)
          .truncationMode(.tail)
      } else {
        Text(verbatim: item.title)
          .font(.system(size: 10))
          .foregroundStyle(.secondary)
          .lineLimit(1)
          .truncationMode(.tail)
      }

      Spacer(minLength: 0)

      if item.isPinned {
        Image(systemName: "pin.fill")
          .font(.system(size: 8))
          .foregroundStyle(.secondary)
      }

      if !item.shortcuts.isEmpty {
        HStack(spacing: 2) {
          ForEach(item.shortcuts) { shortcut in
            KeyboardShortcutView(shortcut: shortcut)
          }
        }
      }
    }
    .padding(.horizontal, 8)
  }
}
