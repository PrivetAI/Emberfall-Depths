import SwiftUI

struct FHDGameView: View {
    @ObservedObject var engine: FHDEngine
    @EnvironmentObject var store: FHDStore
    @EnvironmentObject var nav: FHDNav
    @EnvironmentObject var holder: FHDEngineHolder
    @Environment(\.scenePhase) private var scenePhase

    @State private var showInventory = false
    @State private var showOnboarding = false

    var body: some View {
        GeometryReader { geo in
            let vw = min(geo.size.width, UIScreen.main.bounds.width)
            let vh = min(geo.size.height, UIScreen.main.bounds.height)
            ZStack {
                FHDTheme.abyss.edgesIgnoringSafeArea(.all)
                VStack(spacing: 0) {
                    FHDHUDView(engine: engine, onMenu: { saveAndExit() }, onInventory: { showInventory = true })
                    // Tile view fills remaining space; pass explicit screenSize to the canvas.
                    GeometryReader { tileGeo in
                        FHDTileCanvas(engine: engine, screenSize: tileGeo.size)
                    }
                    FHDControlsView(engine: engine,
                                    onInventory: { showInventory = true },
                                    onExamine: { engine.examineMode.toggle(); engine.examinePos = engine.run.hero.pos },
                                    onDescend: { engine.descend(); checkEnd() },
                                    onRest: { rest() })
                    FHDLogStrip(engine: engine)
                }
                .frame(width: vw, height: vh)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                if engine.pendingMerchant {
                    FHDMerchantView(engine: engine)
                }
                if showOnboarding {
                    FHDOnboardingView(isShown: $showOnboarding) {
                        store.onboardingDone = true
                        store.saveMeta()
                    }
                }
            }
        }
        .sheet(isPresented: $showInventory) {
            FHDInventoryView(engine: engine, isShown: $showInventory)
        }
        .onAppear {
            if !store.onboardingDone { showOnboarding = true }
            checkEnd()
        }
        .onChange(of: engine.run.alive) { _ in checkEnd() }
        .onChange(of: scenePhase) { phase in
            // Save ONLY on .background (never .inactive — it fires on both transitions).
            if phase == .background, engine.run.alive {
                store.saveRun(engine.run)
            }
        }
    }

    private func rest() {
        // wait a turn in place
        engine.endPlayerTurn()
        checkEnd()
    }

    private func checkEnd() {
        if !engine.run.alive {
            nav.screen = .summary
        }
    }

    private func saveAndExit() {
        if engine.run.alive { store.saveRun(engine.run) }
        nav.screen = .title
    }
}

// MARK: - Tile canvas (camera anchored to screenSize, per pitfall)

struct FHDTileCanvas: View {
    @ObservedObject var engine: FHDEngine
    let screenSize: CGSize

    var body: some View {
        let run = engine.run
        let cell: CGFloat = 30
        let cols = Int(ceil(screenSize.width / cell)) + 2
        let rows = Int(ceil(screenSize.height / cell)) + 2
        // Camera centers on hero using the PARENT screenSize (not the canvas closure size).
        let camX = CGFloat(run.hero.pos.x) * cell + cell/2
        let camY = CGFloat(run.hero.pos.y) * cell + cell/2
        let offX = screenSize.width / 2 - camX
        let offY = screenSize.height / 2 - camY

        ZStack {
            Canvas { ctx, _ in
                let minTX = run.hero.pos.x - cols/2 - 1
                let maxTX = run.hero.pos.x + cols/2 + 1
                let minTY = run.hero.pos.y - rows/2 - 1
                let maxTY = run.hero.pos.y + rows/2 + 1
                for ty in minTY...maxTY {
                    for tx in minTX...maxTX {
                        if tx < 0 || ty < 0 || ty >= run.tiles.count || tx >= run.tiles[0].count { continue }
                        let tile = run.tiles[ty][tx]
                        if !tile.discovered { continue }
                        let rx = offX + CGFloat(tx) * cell
                        let ry = offY + CGFloat(ty) * cell
                        let rect = CGRect(x: rx, y: ry, width: cell - 1, height: cell - 1)
                        drawTile(ctx, tile: tile, type: tile.type, rect: rect, visible: tile.visible, biome: run.biome)
                    }
                }
                // ground items
                for gi in run.ground {
                    let p = gi.pos
                    if p.y < 0 || p.y >= run.tiles.count || p.x < 0 || p.x >= run.tiles[0].count { continue }
                    if !run.tiles[p.y][p.x].visible { continue }
                    let rx = offX + CGFloat(p.x) * cell
                    let ry = offY + CGFloat(p.y) * cell
                    drawItemGlyph(ctx, def: FHDCatalog.def(gi.item.defID),
                                  rect: CGRect(x: rx + 6, y: ry + 6, width: cell - 13, height: cell - 13))
                }
                // enemies
                for e in run.enemies {
                    let p = e.pos
                    if p.y < 0 || p.y >= run.tiles.count || p.x < 0 || p.x >= run.tiles[0].count { continue }
                    if !run.tiles[p.y][p.x].visible { continue }
                    if e.disguised && e.def.ai == .iceMimic {
                        // shows as a chest
                        let rx = offX + CGFloat(p.x) * cell
                        let ry = offY + CGFloat(p.y) * cell
                        drawGlyph(ctx, FHDChestShape().path(in: CGRect(x: rx+5, y: ry+6, width: cell-11, height: cell-11)),
                                  color: FHDTheme.gold)
                        continue
                    }
                    let rx = offX + CGFloat(p.x) * cell
                    let ry = offY + CGFloat(p.y) * cell
                    drawEnemy(ctx, enemy: e, rect: CGRect(x: rx + 3, y: ry + 3, width: cell - 7, height: cell - 7))
                }
                // hero
                let hrx = offX + CGFloat(run.hero.pos.x) * cell
                let hry = offY + CGFloat(run.hero.pos.y) * cell
                drawHero(ctx, rect: CGRect(x: hrx + 3, y: hry + 3, width: cell - 7, height: cell - 7),
                         warmthFrac: Double(run.hero.warmth) / Double(max(1, engine.effectiveWarmthCap())))
                // examine cursor
                if engine.examineMode {
                    let ex = offX + CGFloat(engine.examinePos.x) * cell
                    let ey = offY + CGFloat(engine.examinePos.y) * cell
                    let box = Path(roundedRect: CGRect(x: ex, y: ey, width: cell - 1, height: cell - 1), cornerRadius: 3)
                    ctx.stroke(box, with: .color(FHDTheme.ember), lineWidth: 2)
                }
            }
            // float texts
            ForEach(engine.floatTexts) { ft in
                let rx = offX + CGFloat(ft.pos.x) * cell + cell/2
                let ry = offY + CGFloat(ft.pos.y) * cell
                Text(ft.text)
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .foregroundColor(ft.color)
                    .position(x: rx, y: ry - 8)
                    .transition(.opacity)
            }

            // minimap overlay top-right
            FHDMinimap(engine: engine)
                .frame(width: 92, height: 78)
                .padding(8)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)

            // examine info card
            if engine.examineMode {
                FHDExaminePanel(engine: engine)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            }
        }
        .clipped()
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 18)
                .onEnded { v in
                    if engine.examineMode { handleExamineDrag(v) }
                    else { handleSwipe(v) }
                }
        )
    }

    private func handleSwipe(_ v: DragGesture.Value) {
        let dx = v.translation.width, dy = v.translation.height
        if abs(dx) > abs(dy) {
            engine.tryMove(dx > 0 ? .right : .left)
        } else {
            engine.tryMove(dy > 0 ? .down : .up)
        }
    }
    private func handleExamineDrag(_ v: DragGesture.Value) {
        let dx = v.translation.width, dy = v.translation.height
        var p = engine.examinePos
        if abs(dx) > abs(dy) { p.x += dx > 0 ? 1 : -1 } else { p.y += dy > 0 ? 1 : -1 }
        if engine.inBounds(p) { engine.examinePos = p }
    }

    // MARK: drawing helpers

    private func drawTile(_ ctx: GraphicsContext, tile: FHDTile, type: FHDTileType, rect: CGRect, visible: Bool, biome: FHDBiome) {
        var base: Color
        switch type {
        case .wall, .secretWall: base = biome.wallColor
        case .floor, .stairsUp, .merchantPad: base = biome.floorColor
        case .door, .lockedDoor: base = biome.floorColor
        case .stairsDown: base = biome.floorColor
        case .thinIce: base = Color(red: 0.55, green: 0.75, blue: 0.88)
        case .crackedIce: base = Color(red: 0.30, green: 0.45, blue: 0.58)
        case .water: base = Color(red: 0.10, green: 0.25, blue: 0.42)
        case .lava: base = Color(red: 0.62, green: 0.22, blue: 0.10)
        case .brazier: base = biome.floorColor
        case .heatVault: base = Color(red: 0.40, green: 0.20, blue: 0.10)
        case .frostSpore: base = Color(red: 0.30, green: 0.40, blue: 0.40)
        case .steamJet: base = biome.floorColor
        case .meltwater: base = Color(red: 0.20, green: 0.30, blue: 0.40)
        }
        if !visible { base = base.opacity(0.42) }
        ctx.fill(Path(roundedRect: rect, cornerRadius: 2), with: .color(base))

        // overlays
        switch type {
        case .stairsDown:
            drawGlyph(ctx, FHDStairsShape().path(in: rect.insetBy(dx: 6, dy: 6)), color: FHDTheme.ember.opacity(visible ? 1 : 0.5))
        case .stairsUp:
            drawGlyph(ctx, FHDChevronShape(dir: 0).path(in: rect.insetBy(dx: 8, dy: 8)), color: FHDTheme.frost.opacity(visible ? 0.8 : 0.4))
        case .door:
            ctx.stroke(Path(rect.insetBy(dx: 7, dy: 4)), with: .color(FHDTheme.frost.opacity(0.6)), lineWidth: 2)
        case .lockedDoor:
            drawGlyph(ctx, FHDKeyShape().path(in: rect.insetBy(dx: 7, dy: 9)), color: FHDTheme.gold.opacity(visible ? 0.9 : 0.4))
        case .brazier:
            if visible {
                drawGlyph(ctx, FHDFlameShape().path(in: rect.insetBy(dx: 8, dy: 5)), color: FHDTheme.torch)
            }
        case .heatVault:
            drawGlyph(ctx, FHDFlameShape().path(in: rect.insetBy(dx: 6, dy: 4)), color: FHDTheme.ember)
        case .lava:
            if visible { drawGlyph(ctx, FHDFlameShape().path(in: rect.insetBy(dx: 9, dy: 7)), color: FHDTheme.ember.opacity(0.8)) }
        case .frostSpore:
            if visible { drawGlyph(ctx, FHDSnowflakeShape().path(in: rect.insetBy(dx: 8, dy: 8)), color: FHDTheme.poison.opacity(0.7)) }
        case .merchantPad:
            drawGlyph(ctx, FHDBagShape().path(in: rect.insetBy(dx: 7, dy: 6)), color: FHDTheme.gold)
        case .steamJet:
            if visible { drawGlyph(ctx, FHDChevronShape(dir: 0).path(in: rect.insetBy(dx: 9, dy: 9)), color: FHDTheme.ivory.opacity(0.5)) }
        case .thinIce:
            ctx.stroke(Path(rect.insetBy(dx: 5, dy: 5)), with: .color(FHDTheme.iceCyan.opacity(0.4)), lineWidth: 1)
        default: break
        }
    }

    private func drawGlyph(_ ctx: GraphicsContext, _ path: Path, color: Color) {
        ctx.fill(path, with: .color(color))
    }

    private func drawItemGlyph(_ ctx: GraphicsContext, def: FHDItemDef, rect: CGRect) {
        let color = itemColor(def)
        let path: Path
        switch def.glyph {
        case .sword: path = FHDSwordShape().path(in: rect)
        case .shield: path = FHDShieldShape().path(in: rect)
        case .potion: path = FHDPotionShape().path(in: rect)
        case .scroll: path = FHDScrollShape().path(in: rect)
        case .ring: ctx.fill(FHDRingShape().path(in: rect), with: .color(color), style: FillStyle(eoFill: true)); return
        case .wand: ctx.fill(FHDWandShape().path(in: rect), with: .color(color), style: FillStyle(eoFill: true)); return
        case .flame: path = FHDFlameShape().path(in: rect)
        case .key: path = FHDKeyShape().path(in: rect)
        case .heart: path = FHDHeartShape().path(in: rect)
        case .boot: path = FHDBootShape().path(in: rect)
        case .gear: ctx.fill(FHDGearShape().path(in: rect), with: .color(color), style: FillStyle(eoFill: true)); return
        case .chest: path = FHDChestShape().path(in: rect)
        case .bag: path = FHDBagShape().path(in: rect)
        case .snow: ctx.stroke(FHDSnowflakeShape().path(in: rect), with: .color(color), lineWidth: 1.5); return
        case .star: path = FHDStarShape().path(in: rect)
        case .skull: path = FHDSkullShape().path(in: rect)
        }
        ctx.fill(path, with: .color(color))
    }

    private func itemColor(_ def: FHDItemDef) -> Color {
        switch def.category {
        case .weapon: return def.affinity == .fire ? FHDTheme.torch : FHDTheme.frost
        case .armor: return FHDTheme.iceCyan
        case .potion: return FHDTheme.poison
        case .scroll: return FHDTheme.ivory
        case .ring: return FHDTheme.gold
        case .wand: return Color(red: 0.7, green: 0.6, blue: 1.0)
        case .gold: return FHDTheme.gold
        case .key: return FHDTheme.gold
        case .shard: return FHDTheme.shard
        case .throwable: return FHDTheme.ember
        case .food: return FHDTheme.blood
        default: return FHDTheme.ivory
        }
    }

    private func drawEnemy(_ ctx: GraphicsContext, enemy: FHDEnemy, rect: CGRect) {
        let def = enemy.def
        var color: Color = def.affinity == .fire ? FHDTheme.torch :
                           (def.affinity == .frost ? FHDTheme.iceCyan : FHDTheme.ivory)
        if def.isBoss { color = FHDTheme.danger }
        if enemy.frozenTurns > 0 { color = FHDTheme.frost.opacity(0.6) }
        if enemy.polymorphed { color = FHDTheme.poison }
        // base body
        ctx.fill(Path(ellipseIn: rect), with: .color(color.opacity(0.22)))
        let glyphRect = rect.insetBy(dx: 2, dy: 2)
        let path: Path
        switch def.glyph {
        case .skull: path = FHDSkullShape().path(in: glyphRect)
        case .snow: ctx.stroke(FHDSnowflakeShape().path(in: glyphRect), with: .color(color), lineWidth: 1.6); drawHPBar(ctx, enemy, rect); return
        case .shield: path = FHDShieldShape().path(in: glyphRect)
        case .flame: path = FHDFlameShape().path(in: glyphRect)
        case .gear: ctx.fill(FHDGearShape().path(in: glyphRect), with: .color(color), style: FillStyle(eoFill: true)); drawHPBar(ctx, enemy, rect); return
        case .wand: ctx.fill(FHDWandShape().path(in: glyphRect), with: .color(color), style: FillStyle(eoFill: true)); drawHPBar(ctx, enemy, rect); return
        case .star: path = FHDStarShape().path(in: glyphRect)
        case .chest: path = FHDChestShape().path(in: glyphRect)
        case .ring: ctx.fill(FHDRingShape().path(in: glyphRect), with: .color(color), style: FillStyle(eoFill: true)); drawHPBar(ctx, enemy, rect); return
        case .sword: path = FHDSwordShape().path(in: glyphRect)
        case .heart: path = FHDHeartShape().path(in: glyphRect)
        default: path = FHDSkullShape().path(in: glyphRect)
        }
        ctx.fill(path, with: .color(color))
        drawHPBar(ctx, enemy, rect)
    }

    private func drawHPBar(_ ctx: GraphicsContext, _ enemy: FHDEnemy, _ rect: CGRect) {
        let frac = Double(enemy.hp) / Double(max(1, enemy.def.maxHP))
        if frac >= 0.999 { return }
        let barRect = CGRect(x: rect.minX, y: rect.maxY + 1, width: rect.width, height: 2.5)
        ctx.fill(Path(barRect), with: .color(FHDTheme.abyss.opacity(0.8)))
        ctx.fill(Path(CGRect(x: barRect.minX, y: barRect.minY, width: barRect.width * CGFloat(frac), height: barRect.height)),
                 with: .color(FHDTheme.hpColor(frac)))
    }

    private func drawHero(_ ctx: GraphicsContext, rect: CGRect, warmthFrac: Double) {
        let glow = FHDTheme.warmthColor(warmthFrac)
        ctx.fill(Path(ellipseIn: rect.insetBy(dx: -2, dy: -2)), with: .color(glow.opacity(0.25)))
        ctx.fill(Path(ellipseIn: rect), with: .color(glow.opacity(0.4)))
        // a simple adventurer figure: head + body
        let head = CGRect(x: rect.midX - rect.width*0.18, y: rect.minY + 1, width: rect.width*0.36, height: rect.width*0.36)
        ctx.fill(Path(ellipseIn: head), with: .color(FHDTheme.ivory))
        let body = Path(roundedRect: CGRect(x: rect.midX - rect.width*0.22, y: head.maxY, width: rect.width*0.44, height: rect.height*0.5), cornerRadius: 3)
        ctx.fill(body, with: .color(glow))
    }
}
