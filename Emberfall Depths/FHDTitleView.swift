import SwiftUI

struct FHDTitleView: View {
    @EnvironmentObject var store: FHDStore
    @EnvironmentObject var nav: FHDNav
    @EnvironmentObject var holder: FHDEngineHolder
    @State private var flicker = false

    var hasResume: Bool { store.activeRun?.alive == true }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                Spacer(minLength: 28)
                // Emblem
                ZStack {
                    FHDSnowflakeShape()
                        .stroke(FHDTheme.iceCyan.opacity(0.45), lineWidth: 3)
                        .frame(width: 120, height: 120)
                    FHDFlameShape()
                        .fill(FHDTheme.warmGradient)
                        .frame(width: 46, height: 64)
                        .shadow(color: FHDTheme.torch.opacity(flicker ? 0.9 : 0.5), radius: flicker ? 20 : 8)
                }
                .padding(.bottom, 4)

                Text("EMBERFALL")
                    .font(.system(size: 30, weight: .heavy, design: .serif))
                    .tracking(4)
                    .foregroundColor(FHDTheme.ivory)
                Text("D E P T H S")
                    .font(.system(size: 18, weight: .bold, design: .serif))
                    .tracking(8)
                    .foregroundColor(FHDTheme.torch)

                HStack(spacing: 14) {
                    statChip(label: "Shards", value: "\(store.shards)", glyph: .snow, color: FHDTheme.shard)
                    statChip(label: "Best", value: store.bestFloor > 0 ? "F\(store.bestFloor)" : "—", glyph: .stairs, color: FHDTheme.frost)
                    statChip(label: "Wins", value: "\(store.totalWins)", glyph: .star, color: FHDTheme.gold)
                }
                .padding(.vertical, 6)

                VStack(spacing: 11) {
                    if hasResume, let r = store.activeRun {
                        Button {
                            holder.resume(run: r, store: store)
                            nav.screen = .game
                        } label: {
                            HStack {
                                FHDGlyph(kind: .stairs, size: 16, color: FHDTheme.abyss)
                                Text("Resume — Floor \(r.floor)")
                            }
                        }
                        .buttonStyle(FHDButtonStyle(tint: FHDTheme.ember))
                    }

                    Button {
                        nav.screen = .classSelect(daily: false)
                    } label: { Text(hasResume ? "New Descent" : "Begin Descent") }
                        .buttonStyle(FHDButtonStyle(tint: FHDTheme.torch))

                    Button { nav.screen = .daily } label: { Text("Daily Run") }
                        .buttonStyle(FHDButtonStyle(tint: FHDTheme.iceCyan, filled: false))

                    Button { nav.screen = .metaHub } label: { Text("Frost Vault") }
                        .buttonStyle(FHDButtonStyle(tint: FHDTheme.frost, filled: false))

                    HStack(spacing: 11) {
                        Button { nav.screen = .codex } label: { Text("Codex") }
                            .buttonStyle(FHDButtonStyle(tint: FHDTheme.frost, filled: false))
                        Button { nav.screen = .achievements } label: { Text("Awards") }
                            .buttonStyle(FHDButtonStyle(tint: FHDTheme.frost, filled: false))
                    }
                    HStack(spacing: 11) {
                        Button { nav.screen = .history } label: { Text("History") }
                            .buttonStyle(FHDButtonStyle(tint: FHDTheme.frost, filled: false))
                        Button { nav.screen = .settings } label: { Text("Settings") }
                            .buttonStyle(FHDButtonStyle(tint: FHDTheme.frost, filled: false))
                    }
                }
                .padding(.horizontal, 24)

                Text("Descend 30 floors. Hold back the cold.")
                    .font(.system(size: 12, weight: .medium, design: .serif))
                    .foregroundColor(FHDTheme.textDim)
                    .padding(.top, 4)
                Spacer(minLength: 24)
            }
            .fhdFit()
            .frame(maxWidth: .infinity)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) { flicker = true }
        }
    }

    private func statChip(label: String, value: String, glyph: FHDGlyph.Kind, color: Color) -> some View {
        VStack(spacing: 4) {
            FHDGlyph(kind: glyph, size: 18, color: color)
            Text(value).font(.system(size: 15, weight: .bold, design: .serif)).foregroundColor(FHDTheme.ivory)
            Text(label).font(.system(size: 10)).foregroundColor(FHDTheme.textDim)
        }
        .frame(width: 76, height: 70)
        .fhdCard()
    }
}
