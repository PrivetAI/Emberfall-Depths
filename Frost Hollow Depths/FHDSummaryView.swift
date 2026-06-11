import SwiftUI

// Death / victory summary after a run ends.
struct FHDSummaryView: View {
    @ObservedObject var engine: FHDEngine
    @EnvironmentObject var store: FHDStore
    @EnvironmentObject var nav: FHDNav
    @EnvironmentObject var holder: FHDEngineHolder

    var body: some View {
        let run = engine.run
        ScrollView {
            VStack(spacing: 16) {
                Spacer(minLength: 26)
                ZStack {
                    Circle()
                        .fill((run.victory ? FHDTheme.torch : FHDTheme.iceCyan).opacity(0.12))
                        .frame(width: 110, height: 110)
                    FHDGlyph(kind: run.victory ? .flame : .skull, size: 56,
                             color: run.victory ? FHDTheme.torch : FHDTheme.frost)
                }
                Text(run.victory ? "THE LONG THAW" : "FROZEN IN THE DARK")
                    .font(.system(size: 24, weight: .heavy, design: .serif))
                    .tracking(2)
                    .foregroundColor(run.victory ? FHDTheme.ember : FHDTheme.iceCyan)
                    .multilineTextAlignment(.center)
                Text(run.victory
                     ? "You reached the Heart of Winter and ended the eternal cold."
                     : lastCauseText())
                    .font(.system(size: 13, weight: .medium, design: .serif))
                    .foregroundColor(FHDTheme.textDim)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 26)

                if run.isDaily {
                    Text("DAILY RUN — \(FHDStore.dailyKey())")
                        .font(.system(size: 11, weight: .heavy))
                        .foregroundColor(FHDTheme.shard)
                        .padding(.horizontal, 10).padding(.vertical, 4)
                        .background(RoundedRectangle(cornerRadius: 6).stroke(FHDTheme.shard.opacity(0.6), lineWidth: 1))
                }

                // Stats grid
                VStack(spacing: 8) {
                    statRow("Class", run.hero.classID.name)
                    statRow("Deepest Floor", "\(run.deepestFloor) — \(FHDBiome.forFloor(run.deepestFloor).name)")
                    statRow("Enemies Slain", "\(run.kills)")
                    statRow("Gold Collected", "\(run.goldCollected)")
                    statRow("Turns Survived", "\(run.turnCount)")
                    statRow("Steps Taken", "\(run.stepsTaken)")
                    statRow("Items Used", "\(run.itemsUsed)")
                    statRow("Coldest Warmth", "\(run.coldestWarmth)")
                }
                .padding(14)
                .fhdCard()
                .padding(.horizontal, 20)

                // Shards earned (mirrors FHDStore.finishRun formula)
                HStack(spacing: 8) {
                    FHDGlyph(kind: .snow, size: 20, color: FHDTheme.shard)
                    Text("+\(shardsEarned()) Frost Shards banked")
                        .font(.system(size: 15, weight: .bold, design: .serif))
                        .foregroundColor(FHDTheme.shard)
                }
                .padding(.vertical, 10).padding(.horizontal, 18)
                .background(RoundedRectangle(cornerRadius: 12).fill(FHDTheme.shard.opacity(0.08))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(FHDTheme.shard.opacity(0.4), lineWidth: 1)))

                VStack(spacing: 10) {
                    Button {
                        holder.clear()
                        nav.screen = .metaHub
                    } label: { Text("Spend Shards — Frost Vault") }
                        .buttonStyle(FHDButtonStyle(tint: FHDTheme.iceCyan, filled: false))
                    Button {
                        holder.clear()
                        nav.screen = .classSelect(daily: false)
                    } label: { Text("Descend Again") }
                        .buttonStyle(FHDButtonStyle(tint: FHDTheme.torch))
                    Button {
                        holder.clear()
                        nav.screen = .title
                    } label: { Text("Return to Title") }
                        .buttonStyle(FHDButtonStyle(tint: FHDTheme.frost, filled: false))
                }
                .padding(.horizontal, 24)
                Spacer(minLength: 24)
            }
            .fhdFit()
            .frame(maxWidth: .infinity)
        }
    }

    private func lastCauseText() -> String {
        // The death log line carries the cause; fall back to a generic line.
        if let lastDanger = engine.run.log.last(where: { $0.tone == 3 && $0.text.hasPrefix("You have fallen") }) {
            return lastDanger.text + " The Hollow keeps what it takes — but the shards are yours."
        }
        return "The cold claimed another. The shards you carried out endure."
    }

    private func shardsEarned() -> Int {
        let run = engine.run
        return run.deepestFloor * 3 + run.kills + (run.victory ? 50 : 0) + (run.isDaily ? 10 : 0)
    }

    private func statRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).font(.system(size: 13, weight: .medium, design: .serif))
                .foregroundColor(FHDTheme.textDim)
            Spacer()
            Text(value).font(.system(size: 13, weight: .bold, design: .serif))
                .foregroundColor(FHDTheme.ivory)
                .multilineTextAlignment(.trailing)
        }
    }
}
