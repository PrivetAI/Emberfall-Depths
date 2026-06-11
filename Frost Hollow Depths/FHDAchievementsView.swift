import SwiftUI

// Achievements list ("Awards" on the title screen).
struct FHDAchievementsView: View {
    @EnvironmentObject var store: FHDStore
    @EnvironmentObject var nav: FHDNav

    var body: some View {
        VStack(spacing: 0) {
            FHDHeaderBar(title: "Awards",
                         trailing: AnyView(counter)) { nav.screen = .title }
            ScrollView {
                VStack(spacing: 7) {
                    ForEach(FHDAchID.allCases, id: \.self) { ach in
                        row(ach, unlocked: store.achievements.contains(ach))
                    }
                    Spacer(minLength: 24)
                }
                .padding(16)
                .fhdFit()
                .frame(maxWidth: .infinity)
            }
        }
    }

    private var counter: some View {
        Text("\(store.achievements.count) / \(FHDAchID.allCases.count)")
            .font(.system(size: 13, weight: .heavy, design: .rounded))
            .foregroundColor(FHDTheme.gold)
            .padding(.horizontal, 10).padding(.vertical, 5)
            .background(RoundedRectangle(cornerRadius: 9).fill(FHDTheme.panel))
    }

    private func row(_ ach: FHDAchID, unlocked: Bool) -> some View {
        HStack(spacing: 11) {
            ZStack {
                Circle()
                    .fill((unlocked ? FHDTheme.gold : FHDTheme.stroke).opacity(0.13))
                    .frame(width: 42, height: 42)
                FHDGlyph(kind: .star, size: 22,
                         color: unlocked ? FHDTheme.gold : FHDTheme.stroke)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(ach.title)
                    .font(.system(size: 14, weight: .bold, design: .serif))
                    .foregroundColor(unlocked ? FHDTheme.ivory : FHDTheme.textDim)
                Text(ach.detail)
                    .font(.system(size: 11))
                    .foregroundColor(unlocked ? FHDTheme.textDim : FHDTheme.stroke)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
            if unlocked {
                FHDGlyph(kind: .flame, size: 15, color: FHDTheme.torch)
            }
        }
        .padding(10)
        .fhdCard(raised: unlocked)
    }
}
