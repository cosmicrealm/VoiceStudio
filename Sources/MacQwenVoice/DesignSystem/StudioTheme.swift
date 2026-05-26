import AppKit
import SwiftUI

enum StudioTheme {
    static let workspaceBackground = Color(nsColor: NSColor.windowBackgroundColor)
    static let panelBackground = Color(nsColor: NSColor.controlBackgroundColor)
    static let elevatedBackground = Color(nsColor: NSColor.textBackgroundColor)
    static let subtleFill = Color.secondary.opacity(0.08)
    static let border = Color.secondary.opacity(0.16)
    static let accentSoft = Color.accentColor.opacity(0.10)
    static let success = Color.green
    static let warning = Color.orange
    static let danger = Color.red
    static let cornerRadius: CGFloat = 8
    static let pagePadding: CGFloat = 20
}

struct StudioPanel<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(16)
            .background(StudioTheme.elevatedBackground)
            .clipShape(RoundedRectangle(cornerRadius: StudioTheme.cornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: StudioTheme.cornerRadius, style: .continuous)
                    .stroke(StudioTheme.border, lineWidth: 1)
            }
    }
}

struct StudioSectionHeader: View {
    let title: String
    let subtitle: String?

    init(_ title: String, subtitle: String? = nil) {
        self.title = title
        self.subtitle = subtitle
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.headline)
            if let subtitle {
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct StudioPill: View {
    let title: String
    let systemImage: String
    var color: Color = .secondary

    var body: some View {
        Label(title, systemImage: systemImage)
            .font(.caption.weight(.semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(color.opacity(0.10))
            .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
    }
}

struct StudioToolbarButton: View {
    let title: String
    let systemImage: String
    var prominent = false
    let action: () -> Void

    var body: some View {
        Group {
            if prominent {
                Button(action: action) {
                    Label(title, systemImage: systemImage)
                        .frame(minHeight: 28)
                }
                .buttonStyle(.borderedProminent)
            } else {
                Button(action: action) {
                    Label(title, systemImage: systemImage)
                        .frame(minHeight: 28)
                }
                .buttonStyle(.bordered)
            }
        }
        .controlSize(.regular)
    }
}

extension View {
    func studioCardStyle() -> some View {
        padding(14)
            .background(StudioTheme.subtleFill)
            .clipShape(RoundedRectangle(cornerRadius: StudioTheme.cornerRadius, style: .continuous))
    }
}
