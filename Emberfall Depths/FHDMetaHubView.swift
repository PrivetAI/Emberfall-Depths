import SwiftUI

// Frost Vault: spend Frost Shards on permanent unlocks.
struct FHDMetaHubView: View {
    @EnvironmentObject var store: FHDStore
    @EnvironmentObject var nav: FHDNav

    private let classNodes: [FHDUnlockID] = [.classPyre, .classWitch, .classTinker]
    private let boonNodes: [FHDUnlockID] = [.warmthCap1, .warmthCap2, .startHeal, .startTorch,
                                            .startArmor, .insulation1, .lightBoost]
    private let loreNodes: [FHDUnlockID] = [.codexPage1, .codexPage2]

    var body: some View {
        VStack(spacing: 0) {
            FHDHeaderBar(title: "Frost Vault",
                         trailing: AnyView(shardChip)) { nav.screen = .title }
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Frost Shards endure beyond death. Trade them for classes, boons and lore that persist across every descent.")
                        .font(.system(size: 12, weight: .medium, design: .serif))
                        .foregroundColor(FHDTheme.textDim)
                        .padding(.top, 10)

                    sectionHeader("CLASSES")
                    ForEach(classNodes, id: \.self) { unlockCard($0) }

                    sectionHeader("PERMANENT BOONS")
                    ForEach(boonNodes, id: \.self) { unlockCard($0) }

                    sectionHeader("LORE")
                    ForEach(loreNodes, id: \.self) { unlockCard($0) }

                    Spacer(minLength: 24)
                }
                .padding(.horizontal, 18)
                .fhdFit()
                .frame(maxWidth: .infinity)
            }
        }
    }

    private var shardChip: some View {
        HStack(spacing: 5) {
            FHDGlyph(kind: .snow, size: 14, color: FHDTheme.shard)
            Text("\(store.shards)")
                .font(.system(size: 14, weight: .heavy, design: .rounded))
                .foregroundColor(FHDTheme.ivory)
        }
        .padding(.horizontal, 10).padding(.vertical, 5)
        .background(RoundedRectangle(cornerRadius: 9).fill(FHDTheme.panel))
    }

    private func sectionHeader(_ t: String) -> some View {
        Text(t)
            .font(.system(size: 11, weight: .heavy)).tracking(1.5)
            .foregroundColor(FHDTheme.frost)
            .padding(.top, 6)
    }

    private func unlockCard(_ u: FHDUnlockID) -> some View {
        let owned = store.unlocks.contains(u)
        let affordable = store.canAfford(u)
        return HStack(spacing: 11) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill((owned ? FHDTheme.torch : FHDTheme.frost).opacity(0.12))
                    .frame(width: 44, height: 44)
                FHDGlyph(kind: glyph(u), size: 24, color: owned ? FHDTheme.torch : FHDTheme.frost)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(u.title)
                    .font(.system(size: 14, weight: .bold, design: .serif))
                    .foregroundColor(FHDTheme.ivory)
                Text(u.detail)
                    .font(.system(size: 11))
                    .foregroundColor(FHDTheme.textDim)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
            if owned {
                Text("OWNED")
                    .font(.system(size: 10, weight: .heavy))
                    .foregroundColor(FHDTheme.torch)
                    .padding(.horizontal, 8).padding(.vertical, 5)
                    .background(RoundedRectangle(cornerRadius: 7).stroke(FHDTheme.torch.opacity(0.7), lineWidth: 1))
            } else {
                Button { store.buy(u) } label: {
                    HStack(spacing: 4) {
                        FHDGlyph(kind: .snow, size: 11, color: affordable ? FHDTheme.abyss : FHDTheme.textDim)
                        Text("\(u.cost)")
                            .font(.system(size: 13, weight: .heavy, design: .rounded))
                            .foregroundColor(affordable ? FHDTheme.abyss : FHDTheme.textDim)
                    }
                    .padding(.horizontal, 12).padding(.vertical, 8)
                    .background(RoundedRectangle(cornerRadius: 9)
                        .fill(affordable ? FHDTheme.shard : FHDTheme.panel))
                }
                .disabled(!affordable)
            }
        }
        .padding(11)
        .fhdCard(raised: owned)
    }

    private func glyph(_ u: FHDUnlockID) -> FHDGlyph.Kind {
        switch u {
        case .classPyre: return .flame
        case .classWitch: return .wand
        case .classTinker: return .gear
        case .warmthCap1, .warmthCap2: return .flame
        case .startHeal: return .potion
        case .startTorch: return .flame
        case .startArmor: return .shield
        case .insulation1: return .shield
        case .lightBoost: return .eye
        case .codexPage1, .codexPage2: return .scroll
        }
    }
}
