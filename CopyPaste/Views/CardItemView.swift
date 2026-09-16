import Defaults
import SwiftUI

struct CardItemView: View {
  @Bindable var item: HistoryItemDecorator
  var previous: HistoryItemDecorator?
  var next: HistoryItemDecorator?
  var index: Int

  @Default(.showApplicationIcons) private var showIcons
  @Environment(AppState.self) private var appState
  @Environment(\.colorScheme) private var colorScheme

  @State private var isHovered = false

  private var shape: RoundedRectangle {
    RoundedRectangle(cornerRadius: Popup.cardCornerRadius, style: .continuous)
  }

  private var surface: Color {
    colorScheme == .dark ? Color(nsColor: .underPageBackgroundColor) : .white
  }

  var body: some View {
    VStack(spacing: 0) {
      header
      preview
    }
    .frame(width: Popup.cardWidth)
    .frame(maxHeight: .infinity)
    .background(surface)
    .overlay(alignment: .topTrailing) { applicationBadge }
    .overlay(alignment: .bottomLeading) { shortcutBadge }
    .clipShape(shape)
    .overlay {
      shape.strokeBorder(
        item.isSelected ? Color.accentColor : Color.primary.opacity(colorScheme == .dark ? 0.15 : 0.08),
        lineWidth: item.isSelected ? 2.5 : 1
      )
    }
    .shadow(color: .black.opacity(isHovered ? 0.2 : 0.12), radius: isHovered ? 6 : 3, y: 1)
    .animation(.easeOut(duration: 0.12), value: isHovered)
    .id(item.id)
    .hoverSelectionId(item.id)
    .onHover { isHovered = $0 }
    .onAppear {
      item.ensureThumbnailImage()
    }
    .onTapGesture(count: 2) {
      Task {
        appState.history.paste(item)
      }
    }
    .onTapGesture {
      if NSEvent.modifierFlags.contains(.command) && appState.multiSelectionEnabled {
        appState.navigator.addToSelection(item: item)
      } else {
        appState.navigator.select(item: item)
      }
    }
  }

  private var header: some View {
    HStack(alignment: .top, spacing: 4) {
      VStack(alignment: .leading, spacing: 1) {
        Text(item.kind.title)
          .font(.system(size: 13.5, weight: .semibold))
          .foregroundStyle(.white)

        Text(item.relativeTime)
          .font(.system(size: 11))
          .foregroundStyle(.white.opacity(0.75))
      }
      .lineLimit(1)

      Spacer(minLength: 0)

      if item.isPinned {
        Image(systemName: "pin.fill")
          .font(.system(size: 10))
          .foregroundStyle(.white.opacity(0.85))
          .padding(.top, 2)
      }
    }
    .padding(.leading, 12)
    .padding(.trailing, showIcons ? Popup.cardHeaderHeight + 4 : 12)
    .padding(.vertical, 7)
    .frame(height: Popup.cardHeaderHeight, alignment: .top)
    .background(item.kind.accentColor)
  }

  @ViewBuilder
  private var preview: some View {
    switch item.kind {
    case .image:
      imagePreview
    case .color:
      colorPreview
    case .link:
      linkPreview
    default:
      textPreview
    }
  }

  private var imagePreview: some View {
    ZStack(alignment: .bottom) {
      if let image = item.thumbnailImage {
        Image(nsImage: image)
          .resizable()
          .aspectRatio(contentMode: .fill)
          .frame(maxWidth: .infinity, maxHeight: .infinity)
      } else {
        Image(systemName: "photo")
          .font(.system(size: 30, weight: .light))
          .foregroundStyle(.tertiary)
          .frame(maxWidth: .infinity, maxHeight: .infinity)
      }

      if let dimensions = item.imageDimensions {
        Text(verbatim: dimensions)
          .font(.system(size: 10.5, weight: .medium))
          .foregroundStyle(.secondary)
          .padding(.horizontal, 7)
          .padding(.vertical, 3)
          .background(Capsule().fill(.regularMaterial))
          .padding(.bottom, 8)
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .clipped()
  }

  private var colorPreview: some View {
    ZStack {
      if let swatch = ColorImage.from(item.title) {
        Image(nsImage: swatch)
          .resizable()
          .frame(maxWidth: .infinity, maxHeight: .infinity)
      }

      Text(verbatim: item.title)
        .font(.system(size: 12.5, weight: .medium, design: .monospaced))
        .foregroundStyle(.white)
        .padding(.horizontal, 9)
        .padding(.vertical, 4)
        .background(Capsule().fill(.black.opacity(0.35)))
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

  private var linkPreview: some View {
    VStack(spacing: 0) {
      ZStack {
        LinearGradient(
          colors: [Color.primary.opacity(0.01), Color.primary.opacity(0.06)],
          startPoint: .top,
          endPoint: .bottom
        )

        Image(systemName: "safari")
          .font(.system(size: 32, weight: .thin))
          .foregroundStyle(.tertiary)
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)

      subtitle(alignment: .leading, lineLimit: 2)
    }
  }

  private var textPreview: some View {
    VStack(alignment: .leading, spacing: 4) {
      Group {
        if let attributedTitle = item.attributedTitle {
          Text(attributedTitle)
        } else {
          Text(verbatim: item.title)
        }
      }
      .font(.system(size: 13))
      .lineSpacing(1.5)
      .multilineTextAlignment(.leading)
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
      .padding(.horizontal, 13)
      .padding(.top, 11)

      subtitle(alignment: .trailing, lineLimit: 1)
    }
    .clipped()
  }

  @ViewBuilder
  private func subtitle(alignment: Alignment, lineLimit: Int) -> some View {
    if let subtitle = item.subtitle {
      Text(verbatim: subtitle)
        .font(.system(size: 10.5))
        .foregroundStyle(.secondary)
        .lineLimit(lineLimit)
        .truncationMode(.middle)
        .multilineTextAlignment(alignment == .trailing ? .trailing : .leading)
        .frame(maxWidth: .infinity, alignment: alignment)
        .padding(.horizontal, 13)
        .padding(.bottom, 10)
    }
  }

  @ViewBuilder
  private var applicationBadge: some View {
    if showIcons {
      ZStack {
        surface
        AppImageView(
          appImage: item.applicationImage,
          size: NSSize(width: 32, height: 32)
        )
      }
      .frame(width: Popup.cardHeaderHeight, height: Popup.cardHeaderHeight)
    }
  }

  @ViewBuilder
  private var shortcutBadge: some View {
    if let shortcut = item.shortcuts.first, isHovered || item.isSelected {
      KeyboardShortcutView(shortcut: shortcut)
        .font(.system(size: 10, weight: .medium))
        .foregroundStyle(.secondary)
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(Capsule().fill(.regularMaterial))
        .padding(8)
        .transition(.opacity)
    }
  }
}
