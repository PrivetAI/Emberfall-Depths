import SwiftUI

// Daily seeded run hub: one fixed-seed descent per UTC day.
struct FHDDailyView: View {
    @EnvironmentObject var store: FHDStore
    @EnvironmentObject var nav: FHDNav

    var body: some View {
        VStack(spacing: 0) {
            FHDHeaderBar(title: "Daily Run") { nav.screen = .title }
            ScrollView {
                VStack(spacing: 14) {
                    ZStack {
                        FHDSnowflakeShape()
                            .stroke(FHDTheme.shard.opacity(0.5), lineWidth: 2.5)
                            .frame(width: 86, height: 86)
                        FHDGlyph(kind: .stairs, size: 34, color: FHDTheme.shard)
                    }
                    .padding(.top, 18)

                    Text("Descent of \(FHDStore.dailyKey())")
                        .font(.system(size: 19, weight: .heavy, design: .serif))
                        .foregroundColor(FHDTheme.ivory)
                    Text("Everyone faces the same dungeon today. One fixed seed — the same floors, foes and unknown brews for all who descend. One attempt per day; +10 bonus shards for finishing it.")
                        .font(.system(size: 12, weight: .medium, design: .serif))
                        .foregroundColor(FHDTheme.textDim)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 26)

                    if let today = store.dailyResults.first(where: { $0.dateKey == FHDStore.dailyKey() }) {
                        VStack(spacing: 8) {
                            Text("TODAY'S DESCENT COMPLETE")
                                .font(.system(size: 11, weight: .heavy))
                                .tracking(1)
                                .foregroundColor(today.victory ? FHDTheme.ember : FHDTheme.iceCyan)
                            HStack(spacing: 18) {
                                resultStat("Floor", "\(today.floor)")
                                resultStat("Kills", "\(today.kills)")
                                resultStat("Outcome", today.victory ? "Victory" : "Fallen")
                            }
                            Text("Return tomorrow for a fresh seed.")
                                .font(.system(size: 11)).foregroundColor(FHDTheme.textDim)
                        }
                        .padding(16)
                        .fhdCard(raised: true)
                        .padding(.horizontal, 20)
                    } else {
                        Button {
                            nav.screen = .classSelect(daily: true)
                        } label: {
                            HStack {
                                FHDGlyph(kind: .snow, size: 16, color: FHDTheme.abyss)
                                Text("Begin Today's Descent")
                            }
                        }
                        .buttonStyle(FHDButtonStyle(tint: FHDTheme.iceCyan))
                        .padding(.horizontal, 24)
                        .padding(.top, 4)
                    }

                    if !store.dailyResults.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("PAST DAILIES")
                                .font(.system(size: 11, weight: .heavy))
                                .tracking(1)
                                .foregroundColor(FHDTheme.textDim)
                            ForEach(store.dailyResults) { r in
                                HStack {
                                    FHDGlyph(kind: r.victory ? .star : .skull, size: 16,
                                             color: r.victory ? FHDTheme.gold : FHDTheme.frost)
                                    Text(r.dateKey)
                                        .font(.system(size: 13, weight: .semibold, design: .serif))
                                        .foregroundColor(FHDTheme.ivory)
                                    Spacer()
                                    Text("Floor \(r.floor) · \(r.kills) kills")
                                        .font(.system(size: 12))
                                        .foregroundColor(FHDTheme.textDim)
                                }
                                .padding(.vertical, 8).padding(.horizontal, 12)
                                .fhdCard()
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                    }
                    Spacer(minLength: 24)
                }
                .fhdFit()
                .frame(maxWidth: .infinity)
            }
        }
    }

    private func resultStat(_ label: String, _ value: String) -> some View {
        VStack(spacing: 3) {
            Text(value).font(.system(size: 16, weight: .bold, design: .serif)).foregroundColor(FHDTheme.ivory)
            Text(label).font(.system(size: 10)).foregroundColor(FHDTheme.textDim)
        }
    }
}
