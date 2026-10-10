@testable import HealthGoals
import SwiftUI
import Testing

struct VisualColorsTests {
    @Test(arguments: [ColorScheme.light, .dark])
    func semanticTextPairsMeetMinimumContrast(_ scheme: ColorScheme) {
        var environment = EnvironmentValues()
        environment.colorScheme = scheme
        let pairs: [(name: String, foreground: Color, background: Color)] = [
            ("text / background", VisualColors.text, VisualColors.background),
            ("text / surface", VisualColors.text, VisualColors.surface),
            ("secondaryText / background", VisualColors.secondaryText, VisualColors.background),
            ("secondaryText / surface", VisualColors.secondaryText, VisualColors.surface),
            ("accent / background", VisualColors.accent, VisualColors.background),
            ("accent / surface", VisualColors.accent, VisualColors.surface),
            ("secondaryAccent / background", VisualColors.secondaryAccent, VisualColors.background),
            ("secondaryAccent / surface", VisualColors.secondaryAccent, VisualColors.surface),
            ("onAccent / accent", VisualColors.onAccent, VisualColors.accent),
            ("onCelebration / celebration", VisualColors.onCelebration, VisualColors.celebration),
        ]
        for pair in pairs {
            let foreground = pair.foreground.resolve(in: environment)
            let background = pair.background.resolve(in: environment)
            #expect(foreground.opacity == 1)
            #expect(background.opacity == 1)
            #expect(contrast(foreground, background) >= 4.5, "\(scheme): \(pair.name)")
        }
    }

    @Test func appearancesResolveToDifferentSurfaceBrightness() {
        var light = EnvironmentValues()
        light.colorScheme = .light
        var dark = EnvironmentValues()
        dark.colorScheme = .dark
        #expect(luminance(VisualColors.background.resolve(in: light)) > luminance(VisualColors.text.resolve(in: light)))
        #expect(luminance(VisualColors.background.resolve(in: dark)) < luminance(VisualColors.text.resolve(in: dark)))
        #expect(VisualColors.surface.resolve(in: light) != VisualColors.surface.resolve(in: dark))
    }
}

private extension VisualColorsTests {
    func contrast(_ first: Color.Resolved, _ second: Color.Resolved) -> Double {
        let firstLuminance = luminance(first)
        let secondLuminance = luminance(second)
        return (max(firstLuminance, secondLuminance) + Constants.viewingFlare) /
            (min(firstLuminance, secondLuminance) + Constants.viewingFlare)
    }

    func luminance(_ color: Color.Resolved) -> Double {
        // Color.Resolved provides linear sRGB channels; do not linearize them a second time.
        Double(color.linearRed) * Constants.redLuminanceWeight +
            Double(color.linearGreen) * Constants.greenLuminanceWeight +
            Double(color.linearBlue) * Constants.blueLuminanceWeight
    }

    enum Constants {
        static let redLuminanceWeight = 0.2126
        static let greenLuminanceWeight = 0.7152
        static let blueLuminanceWeight = 0.0722
        static let viewingFlare = 0.05
    }
}
