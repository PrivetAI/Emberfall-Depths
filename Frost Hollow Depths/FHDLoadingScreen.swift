import SwiftUI

struct FrostHollowLoadingScreen: View {
    @State private var glow = false
    @State private var spin = false

    var body: some View {
        ZStack {
            FHDTheme.abyss.edgesIgnoringSafeArea(.all)
            VStack(spacing: 26) {
                ZStack {
                    FHDSnowflakeShape()
                        .stroke(FHDTheme.iceCyan.opacity(0.5), lineWidth: 3)
                        .frame(width: 96, height: 96)
                        .rotationEffect(.degrees(spin ? 360 : 0))
                        .animation(.linear(duration: 18).repeatForever(autoreverses: false), value: spin)
                    FHDFlameShape()
                        .fill(FHDTheme.warmGradient)
                        .frame(width: 38, height: 52)
                        .scaleEffect(glow ? 1.18 : 0.82)
                        .shadow(color: FHDTheme.torch.opacity(0.8), radius: glow ? 18 : 6)
                        .animation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true), value: glow)
                }
                Text("FROST HOLLOW DEPTHS")
                    .font(.system(size: 19, weight: .heavy, design: .serif))
                    .tracking(3)
                    .foregroundColor(FHDTheme.ivory)
                Text("Descend. Survive the cold.")
                    .font(.system(size: 13, weight: .medium, design: .serif))
                    .foregroundColor(FHDTheme.frost.opacity(0.7))
            }
        }
        .onAppear { glow = true; spin = true }
    }
}
