import SwiftUI

// MARK: - HUD (HP / Warmth / Light)

struct FHDHUDView: View {
    @ObservedObject var engine: FHDEngine
    var onMenu: () -> Void
    var onInventory: () -> Void

    var body: some View {
        let run = engine.run
        let warmCap = engine.effectiveWarmthCap()
        let warmFrac = Double(run.hero.warmth) / Double(max(1, warmCap))
        VStack(spacing: 6) {
            HStack(spacing: 10) {
                Button(action: onMenu) {
                    ZStack {
                        Circle().fill(FHDTheme.panelRaised).frame(width: 30, height: 30)
                        FHDChevronShape(dir: 2).frame(width: 13, height: 13).foregroundColor(FHDTheme.ivory)
                    }
                }
                VStack(alignment: .leading, spacing: 0) {
                    Text(run.biome.name).font(.system(size: 13, weight: .bold, design: .serif))
                        .foregroundColor(run.biome.accentColor)
                    Text("Floor \(run.floor) / 30").font(.system(size: 10)).foregroundColor(FHDTheme.textDim)
                }
                Spacer()
                hudChip(glyph: .star, value: "\(run.hero.gold)", color: FHDTheme.gold)
                hudChip(glyph: .snow, value: "\(run.hero.keys)", color: FHDTheme.frost)
                Button(action: onInventory) {
                    ZStack {
                        Circle().fill(FHDTheme.panelRaised).frame(width: 30, height: 30)
                        FHDGlyph(kind: .bag, size: 16, color: FHDTheme.ivory)
                    }
                }
            }
            // HP bar
            barRow(label: "HP", frac: Double(run.hero.hp)/Double(max(1, run.hero.maxHP)),
                   color: FHDTheme.hpColor(Double(run.hero.hp)/Double(max(1, run.hero.maxHP))),
                   text: "\(run.hero.hp)/\(run.hero.maxHP)", glyph: .heart)
            // Warmth bar (glows orange when warm, blue when cold)
            barRow(label: "Warmth", frac: warmFrac,
                   color: FHDTheme.warmthColor(warmFrac),
                   text: "\(run.hero.warmth)/\(warmCap)", glyph: .flame,
                   warning: run.hero.warmth <= 0)
            // Light + status row
            HStack(spacing: 8) {
                miniStat(glyph: .eye, label: "Light \(engine.lightRadius)", color: FHDTheme.frost)
                if let t = run.hero.torch {
                    miniStat(glyph: .flame, label: "Fuel \(t.fuel)", color: FHDTheme.torch)
                }
                Spacer()
                statusIcons
            }
        }
        .padding(.horizontal, 12).padding(.top, 6).padding(.bottom, 8)
        .background(FHDTheme.deepBlue.edgesIgnoringSafeArea(.top))
    }

    private var statusIcons: some View {
        HStack(spacing: 6) {
            if engine.run.hero.frostWard > 0 { statusDot("Ward", FHDTheme.iceCyan) }
            if engine.run.hero.fireImmunity > 0 { statusDot("Fire", FHDTheme.torch) }
            if engine.run.hero.haste > 0 { statusDot("Haste", FHDTheme.gold) }
            if engine.run.hero.levitation > 0 { statusDot("Float", FHDTheme.frost) }
            if engine.run.hero.regenTurns > 0 { statusDot("Regen", FHDTheme.poison) }
            if engine.run.hero.chill > 0 { statusDot("Chill", FHDTheme.iceCyan) }
            if engine.run.hero.poison > 0 { statusDot("Pois", FHDTheme.poison) }
        }
    }
    private func statusDot(_ t: String, _ c: Color) -> some View {
        Text(t).font(.system(size: 8, weight: .bold))
            .foregroundColor(c)
            .padding(.horizontal, 4).padding(.vertical, 2)
            .background(RoundedRectangle(cornerRadius: 4).fill(c.opacity(0.15)))
    }

    private func barRow(label: String, frac: Double, color: Color, text: String, glyph: FHDGlyph.Kind, warning: Bool = false) -> some View {
        HStack(spacing: 7) {
            FHDGlyph(kind: glyph, size: 14, color: color)
            GeometryReader { g in
                ZStack(alignment: .leading) {
                    Capsule().fill(FHDTheme.abyss)
                    Capsule().fill(color)
                        .frame(width: max(0, g.size.width * CGFloat(min(1, max(0, frac)))))
                    if warning {
                        Capsule().stroke(FHDTheme.danger, lineWidth: 1.5)
                    }
                }
            }
            .frame(height: 13)
            Text(text).font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundColor(FHDTheme.ivory).frame(width: 56, alignment: .trailing)
        }
    }

    private func hudChip(glyph: FHDGlyph.Kind, value: String, color: Color) -> some View {
        HStack(spacing: 3) {
            FHDGlyph(kind: glyph, size: 13, color: color)
            Text(value).font(.system(size: 12, weight: .bold, design: .rounded)).foregroundColor(FHDTheme.ivory)
        }
        .padding(.horizontal, 7).padding(.vertical, 4)
        .background(RoundedRectangle(cornerRadius: 7).fill(FHDTheme.panel))
    }

    private func miniStat(glyph: FHDGlyph.Kind, label: String, color: Color) -> some View {
        HStack(spacing: 3) {
            FHDGlyph(kind: glyph, size: 12, color: color)
            Text(label).font(.system(size: 10, weight: .medium)).foregroundColor(FHDTheme.textDim)
        }
    }
}

// MARK: - Controls (D-pad + actions). Proportional sizing for iPad safety.

struct FHDControlsView: View {
    @ObservedObject var engine: FHDEngine
    var onInventory: () -> Void
    var onExamine: () -> Void
    var onDescend: () -> Void
    var onRest: () -> Void

    var body: some View {
        GeometryReader { g in
            let vw = min(g.size.width, UIScreen.main.bounds.width)
            // Button size must fit BOTH the width (6 columns) AND the height (3 D-pad
            // rows + paddings), otherwise the D-pad overflows the controls frame and
            // spills onto the log strip below.
            let unit = max(34, min(52, min((vw - 40) / 6, (g.size.height - 24) / 3)))
            HStack(spacing: 14) {
                // action column
                VStack(spacing: 6) {
                    actionButton("Wait", glyph: .heart, color: FHDTheme.frost, size: unit) { onRest() }
                    actionButton("Look", glyph: .eye, color: engine.examineMode ? FHDTheme.ember : FHDTheme.frost, size: unit) { onExamine() }
                }
                Spacer()
                // D-pad
                dpad(unit: unit)
                Spacer()
                // right action column
                VStack(spacing: 6) {
                    if onStairs { actionButton("Down", glyph: .stairs, color: FHDTheme.ember, size: unit) { onDescend() } }
                    else if canFire { actionButton("Shoot", glyph: .sword, color: FHDTheme.torch, size: unit) { engine.fireBow() } }
                    else if engine.run.hero.classID == .tinker { actionButton("Build", glyph: .gear, color: FHDTheme.gold, size: unit) { engine.deployBrazier() } }
                    else { actionButton("Bag", glyph: .bag, color: FHDTheme.frost, size: unit) { onInventory() } }
                    actionButton("Bag", glyph: .bag, color: FHDTheme.frost, size: unit) { onInventory() }
                }
            }
            .frame(width: vw)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(height: 150)
    }

    private var onStairs: Bool {
        let t = engine.run.tiles[engine.run.hero.pos.y][engine.run.hero.pos.x].type
        return t == .stairsDown
    }
    private var canFire: Bool {
        if let w = engine.run.hero.weapon { return FHDCatalog.def(w.defID).wandRange > 0 }
        return false
    }

    private func dpad(unit: CGFloat) -> some View {
        VStack(spacing: 4) {
            arrow(.up, unit)
            HStack(spacing: 4) { arrow(.left, unit); Color.clear.frame(width: unit, height: unit); arrow(.right, unit) }
            arrow(.down, unit)
        }
    }
    private func arrow(_ dir: FHDDir, _ unit: CGFloat) -> some View {
        Button { engine.tryMove(dir) } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 9).fill(FHDTheme.panelRaised)
                FHDChevronShape(dir: chevDir(dir)).frame(width: unit*0.4, height: unit*0.4).foregroundColor(FHDTheme.ivory)
            }
            .frame(width: unit, height: unit)
        }
        .buttonStyle(.plain)
    }
    private func chevDir(_ d: FHDDir) -> Int {
        switch d { case .up: return 0; case .down: return 1; case .left: return 2; case .right: return 3 }
    }

    private func actionButton(_ label: String, glyph: FHDGlyph.Kind, color: Color, size: CGFloat, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 2) {
                FHDGlyph(kind: glyph, size: size*0.36, color: color)
                Text(label).font(.system(size: 8, weight: .bold)).foregroundColor(FHDTheme.textDim)
            }
            .frame(width: size, height: size*0.78)
            .background(RoundedRectangle(cornerRadius: 9).fill(FHDTheme.panel)
                .overlay(RoundedRectangle(cornerRadius: 9).stroke(color.opacity(0.4), lineWidth: 1)))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Log strip

struct FHDLogStrip: View {
    @ObservedObject var engine: FHDEngine
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(engine.run.log.suffix(20)) { entry in
                        Text(entry.text)
                            .font(.system(size: 11, weight: .medium, design: .serif))
                            .foregroundColor(logColor(entry.tone))
                            .id(entry.id)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(.horizontal, 12).padding(.vertical, 5)
            }
            .frame(height: 52)
            .background(FHDTheme.deepBlue.opacity(0.85).edgesIgnoringSafeArea(.bottom))
            .onChange(of: engine.run.log.count) { _ in
                if let last = engine.run.log.last { withAnimation { proxy.scrollTo(last.id, anchor: .bottom) } }
            }
        }
    }
    private func logColor(_ tone: Int) -> Color {
        switch tone {
        case 1: return FHDTheme.ember
        case 2: return FHDTheme.iceCyan
        case 3: return FHDTheme.danger
        case 4: return FHDTheme.poison
        default: return FHDTheme.textDim
        }
    }
}

// MARK: - Minimap

struct FHDMinimap: View {
    @ObservedObject var engine: FHDEngine
    var body: some View {
        let run = engine.run
        Canvas { ctx, size in
            ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .color(FHDTheme.abyss.opacity(0.85)))
            let w = run.tiles[0].count, h = run.tiles.count
            let cw = size.width / CGFloat(w), ch = size.height / CGFloat(h)
            for y in 0..<h {
                for x in 0..<w {
                    let t = run.tiles[y][x]
                    if !t.discovered { continue }
                    var c: Color = FHDTheme.stroke
                    switch t.type {
                    case .wall, .secretWall: c = FHDTheme.panel
                    case .stairsDown: c = FHDTheme.ember
                    case .brazier, .lava, .heatVault: c = FHDTheme.torch
                    case .merchantPad: c = FHDTheme.gold
                    case .lockedDoor: c = FHDTheme.gold.opacity(0.7)
                    default: c = FHDTheme.frost.opacity(0.5)
                    }
                    ctx.fill(Path(CGRect(x: CGFloat(x)*cw, y: CGFloat(y)*ch, width: cw+0.5, height: ch+0.5)), with: .color(c))
                }
            }
            // hero
            let hx = CGFloat(run.hero.pos.x)*cw, hy = CGFloat(run.hero.pos.y)*ch
            ctx.fill(Path(ellipseIn: CGRect(x: hx-1.5, y: hy-1.5, width: 4, height: 4)), with: .color(FHDTheme.ivory))
        }
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(FHDTheme.stroke, lineWidth: 1))
        .background(RoundedRectangle(cornerRadius: 6).fill(FHDTheme.abyss.opacity(0.7)))
        .cornerRadius(6)
    }
}

// MARK: - Examine panel

struct FHDExaminePanel: View {
    @ObservedObject var engine: FHDEngine
    var body: some View {
        let p = engine.examinePos
        VStack(alignment: .leading, spacing: 3) {
            Text(describe(p)).font(.system(size: 12, weight: .bold, design: .serif)).foregroundColor(FHDTheme.ivory)
            Text("Swipe to move cursor · tap Look to exit").font(.system(size: 9)).foregroundColor(FHDTheme.textDim)
        }
        .padding(10)
        .frame(maxWidth: 320)
        .fhdCard(raised: true)
        .padding(.bottom, 8)
    }
    private func describe(_ p: FHDPoint) -> String {
        if !engine.inBounds(p) { return "The void." }
        if let e = engine.run.enemies.first(where: { $0.pos == p && !($0.disguised && $0.def.ai == .iceMimic) }) {
            return "\(e.def.name) — HP \(e.hp)/\(e.def.maxHP). \(e.def.desc)"
        }
        if let gi = engine.run.ground.first(where: { $0.pos == p }) {
            return "Item: \(engine.run.displayName(gi.item))"
        }
        let t = engine.run.tiles[p.y][p.x]
        if !t.discovered { return "Unexplored darkness." }
        switch t.type {
        case .stairsDown: return "Stairs leading deeper."
        case .brazier: return "A warm brazier. Stand near it to warm up."
        case .lava: return "Molten rock. Warms you, but burns."
        case .thinIce: return "Thin ice. It will crack after you step away."
        case .water: return "Frigid water. Drains your warmth."
        case .frostSpore: return "Frost spores. They chill and slow."
        case .heatVault: return "A heat vault — a great burst of warmth."
        case .merchantPad: return "A merchant's stall."
        case .lockedDoor: return "A locked door. You need a key."
        case .wall: return "Solid cold stone."
        default: return "Stone floor."
        }
    }
}

// MARK: - Merchant

struct FHDMerchantView: View {
    @ObservedObject var engine: FHDEngine
    @State private var stock: [FHDMerchantOffer] = []

    var body: some View {
        ZStack {
            Color.black.opacity(0.7).edgesIgnoringSafeArea(.all)
                .onTapGesture { }
            VStack(spacing: 12) {
                Text("Merchant").font(.system(size: 20, weight: .heavy, design: .serif)).foregroundColor(FHDTheme.gold)
                Text("Gold: \(engine.run.hero.gold)").font(.system(size: 13)).foregroundColor(FHDTheme.ivory)
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(stock) { offer in
                            HStack(spacing: 10) {
                                FHDGlyph(kind: glyphFor(offer.item), size: 22, color: FHDTheme.frost)
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(engine.run.displayName(offer.item)).font(.system(size: 13, weight: .bold)).foregroundColor(FHDTheme.ivory)
                                    Text(FHDCatalog.def(offer.item.defID).desc).font(.system(size: 9)).foregroundColor(FHDTheme.textDim).lineLimit(1)
                                }
                                Spacer()
                                Button {
                                    buy(offer)
                                } label: {
                                    Text(offer.sold ? "Sold" : "\(offer.price)g")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(offer.sold ? FHDTheme.textDim : (engine.run.hero.gold >= offer.price ? FHDTheme.abyss : FHDTheme.danger))
                                        .padding(.horizontal, 10).padding(.vertical, 6)
                                        .background(RoundedRectangle(cornerRadius: 8).fill(offer.sold ? Color.clear : (engine.run.hero.gold >= offer.price ? FHDTheme.gold : FHDTheme.panel)))
                                }
                                .disabled(offer.sold || engine.run.hero.gold < offer.price)
                            }
                            .padding(10).fhdCard()
                        }
                    }
                }
                .frame(maxHeight: 320)
                Button { engine.pendingMerchant = false } label: { Text("Leave") }
                    .buttonStyle(FHDButtonStyle(tint: FHDTheme.torch))
            }
            .padding(18)
            .frame(maxWidth: 380)
            .background(RoundedRectangle(cornerRadius: 18).fill(FHDTheme.deepBlue)
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(FHDTheme.gold.opacity(0.5), lineWidth: 1)))
            .padding(20)
        }
        .onAppear { if stock.isEmpty { rollStock() } }
    }

    private func glyphFor(_ item: FHDItem) -> FHDGlyph.Kind {
        switch FHDCatalog.def(item.defID).glyph {
        case .sword: return .sword
        case .shield: return .shield
        case .potion: return .potion
        case .scroll: return .scroll
        case .ring: return .ring
        case .wand: return .wand
        case .flame: return .flame
        case .heart: return .heart
        default: return .bag
        }
    }

    private func rollStock() {
        var rng = FHDRandom(seed: engine.run.seed &+ UInt64(engine.run.floor) &* 7919)
        var offers: [FHDMerchantOffer] = []
        for _ in 0..<6 {
            let item = FHDGenerator.rollLoot(floor: engine.run.floor + 2, rng: &rng)
            let def = FHDCatalog.def(item.defID)
            let base = 18 + engine.run.floor * 4
            let price = base + rng.int(0...30) + def.power * 2
            offers.append(FHDMerchantOffer(item: item, price: price))
        }
        // always a healing potion & fuel
        offers.append(FHDMerchantOffer(item: FHDItem(defID: 300), price: 25))
        offers.append(FHDMerchantOffer(item: FHDItem(defID: FHDCatalog.fuel.id, fuel: 70), price: 20))
        stock = offers
    }

    private func buy(_ offer: FHDMerchantOffer) {
        guard let idx = stock.firstIndex(where: { $0.id == offer.id }), !stock[idx].sold else { return }
        guard engine.run.hero.gold >= offer.price else { return }
        engine.run.hero.gold -= offer.price
        engine.addToInventory(offer.item)
        engine.run.foundItemIDs.insert(offer.item.defID)
        stock[idx].sold = true
        engine.objectWillChange.send()
    }
}

struct FHDMerchantOffer: Identifiable {
    var id = UUID()
    var item: FHDItem
    var price: Int
    var sold = false
}
