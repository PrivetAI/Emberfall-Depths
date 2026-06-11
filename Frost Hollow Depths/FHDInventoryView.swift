import SwiftUI

// Inventory sheet: equipment slots, item list, and an item detail panel
// with Use / Equip / Throw / Zap / Drop actions.
struct FHDInventoryView: View {
    @ObservedObject var engine: FHDEngine
    @Binding var isShown: Bool
    @EnvironmentObject var store: FHDStore
    @State private var selectedID: UUID? = nil

    var body: some View {
        ZStack {
            FHDTheme.abyss.edgesIgnoringSafeArea(.all)
            VStack(spacing: 0) {
                // header
                HStack {
                    Text("Pack")
                        .font(.system(size: 19, weight: .heavy, design: .serif))
                        .foregroundColor(FHDTheme.ivory)
                    Text("\(engine.run.inventory.count) items · \(engine.run.hero.gold) gold · \(engine.run.hero.keys) keys")
                        .font(.system(size: 11)).foregroundColor(FHDTheme.textDim)
                    Spacer()
                    Button { isShown = false } label: {
                        ZStack {
                            Circle().fill(FHDTheme.panelRaised).frame(width: 32, height: 32)
                            FHDGlyph(kind: .cross, size: 13, color: FHDTheme.ivory)
                        }
                    }
                }
                .padding(.horizontal, 16).padding(.vertical, 12)
                .background(FHDTheme.deepBlue)

                ScrollView {
                    VStack(spacing: 12) {
                        equipmentPanel
                        if engine.run.inventory.isEmpty {
                            Text("Your pack is empty. The depths provide — keep descending.")
                                .font(.system(size: 12, weight: .medium, design: .serif))
                                .foregroundColor(FHDTheme.textDim)
                                .padding(.top, 24)
                        } else {
                            VStack(spacing: 6) {
                                ForEach(engine.run.inventory) { item in
                                    itemRow(item)
                                }
                            }
                        }
                        Spacer(minLength: 12)
                    }
                    .padding(14)
                    .fhdFit()
                    .frame(maxWidth: .infinity)
                }

                if let item = selectedItem {
                    detailPanel(item)
                }
            }
        }
        .onAppear { store.packedCheck(engine.run.inventory.count) }
    }

    private var selectedItem: FHDItem? {
        guard let id = selectedID else { return nil }
        return engine.run.inventory.first(where: { $0.id == id })
    }

    // MARK: - Equipment

    private var equipmentPanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("EQUIPPED")
                .font(.system(size: 11, weight: .heavy)).tracking(1)
                .foregroundColor(FHDTheme.textDim)
            slotRow("Weapon", item: engine.run.hero.weapon, glyph: .sword, slot: 0)
            slotRow("Armor", item: engine.run.hero.armor, glyph: .shield, slot: 1)
            slotRow("Ring", item: engine.run.hero.ringA, glyph: .ring, slot: 2)
            slotRow("Ring", item: engine.run.hero.ringB, glyph: .ring, slot: 3)
            slotRow("Torch", item: engine.run.hero.torch, glyph: .flame, slot: 4)
        }
        .padding(12)
        .fhdCard(raised: true)
    }

    private func slotRow(_ label: String, item: FHDItem?, glyph: FHDGlyph.Kind, slot: Int) -> some View {
        HStack(spacing: 9) {
            FHDGlyph(kind: glyph, size: 17, color: item == nil ? FHDTheme.stroke : FHDTheme.torch)
            Text(label).font(.system(size: 11, weight: .semibold))
                .foregroundColor(FHDTheme.textDim)
                .frame(width: 52, alignment: .leading)
            if let it = item {
                Text(slotTitle(it, slot: slot))
                    .font(.system(size: 13, weight: .bold, design: .serif))
                    .foregroundColor(FHDTheme.ivory)
                    .lineLimit(1)
                Spacer()
                Button {
                    engine.unequip(slot: slot)
                } label: {
                    Text("Remove")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(FHDTheme.frost)
                        .padding(.horizontal, 9).padding(.vertical, 5)
                        .background(RoundedRectangle(cornerRadius: 7).stroke(FHDTheme.frost.opacity(0.6), lineWidth: 1))
                }
            } else {
                Text("— empty —").font(.system(size: 12, design: .serif)).foregroundColor(FHDTheme.stroke)
                Spacer()
            }
        }
    }

    private func slotTitle(_ item: FHDItem, slot: Int) -> String {
        var n = engine.run.displayName(item)
        if slot == 4 { n += " (fuel \(item.fuel))" }
        return n
    }

    // MARK: - Item list

    private func itemRow(_ item: FHDItem) -> some View {
        let def = FHDCatalog.def(item.defID)
        let isSel = selectedID == item.id
        return Button {
            selectedID = isSel ? nil : item.id
        } label: {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8).fill(categoryColor(def).opacity(0.13))
                        .frame(width: 38, height: 38)
                    FHDGlyph(kind: glyphFor(def), size: 20, color: categoryColor(def))
                }
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 5) {
                        Text(engine.run.displayName(item))
                            .font(.system(size: 14, weight: .bold, design: .serif))
                            .foregroundColor(FHDTheme.ivory)
                            .lineLimit(1)
                        if item.quantity > 1 {
                            Text("x\(item.quantity)")
                                .font(.system(size: 11, weight: .heavy, design: .rounded))
                                .foregroundColor(FHDTheme.gold)
                        }
                    }
                    Text(statLine(item, def: def))
                        .font(.system(size: 10))
                        .foregroundColor(FHDTheme.textDim)
                        .lineLimit(1)
                }
                Spacer()
                FHDChevronShape(dir: isSel ? 1 : 3)
                    .frame(width: 11, height: 11)
                    .foregroundColor(FHDTheme.stroke)
            }
            .padding(9)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSel ? FHDTheme.panelRaised : FHDTheme.panel)
                    .overlay(RoundedRectangle(cornerRadius: 12)
                        .stroke(isSel ? FHDTheme.torch.opacity(0.7) : FHDTheme.stroke.opacity(0.5), lineWidth: 1))
            )
        }
        .buttonStyle(.plain)
    }

    private func statLine(_ item: FHDItem, def: FHDItemDef) -> String {
        switch def.category {
        case .weapon:
            var s = "Damage \(def.power + item.upgrade * 2)"
            if def.wandRange > 0 { s += " · range \(def.wandRange)" }
            if def.emitsWarmth > 0 { s += " · +\(def.emitsWarmth) warmth/turn" }
            return s
        case .armor:
            return "Defense \(def.power + item.upgrade) · insulation \(def.insulation + item.upgrade)"
        case .potion:
            return engine.run.identifiedPotion.contains(def.id) ? def.desc : "Unidentified brew. Drink to learn it."
        case .scroll:
            return engine.run.identifiedScroll.contains(def.id) ? def.desc : "Unread runes. Read to learn them."
        case .ring: return def.desc
        case .wand: return "\(def.desc) Charges: \(item.chargesLeft)"
        case .throwable: return def.desc
        case .food: return def.desc
        case .torch: return "Burn time \(item.fuel > 0 ? item.fuel : 90). Light and warmth."
        case .fuel: return "Refills your lit torch."
        default: return def.desc
        }
    }

    // MARK: - Detail / actions

    private func detailPanel(_ item: FHDItem) -> some View {
        let def = FHDCatalog.def(item.defID)
        return VStack(alignment: .leading, spacing: 9) {
            Text(engine.run.displayName(item))
                .font(.system(size: 16, weight: .heavy, design: .serif))
                .foregroundColor(FHDTheme.ivory)
            Text(statLine(item, def: def))
                .font(.system(size: 11, weight: .medium, design: .serif))
                .foregroundColor(FHDTheme.textDim)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 8) {
                ForEach(actions(for: def), id: \.0) { action in
                    Button {
                        perform(action.0, on: item)
                    } label: {
                        Text(action.0)
                            .font(.system(size: 13, weight: .bold, design: .serif))
                            .foregroundColor(FHDTheme.abyss)
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity)
                            .background(RoundedRectangle(cornerRadius: 10).fill(action.1))
                    }
                }
                Button {
                    engine.drop(item)
                    selectedID = nil
                } label: {
                    Text("Drop")
                        .font(.system(size: 13, weight: .bold, design: .serif))
                        .foregroundColor(FHDTheme.danger)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        .background(RoundedRectangle(cornerRadius: 10).stroke(FHDTheme.danger.opacity(0.7), lineWidth: 1))
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(FHDTheme.deepBlue)
    }

    // (label, tint) pairs for the primary actions of this item category.
    private func actions(for def: FHDItemDef) -> [(String, Color)] {
        switch def.category {
        case .weapon, .armor, .ring, .torch: return [("Equip", FHDTheme.torch)]
        case .potion: return [("Drink", FHDTheme.poison)]
        case .scroll: return [("Read", FHDTheme.ivory)]
        case .food: return [("Eat", FHDTheme.ember)]
        case .fuel: return [("Refuel", FHDTheme.torch)]
        case .throwable: return [("Throw", FHDTheme.ember)]
        case .wand: return [("Zap", Color(red: 0.7, green: 0.6, blue: 1.0))]
        default: return []
        }
    }

    private func perform(_ label: String, on item: FHDItem) {
        guard engine.run.alive else { isShown = false; return }
        switch label {
        case "Equip": engine.equip(item)
        case "Drink", "Read", "Eat", "Refuel": engine.useItem(item)
        case "Throw": engine.throwItem(item)
        case "Zap": engine.zapWand(item)
        default: break
        }
        selectedID = nil
        // Turn-consuming actions hand the world a tick; close so the player sees it.
        isShown = false
    }

    // MARK: - Visual helpers

    private func glyphFor(_ def: FHDItemDef) -> FHDGlyph.Kind {
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

    private func categoryColor(_ def: FHDItemDef) -> Color {
        switch def.category {
        case .weapon: return def.affinity == .fire ? FHDTheme.torch : FHDTheme.frost
        case .armor: return FHDTheme.iceCyan
        case .potion: return FHDTheme.poison
        case .scroll: return FHDTheme.ivory
        case .ring: return FHDTheme.gold
        case .wand: return Color(red: 0.7, green: 0.6, blue: 1.0)
        case .throwable: return FHDTheme.ember
        case .food: return FHDTheme.blood
        case .torch, .fuel: return FHDTheme.torch
        default: return FHDTheme.ivory
        }
    }
}
