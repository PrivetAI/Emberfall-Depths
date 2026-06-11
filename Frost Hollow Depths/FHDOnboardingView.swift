import SwiftUI

// 5-step skippable onboarding overlay shown on first run.
struct FHDOnboardingView: View {
    @Binding var isShown: Bool
    var onDone: () -> Void
    @State private var step = 0

    private let totalSteps = 5

    var body: some View {
        ZStack {
            Color.black.opacity(0.78).edgesIgnoringSafeArea(.all)
            VStack(spacing: 16) {
                HStack {
                    Text("Step \(step + 1) of \(totalSteps)")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(FHDTheme.textDim)
                    Spacer()
                    Button { finish() } label: {
                        Text("Skip")
                            .font(.system(size: 13, weight: .bold, design: .serif))
                            .foregroundColor(FHDTheme.frost)
                            .padding(.horizontal, 12).padding(.vertical, 6)
                            .background(RoundedRectangle(cornerRadius: 8).stroke(FHDTheme.frost.opacity(0.6), lineWidth: 1))
                    }
                }

                ZStack {
                    Circle().fill(stepColor.opacity(0.14)).frame(width: 84, height: 84)
                    FHDGlyph(kind: stepGlyph, size: 44, color: stepColor)
                }
                .padding(.top, 2)

                Text(stepTitle)
                    .font(.system(size: 20, weight: .heavy, design: .serif))
                    .foregroundColor(FHDTheme.ivory)
                    .multilineTextAlignment(.center)

                Text(stepBody)
                    .font(.system(size: 13, weight: .medium, design: .serif))
                    .foregroundColor(FHDTheme.textDim)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 4)

                // progress dots
                HStack(spacing: 7) {
                    ForEach(0..<totalSteps, id: \.self) { i in
                        Circle()
                            .fill(i == step ? FHDTheme.torch : FHDTheme.stroke)
                            .frame(width: 7, height: 7)
                    }
                }
                .padding(.top, 2)

                HStack(spacing: 10) {
                    if step > 0 {
                        Button { step -= 1 } label: { Text("Back") }
                            .buttonStyle(FHDButtonStyle(tint: FHDTheme.frost, filled: false))
                    }
                    Button {
                        if step < totalSteps - 1 { step += 1 } else { finish() }
                    } label: {
                        Text(step < totalSteps - 1 ? "Next" : "Descend")
                    }
                    .buttonStyle(FHDButtonStyle(tint: FHDTheme.torch))
                }
            }
            .padding(20)
            .frame(maxWidth: 360)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(FHDTheme.deepBlue)
                    .overlay(RoundedRectangle(cornerRadius: 18).stroke(FHDTheme.stroke, lineWidth: 1))
            )
            .padding(24)
        }
    }

    private func finish() {
        isShown = false
        onDone()
    }

    private var stepTitle: String {
        switch step {
        case 0: return "Welcome to the Depths"
        case 1: return "Warmth Is Life"
        case 2: return "Light the Dark"
        case 3: return "Unknown Brews"
        default: return "Death Is Not the End"
        }
    }

    private var stepBody: String {
        switch step {
        case 0:
            return "Descend 30 floors through six frozen biomes. Swipe or use the arrows to move — every step ticks the world, and every enemy moves when you do. Walk into a foe to strike it."
        case 1:
            return "The cold drains your Warmth every turn. At zero, frostbite gnaws your health and slows your hands. Braziers, lava, heat vaults and warm meals restore it — ice, water and frost auras steal it."
        case 2:
            return "Your light radius shrinks in the dark and the cold. Keep a torch lit and carry fuel; what you cannot see can still hunt you. Use Look mode to examine anything in sight."
        case 3:
            return "Potions and scrolls are unidentified each run — a Crimson Potion may heal this descent and chill the next. Drink, read, or use a Scroll of Identify to learn their nature."
        default:
            return "Falling ends the run, but Frost Shards endure. Spend them in the Frost Vault on new classes and permanent boons. Each descent leaves you stronger than the last."
        }
    }

    private var stepGlyph: FHDGlyph.Kind {
        switch step {
        case 0: return .stairs
        case 1: return .flame
        case 2: return .eye
        case 3: return .potion
        default: return .snow
        }
    }

    private var stepColor: Color {
        switch step {
        case 0: return FHDTheme.frost
        case 1: return FHDTheme.torch
        case 2: return FHDTheme.iceCyan
        case 3: return FHDTheme.poison
        default: return FHDTheme.shard
        }
    }
}
