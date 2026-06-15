import SwiftUI

// Run history + lifetime statistics.
struct FHDHistoryView: View {
    @EnvironmentObject var store: FHDStore
    @EnvironmentObject var nav: FHDNav

    var body: some View {
        VStack(spacing: 0) {
            FHDHeaderBar(title: "Run History") { nav.screen = .title }
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    statsPanel
                    Text("PAST DESCENTS")
                        .font(.system(size: 11, weight: .heavy)).tracking(1.5)
                        .foregroundColor(FHDTheme.frost)
                        .padding(.top, 4)
                    if store.history.isEmpty {
                        Text("No descents recorded yet. The Hollow waits.")
                            .font(.system(size: 12, weight: .medium, design: .serif))
                            .foregroundColor(FHDTheme.textDim)
                            .padding(.top, 8)
                    } else {
                        ForEach(store.history) { rec in
                            recordRow(rec)
                        }
                    }
                    Spacer(minLength: 24)
                }
                .padding(16)
                .fhdFit()
                .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Lifetime stats

    private var statsPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("LIFETIME STATISTICS")
                .font(.system(size: 11, weight: .heavy)).tracking(1.5)
                .foregroundColor(FHDTheme.frost)
            HStack(spacing: 8) {
                statBox("Runs", "\(store.totalRuns)", .stairs, FHDTheme.frost)
                statBox("Wins", "\(store.totalWins)", .star, FHDTheme.gold)
                statBox("Best Floor", store.bestFloor > 0 ? "\(store.bestFloor)" : "—", .stairs, FHDTheme.ember)
            }
            HStack(spacing: 8) {
                statBox("Kills", "\(store.totalKills)", .skull, FHDTheme.danger)
                statBox("Gold", "\(store.totalGold)", .star, FHDTheme.gold)
                statBox("Turns", "\(store.totalTurns)", .heart, FHDTheme.poison)
            }
            HStack(spacing: 8) {
                statBox("Shards", "\(store.shards)", .snow, FHDTheme.shard)
                statBox("Codex", "\(store.discoveredEnemies.count)/\(FHDBestiary.list.count)", .eye, FHDTheme.iceCyan)
                statBox("Awards", "\(store.achievements.count)/\(FHDAchID.allCases.count)", .flame, FHDTheme.torch)
            }
        }
        .padding(12)
        .fhdCard(raised: true)
    }

    private func statBox(_ label: String, _ value: String, _ glyph: FHDGlyph.Kind, _ color: Color) -> some View {
        VStack(spacing: 4) {
            FHDGlyph(kind: glyph, size: 16, color: color)
            Text(value)
                .font(.system(size: 14, weight: .heavy, design: .rounded))
                .foregroundColor(FHDTheme.ivory)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(label).font(.system(size: 9)).foregroundColor(FHDTheme.textDim)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 9)
        .background(RoundedRectangle(cornerRadius: 10).fill(FHDTheme.abyss.opacity(0.5)))
    }

    // MARK: - Record rows

    private func recordRow(_ rec: FHDRunRecord) -> some View {
        HStack(spacing: 11) {
            ZStack {
                Circle()
                    .fill((rec.victory ? FHDTheme.gold : FHDTheme.frost).opacity(0.13))
                    .frame(width: 40, height: 40)
                FHDGlyph(kind: rec.victory ? .star : .skull, size: 20,
                         color: rec.victory ? FHDTheme.gold : FHDTheme.frost)
            }
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(rec.victory ? "Victory — \(rec.classID.name)" : "\(rec.classID.name), Floor \(rec.floor)")
                        .font(.system(size: 13, weight: .bold, design: .serif))
                        .foregroundColor(FHDTheme.ivory)
                    if rec.isDaily {
                        Text("DAILY").font(.system(size: 8, weight: .heavy))
                            .foregroundColor(FHDTheme.shard)
                            .padding(.horizontal, 4).padding(.vertical, 2)
                            .background(RoundedRectangle(cornerRadius: 4).stroke(FHDTheme.shard, lineWidth: 1))
                    }
                }
                Text(rec.victory ? "Ended the long winter" : "Fell to \(rec.cause)")
                    .font(.system(size: 10)).foregroundColor(FHDTheme.textDim)
                Text("\(rec.kills) kills · \(rec.gold) gold · \(rec.turns) turns · \(dateText(rec.date))")
                    .font(.system(size: 9)).foregroundColor(FHDTheme.stroke)
            }
            Spacer()
        }
        .padding(10)
        .fhdCard()
    }

    private func dateText(_ d: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f.string(from: d)
    }
}
