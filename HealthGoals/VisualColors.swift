import SwiftUI

/// Semantic V1 roles. Appearance variants live in the asset catalog.
enum VisualColors {
    static let background = Color(.visualBackground)
    static let surface = Color(.visualSurface)
    static let text = Color(.visualText)
    static let secondaryText = Color(.visualSecondaryText)
    static let accent = Color(.visualAccent)
    static let secondaryAccent = Color(.visualSecondaryAccent)
    static let onAccent = Color(.visualOnAccent)
    static let celebration = Color(.visualCelebration)
    static let onCelebration = Color(.visualOnCelebration)
}

#if DEBUG
    private struct VisualRolesPreview: View {
        var body: some View {
            ScrollView {
                VStack(alignment: .leading, spacing: Constants.sectionSpacing) {
                    Text(verbatim: "V1 semantic roles")
                        .font(.title2.bold())
                    swatch("background / text", fill: VisualColors.background, ink: VisualColors.text)
                    swatch("surface / text", fill: VisualColors.surface, ink: VisualColors.text)
                    swatch("surface / secondaryText", fill: VisualColors.surface, ink: VisualColors.secondaryText)
                    Button {} label: {
                        Text(verbatim: "accent / onAccent")
                            .foregroundStyle(VisualColors.onAccent)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(VisualColors.accent)
                    Button {} label: {
                        Text(verbatim: "accent on background")
                    }
                    .tint(VisualColors.accent)
                    Button {} label: {
                        Text(verbatim: "secondaryAccent on background")
                    }
                    .tint(VisualColors.secondaryAccent)
                    swatch(
                        "celebration / onCelebration",
                        fill: VisualColors.celebration,
                        ink: VisualColors.onCelebration
                    )
                    Text(verbatim: "Native body text — SF Pro / Dynamic Type")
                        .font(.body)
                    Text(verbatim: "Native footnote — secondaryText")
                        .font(.footnote)
                        .foregroundStyle(VisualColors.secondaryText)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
            }
            .foregroundStyle(VisualColors.text)
            .background(VisualColors.background)
        }
    }

    private extension VisualRolesPreview {
        func swatch(_ title: String, fill: Color, ink: Color) -> some View {
            Text(verbatim: title)
                .font(.body)
                .foregroundStyle(ink)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(fill, in: RoundedRectangle(cornerRadius: Constants.swatchRadius))
        }

        enum Constants {
            static let sectionSpacing: CGFloat = 16
            static let swatchRadius: CGFloat = 12
        }
    }

    #Preview("V1 Light") {
        VisualRolesPreview().preferredColorScheme(.light)
    }

    #Preview("V1 Dark") {
        VisualRolesPreview().preferredColorScheme(.dark)
    }

    #Preview("V1 Light — Accessibility") {
        VisualRolesPreview()
            .preferredColorScheme(.light)
            .environment(\.dynamicTypeSize, .accessibility3)
    }

    #Preview("V1 Dark — Accessibility") {
        VisualRolesPreview()
            .preferredColorScheme(.dark)
            .environment(\.dynamicTypeSize, .accessibility3)
    }
#endif
