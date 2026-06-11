import SwiftUI

// Codex: bestiary, item compendium, and unlockable lore pages.
struct FHDCodexView: View {
    @EnvironmentObject var store: FHDStore
    @EnvironmentObject var nav: FHDNav
    @State private var tab = 0   // 0 bestiary, 1 items, 2 lore

    var body: some View {
        VStack(spacing: 0) {
            FHDHeaderBar(title: "Codex") { nav.screen = .title }
            // segment switch (custom, no system components)
            HStack(spacing: 8) {
                segButton("Bestiary", 0)
                segButton("Items", 1)
                segButton("Lore", 2)
            }
            .padding(.horizontal, 16).padding(.vertical, 10)

            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    switch tab {
                    case 0: bestiary
                    case 1: itemCompendium
                    default: lorePages
                    }
                    Spacer(minLength: 24)
                }
                .padding(.horizontal, 16)
                .fhdFit()
                .frame(maxWidth: .infinity)
            }
        }
    }

    private func segButton(_ label: String, _ idx: Int) -> some View {
        Button { tab = idx } label: {
            Text(label)
                .font(.system(size: 13, weight: .bold, design: .serif))
                .foregroundColor(tab == idx ? FHDTheme.abyss : FHDTheme.frost)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(RoundedRectangle(cornerRadius: 10)
                    .fill(tab == idx ? FHDTheme.frost : FHDTheme.panel))
        }
    }

    // MARK: - Bestiary

    private var bestiary: some View {
        let discovered = store.discoveredEnemies
        return VStack(alignment: .leading, spacing: 8) {
            Text("\(discovered.count) / \(FHDBestiary.list.count) catalogued — defeat a creature to record it.")
                .font(.system(size: 11)).foregroundColor(FHDTheme.textDim)
            ForEach(FHDBestiary.list, id: \.id) { def in
                bestiaryRow(def, known: discovered.contains(def.id))
            }
        }
    }

    private func bestiaryRow(_ def: FHDEnemyDef, known: Bool) -> some View {
        HStack(spacing: 11) {
            ZStack {
                Circle().fill(rowColor(def, known: known).opacity(0.13)).frame(width: 42, height: 42)
                if known {
                    FHDGlyph(kind: enemyGlyph(def), size: 22, color: rowColor(def, known: true))
                } else {
                    Text("?").font(.system(size: 18, weight: .heavy, design: .serif))
                        .foregroundColor(FHDTheme.stroke)
                }
            }
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(known ? def.name : "Unknown Creature")
                        .font(.system(size: 14, weight: .bold, design: .serif))
                        .foregroundColor(known ? FHDTheme.ivory : FHDTheme.stroke)
                    if def.isBoss && known {
                        Text("BOSS").font(.system(size: 8, weight: .heavy))
                            .foregroundColor(FHDTheme.danger)
                            .padding(.horizontal, 4).padding(.vertical, 2)
                            .background(RoundedRectangle(cornerRadius: 4).stroke(FHDTheme.danger, lineWidth: 1))
                    }
                }
                if known {
                    Text("HP \(def.maxHP) · DMG \(def.damage) · DEF \(def.defense)\(def.warmthDrain > 0 ? " · drains warmth" : "")")
                        .font(.system(size: 10)).foregroundColor(FHDTheme.frost)
                    Text(def.desc).font(.system(size: 10)).foregroundColor(FHDTheme.textDim)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    Text("Slay one to learn its nature.")
                        .font(.system(size: 10)).foregroundColor(FHDTheme.stroke)
                }
            }
            Spacer()
        }
        .padding(10)
        .fhdCard()
    }

    private func rowColor(_ def: FHDEnemyDef, known: Bool) -> Color {
        if !known { return FHDTheme.stroke }
        if def.isBoss { return FHDTheme.danger }
        switch def.affinity {
        case .fire: return FHDTheme.torch
        case .frost: return FHDTheme.iceCyan
        case .neutral: return FHDTheme.ivory
        }
    }

    private func enemyGlyph(_ def: FHDEnemyDef) -> FHDGlyph.Kind {
        switch def.glyph {
        case .skull: return .skull
        case .snow: return .snow
        case .shield: return .shield
        case .flame: return .flame
        case .gear: return .gear
        case .wand: return .wand
        case .star: return .star
        case .chest: return .chest
        case .ring: return .ring
        case .sword: return .sword
        case .heart: return .heart
        default: return .skull
        }
    }

    // MARK: - Item compendium

    private var itemCompendium: some View {
        let groups: [(String, [FHDItemDef])] = [
            ("WEAPONS", FHDCatalog.weapons),
            ("ARMOR", FHDCatalog.armors),
            ("POTIONS", FHDCatalog.potions),
            ("SCROLLS", FHDCatalog.scrolls),
            ("RINGS", FHDCatalog.rings),
            ("WANDS", FHDCatalog.wands),
            ("THROWABLES", FHDCatalog.throwables),
            ("PROVISIONS", FHDCatalog.foods),
        ]
        return VStack(alignment: .leading, spacing: 8) {
            Text("\(store.discoveredItems.count) item kinds found across all runs.")
                .font(.system(size: 11)).foregroundColor(FHDTheme.textDim)
            ForEach(groups, id: \.0) { group in
                Text(group.0)
                    .font(.system(size: 11, weight: .heavy)).tracking(1.5)
                    .foregroundColor(FHDTheme.frost)
                    .padding(.top, 6)
                ForEach(group.1, id: \.id) { def in
                    itemRow(def, found: store.discoveredItems.contains(def.id))
                }
            }
        }
    }

    private func itemRow(_ def: FHDItemDef, found: Bool) -> some View {
        HStack(spacing: 10) {
            FHDGlyph(kind: itemGlyph(def), size: 18,
                     color: found ? FHDTheme.gold : FHDTheme.stroke)
                .frame(width: 26)
            VStack(alignment: .leading, spacing: 1) {
                Text(found ? def.name : "Undiscovered")
                    .font(.system(size: 13, weight: .bold, design: .serif))
                    .foregroundColor(found ? FHDTheme.ivory : FHDTheme.stroke)
                Text(found ? def.desc : "Find one in the depths to record it.")
                    .font(.system(size: 10))
                    .foregroundColor(found ? FHDTheme.textDim : FHDTheme.stroke)
                    .lineLimit(2)
            }
            Spacer()
        }
        .padding(.vertical, 7).padding(.horizontal, 10)
        .fhdCard()
    }

    private func itemGlyph(_ def: FHDItemDef) -> FHDGlyph.Kind {
        switch def.glyph {
        case .sword: return .sword
        case .shield: return .shield
        case .potion: return .potion
        case .scroll: return .scroll
        case .ring: return .ring
        case .wand: return .wand
        case .flame: return .flame
        case .key: return .key
        case .heart: return .heart
        case .boot: return .boot
        case .gear: return .gear
        case .chest: return .chest
        case .bag: return .bag
        case .snow: return .snow
        case .star: return .star
        case .skull: return .skull
        }
    }

    // MARK: - Lore

    private var lorePages: some View {
        VStack(alignment: .leading, spacing: 10) {
            loreCard(title: "The Long Winter", unlocked: true, body:
                "Three hundred years ago the sun dimmed over the valley, and the cold that came up from the Hollow never left. The townsfolk burned what they had, then what they loved, then they went down — for the old shafts breathe heat from the world's heart, and heat means another day.")
            loreCard(title: "The Frostgate", unlocked: true, body:
                "The first wardens sealed the upper halls against what climbed out of the dark. Their gate still stands. Their bones still man it.")
            loreCard(title: "The Glacier Cells", unlocked: store.unlocks.contains(.codexPage1), body:
                "Not a prison for people — a prison for warmth. The jailers learned to freeze a flame mid-flicker and lock it in ice. Some cells still hold light that is centuries old, beating like a heart against the glass.")
            loreCard(title: "The Geothermal Forge", unlocked: store.unlocks.contains(.codexPage1), body:
                "Smiths followed the heat down and built a forge on the magma's shoulder. They made blades that never cool — and woke something in the fire that liked being worshipped.")
            loreCard(title: "The Whiteout", unlocked: store.unlocks.contains(.codexPage2), body:
                "Below the crystal dark, the blizzard blows INDOORS. There is no sky down there, yet the snow falls upward and sideways and through. The King who walked into it never came out, and now it has a crown.")
            loreCard(title: "Hibernal", unlocked: store.unlocks.contains(.codexPage2), body:
                "The Heart of Winter is not a beast but a wound — the place where the world's warmth bleeds out. Hibernal is the scar that grew around it. End it, and the long thaw begins.")
        }
    }

    private func loreCard(title: String, unlocked: Bool, body text: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 7) {
                FHDGlyph(kind: .scroll, size: 15, color: unlocked ? FHDTheme.ember : FHDTheme.stroke)
                Text(unlocked ? title : "Sealed Page")
                    .font(.system(size: 14, weight: .bold, design: .serif))
                    .foregroundColor(unlocked ? FHDTheme.ivory : FHDTheme.stroke)
            }
            Text(unlocked ? text : "Unlock Codex lore in the Frost Vault to read this page.")
                .font(.system(size: 12, weight: .medium, design: .serif))
                .foregroundColor(unlocked ? FHDTheme.textDim : FHDTheme.stroke)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .fhdCard()
    }
}
