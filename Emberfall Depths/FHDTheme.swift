import SwiftUI

// Central color palette for Frost Hollow Depths.
// Cold dungeon identity: deep glacial blue / near-black, warm torch orange,
// ice cyan, bone ivory. Forced dark scheme.
enum FHDTheme {
    // Backgrounds
    static let abyss = Color(red: 0.04, green: 0.06, blue: 0.11)        // near-black glacial
    static let deepBlue = Color(red: 0.07, green: 0.11, blue: 0.20)
    static let panel = Color(red: 0.10, green: 0.15, blue: 0.25)
    static let panelRaised = Color(red: 0.14, green: 0.20, blue: 0.32)

    // Accents
    static let torch = Color(red: 1.0, green: 0.56, blue: 0.18)         // warm orange
    static let ember = Color(red: 1.0, green: 0.74, blue: 0.30)
    static let iceCyan = Color(red: 0.50, green: 0.86, blue: 0.97)
    static let frost = Color(red: 0.62, green: 0.78, blue: 0.95)
    static let ivory = Color(red: 0.93, green: 0.95, blue: 0.92)        // bone ivory text

    // Status
    static let blood = Color(red: 0.86, green: 0.27, blue: 0.30)
    static let poison = Color(red: 0.55, green: 0.85, blue: 0.45)
    static let gold = Color(red: 0.95, green: 0.82, blue: 0.36)
    static let shard = Color(red: 0.62, green: 0.92, blue: 1.0)         // frost shard
    static let danger = Color(red: 0.92, green: 0.38, blue: 0.36)

    static let textDim = Color(red: 0.62, green: 0.70, blue: 0.82)
    static let stroke = Color(red: 0.24, green: 0.34, blue: 0.50)

    static var warmGradient: LinearGradient {
        LinearGradient(colors: [ember, torch, blood.opacity(0.8)],
                       startPoint: .top, endPoint: .bottom)
    }
    static var coldGradient: LinearGradient {
        LinearGradient(colors: [iceCyan, frost, deepBlue],
                       startPoint: .top, endPoint: .bottom)
    }

    // Warmth bar color: glows orange when warm, dims to icy blue as it drops.
    static func warmthColor(_ frac: Double) -> Color {
        let f = max(0, min(1, frac))
        // interpolate from iceCyan (cold) -> torch (warm)
        let r = 0.50 + (1.0 - 0.50) * f
        let g = 0.86 + (0.56 - 0.86) * f
        let b = 0.97 + (0.18 - 0.97) * f
        return Color(red: r, green: g, blue: b)
    }

    static func hpColor(_ frac: Double) -> Color {
        let f = max(0, min(1, frac))
        if f > 0.5 { return Color(red: 0.45, green: 0.80, blue: 0.50) }
        if f > 0.25 { return gold }
        return blood
    }
}

// Reusable card background modifier.
struct FHDCard: ViewModifier {
    var raised: Bool = false
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(raised ? FHDTheme.panelRaised : FHDTheme.panel)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(FHDTheme.stroke.opacity(0.6), lineWidth: 1)
                    )
            )
    }
}

extension View {
    func fhdCard(raised: Bool = false) -> some View {
        modifier(FHDCard(raised: raised))
    }

    // Clamp + center idiom for iPad-compat safety.
    func fhdFit(maxWidth: CGFloat = 620) -> some View {
        self.frame(maxWidth: maxWidth).frame(maxWidth: .infinity)
    }
}

struct FHDButtonStyle: ButtonStyle {
    var tint: Color = FHDTheme.torch
    var filled: Bool = true
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .bold, design: .serif))
            .foregroundColor(filled ? FHDTheme.abyss : tint)
            .padding(.vertical, 13)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(filled ? tint : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(tint, lineWidth: filled ? 0 : 1.5)
                    )
            )
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
    }
}
