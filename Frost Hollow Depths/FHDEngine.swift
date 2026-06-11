import Foundation
import SwiftUI

// The live game controller. Owns the run, drives turns, exposes published state.
final class FHDEngine: ObservableObject {
    @Published var run: FHDRunState
    @Published var floatTexts: [FHDFloatText] = []
    @Published var pendingMerchant = false
    @Published var examineMode = false
    @Published var examinePos: FHDPoint = .zero
    @Published var lastTickStamp = Date()

    weak var store: FHDStore?

    init(run: FHDRunState, store: FHDStore?) {
        self.run = run
        self.store = store
    }

    // MARK: - Floor loading

    func loadFloor(_ floor: Int, fromUp: Bool = true) {
        // Derive a per-floor seed deterministically from run seed + floor.
        let floorSeed = run.seed &* 0x100000001B3 &+ UInt64(floor) &* 0x9E3779B1
        let data = FHDGenerator.generate(floor: floor, seed: floorSeed)
        run.floor = floor
        run.biome = data.biome
        run.tiles = data.tiles
        run.enemies = data.enemies
        run.ground = data.groundItems
        run.rooms = data.rooms.map { FHDRoomCodable($0) }
        run.startPos = data.startPos
        run.downPos = data.downPos
        run.lockedDoorsOnFloor = data.lockedDoors
        run.hasSecretRoom = data.hasSecretRoom
        run.hasHeatVault = data.hasHeatVault
        run.hasMerchant = data.hasMerchant
        run.hero.pos = fromUp ? data.startPos : data.downPos
        run.deepestFloor = max(run.deepestFloor, floor)
        run.addLog(FHDFloorFlavor.intro(floor: floor), tone: data.biome == .forge ? 1 : 2)
        // Codex: record enemies present? Only when seen. Record start FOV.
        recomputeFOV()
        autoPickupAt(run.hero.pos)
        store?.recordBiomeReached(data.biome)
    }

    func descend() {
        if run.hero.pos != run.downPos { return }
        if run.floor >= FHDConst.totalFloors {
            triggerVictory()
            return
        }
        loadFloor(run.floor + 1, fromUp: true)
        store?.saveRun(run)
    }

    // MARK: - Field of view (light-radius driven)

    var lightRadius: Int {
        var r = FHDConst.baseLight
        if let torch = run.hero.torch, torch.fuel > 0 { r += 1 }
        if run.hero.classID == .ranger { r += 1 }
        for ring in equippedRings() {
            let d = FHDCatalog.def(ring.defID)
            if d.ringEffect == FHDRingEffect.light.rawValue { r += 2 + ring.upgrade }
        }
        // Cold dims your vision when warmth is very low.
        if run.hero.warmth <= 0 { r = max(2, r - 2) }
        else if run.hero.warmth < run.hero.warmthCap / 5 { r = max(3, r - 1) }
        return r
    }

    func recomputeFOV() {
        let w = run.tiles[0].count, h = run.tiles.count
        for y in 0..<h { for x in 0..<w { run.tiles[y][x].visible = false } }
        let origin = run.hero.pos
        let radius = lightRadius
        run.tiles[origin.y][origin.x].visible = true
        run.tiles[origin.y][origin.x].discovered = true
        // Symmetric shadow-ish: cast rays to perimeter cells.
        for dy in -radius...radius {
            for dx in -radius...radius {
                if dx*dx + dy*dy > radius*radius { continue }
                let tx = origin.x + dx, ty = origin.y + dy
                if tx < 0 || ty < 0 || tx >= w || ty >= h { continue }
                if lineOfSight(from: origin, to: FHDPoint(x: tx, y: ty)) {
                    run.tiles[ty][tx].visible = true
                    run.tiles[ty][tx].discovered = true
                }
            }
        }
        // Reveal secret walls adjacent to player.
        for d in FHDDir.allCases {
            let p = origin + d.delta
            if inBounds(p), run.tiles[p.y][p.x].type == .secretWall {
                run.tiles[p.y][p.x].type = .door
                run.addLog("You discover a hidden passage!", tone: 4)
            }
        }
    }

    func lineOfSight(from a: FHDPoint, to b: FHDPoint) -> Bool {
        var x0 = a.x, y0 = a.y
        let x1 = b.x, y1 = b.y
        let dx = abs(x1 - x0), dy = abs(y1 - y0)
        let sx = x0 < x1 ? 1 : -1, sy = y0 < y1 ? 1 : -1
        var err = dx - dy
        while true {
            if x0 == x1 && y0 == y1 { return true }
            if !(x0 == a.x && y0 == a.y) {
                if run.tiles[y0][x0].type.blocksSight { return false }
            }
            let e2 = 2 * err
            if e2 > -dy { err -= dy; x0 += sx }
            if e2 < dx { err += dx; y0 += sy }
        }
    }

    func inBounds(_ p: FHDPoint) -> Bool {
        p.x >= 0 && p.y >= 0 && p.x < run.tiles[0].count && p.y < run.tiles.count
    }

    // MARK: - Player actions (each consumes a world tick unless noted)

    func tryMove(_ dir: FHDDir) {
        guard run.alive, !pendingMerchant, !examineMode else { return }
        let target = run.hero.pos + dir.delta
        if !inBounds(target) { return }
        let tile = run.tiles[target.y][target.x]

        // Enemy in the way? Attack. (Walking into a disguised mimic triggers it.)
        if let idx = run.enemies.firstIndex(where: { $0.pos == target }) {
            if run.enemies[idx].def.ai == .iceMimic && run.enemies[idx].disguised {
                run.enemies[idx].disguised = false
                run.enemies[idx].aware = true
                run.addLog("The chest lurches — an Ice Mimic!", tone: 3)
            }
            playerAttack(enemyIndex: idx)
            endPlayerTurn()
            return
        }

        if tile.type == .lockedDoor {
            if run.hero.keys > 0 {
                run.hero.keys -= 1
                run.tiles[target.y][target.x].type = .door
                run.addLog("You unlock the door.", tone: 0)
                recomputeFOV()
            } else {
                run.addLog("The door is locked. You need a key.", tone: 2)
            }
            return
        }

        if tile.type.blocksMove { return }

        // Hazard checks before stepping.
        let levit = run.hero.levitation > 0
        // Step onto target.
        run.hero.pos = target
        run.stepsTaken += 1

        // Thin ice cracks after stepping off — mark it. We crack the tile we left if it was thin ice.
        // Apply tile-entry effects.
        applyTileEntry(target, levitating: levit)

        autoPickupAt(target)

        if target == run.downPos && tile.type == .stairsDown {
            run.addLog("Stairs lead deeper. Stand here and Descend.", tone: 0)
        }
        if tile.type == .merchantPad {
            pendingMerchant = true
            store?.unlockAchievement(.meetMerchant)
        }
        endPlayerTurn()
    }

    func applyTileEntry(_ p: FHDPoint, levitating: Bool) {
        let t = run.tiles[p.y][p.x].type
        // crack thin ice you previously stepped on: convert thinIce to crackedIce when you LEAVE.
        // Here, when stepping onto thin ice, it remains; we crack it on the next move out via flag.
        if levitating { return }
        switch t {
        case .thinIce:
            // schedule crack: set a marker; cracking happens in endPlayerTurn via lastThinIce
            run.lastThinIce = p
        case .crackedIce, .water:
            changeWarmth(-3, reason: "icy water", tone: 2)
        case .lava:
            if run.hero.fireImmunity > 0 {
                changeWarmth(8, reason: "lava heat", tone: 1)
            } else {
                changeWarmth(10, reason: "lava heat", tone: 1)
                damageHero(12, source: "lava")
            }
        case .brazier, .heatVault:
            // handled as warmth source in tick; entering a heat vault gives a big refill.
            if t == .heatVault {
                changeWarmth(run.hero.warmthCap, reason: "heat vault", tone: 1)
                run.addLog("Warmth floods back into your limbs.", tone: 1)
                run.tiles[p.y][p.x].type = .floor
                store?.unlockAchievement(.heatVault)
            }
        case .frostSpore:
            changeWarmth(-5, reason: "frost spores", tone: 2)
            run.hero.chill = max(run.hero.chill, 3)
        case .steamJet:
            if run.turnCount % 3 == 0 {
                damageHero(6, source: "steam")
                changeWarmth(4, reason: "steam", tone: 1)
            }
        case .meltwater:
            run.hero.chill = max(run.hero.chill, 2)
        default: break
        }
        _ = t
    }

    func autoPickupAt(_ p: FHDPoint) {
        let here = run.ground.filter { $0.pos == p }
        for gi in here {
            pickup(gi)
        }
    }

    func pickup(_ gi: FHDGroundItem) {
        let def = FHDCatalog.def(gi.item.defID)
        run.foundItemIDs.insert(def.id)
        store?.recordItemDiscovered(def.id)
        switch def.category {
        case .gold:
            var amt = gi.item.quantity
            if let r = equippedRings().first(where: { FHDCatalog.def($0.defID).ringEffect == FHDRingEffect.greed.rawValue }) {
                amt = amt + amt * (1 + r.upgrade) / 4
            }
            run.hero.gold += amt
            run.goldCollected += amt
            run.addLog("Picked up \(amt) gold.", tone: 4)
        case .key:
            run.hero.keys += 1
            run.addLog("Picked up an iron key.", tone: 4)
        case .shard:
            run.addLog("A frost shard glimmers in your pack.", tone: 4)
        case .torch, .fuel:
            addToInventory(gi.item)
            run.addLog("Picked up \(def.name).", tone: 0)
        default:
            addToInventory(gi.item)
            run.addLog("Picked up \(run.displayName(gi.item)).", tone: 0)
        }
        run.ground.removeAll { $0.id == gi.id }
    }

    func addToInventory(_ item: FHDItem) {
        let def = FHDCatalog.def(item.defID)
        // stack stackables
        if def.category == .potion || def.category == .scroll || def.category == .throwable ||
            def.category == .food || def.category == .fuel {
            if let idx = run.inventory.firstIndex(where: { $0.defID == item.defID && $0.upgrade == item.upgrade }) {
                run.inventory[idx].quantity += max(1, item.quantity)
                return
            }
        }
        run.inventory.append(item)
    }

    // MARK: - Combat

    func playerAttack(enemyIndex idx: Int) {
        var enemy = run.enemies[idx]
        let edef = enemy.def
        var dmg = playerAttackPower()
        // bonus weapon affinity interactions
        if let w = run.hero.weapon {
            let wdef = FHDCatalog.def(w.defID)
            if wdef.id == 107 && edef.affinity == .frost { dmg += 6 } // glacier pick vs frost
        }
        // evasion of enemy: none; defense reduces
        dmg = max(1, dmg - edef.defense)
        enemy.hp -= dmg
        enemy.aware = true
        spawnFloat("-\(dmg)", at: enemy.pos, color: FHDTheme.blood)

        // frost-witch chills on hit
        if run.hero.classID == .frostWitch { enemy.frozenTurns = max(enemy.frozenTurns, 1) }
        // frost cleaver chills but drains your warmth
        if let w = run.hero.weapon, FHDCatalog.def(w.defID).id == 104 {
            enemy.frozenTurns = max(enemy.frozenTurns, 1)
            changeWarmth(-1, reason: "frost cleaver", tone: 2)
        }

        // splitter splits
        if edef.ai == .splitter && enemy.hp > 0 && enemy.splitCount < 2 {
            if let np = freeAdjacent(to: enemy.pos) {
                var child = FHDEnemy(defID: enemy.defID, pos: np, hp: max(4, enemy.hp / 2))
                child.aware = true
                child.splitCount = enemy.splitCount + 1
                enemy.hp = max(1, enemy.hp / 2)
                enemy.splitCount += 1
                run.enemies.append(child)
                run.addLog("The \(edef.name) splinters!", tone: 3)
            }
        }

        if enemy.hp <= 0 {
            killEnemy(at: idx, edef: edef)
        } else {
            run.enemies[idx] = enemy
            run.addLog("You hit the \(edef.name) for \(dmg).", tone: 0)
        }
    }

    func killEnemy(at idx: Int, edef: FHDEnemyDef) {
        let enemy = run.enemies[idx]
        run.addLog("You slay the \(edef.name)!", tone: 4)
        run.kills += 1
        run.hero.xp += edef.xp
        run.encounteredEnemyIDs.insert(edef.id)
        store?.recordEnemyDefeated(edef.id)
        // shard thief drops stolen gold
        if enemy.stolenGold > 0 { run.hero.gold += enemy.stolenGold }
        // level up
        let need = run.hero.level * 12
        if run.hero.xp >= need {
            run.hero.xp -= need
            run.hero.level += 1
            run.hero.maxHP += 5
            run.hero.hp = min(run.hero.maxHP, run.hero.hp + 5)
            run.hero.strength += 1
            run.addLog("You feel stronger. Level \(run.hero.level)!", tone: 4)
        }
        run.enemies.remove(at: idx)
        if edef.isBoss {
            run.addLog("The \(edef.name) is defeated! The way down opens.", tone: 4)
            store?.unlockAchievement(bossAchievement(floor: run.floor))
            // boss drops a shard cache + big loot
            run.ground.append(FHDGroundItem(item: FHDItem(defID: FHDCatalog.shard.id, quantity: 10), pos: enemy.pos))
            run.ground.append(FHDGroundItem(item: FHDItem(defID: 401, quantity: 2), pos: enemy.pos))
        }
    }

    func playerAttackPower() -> Int {
        var p = run.hero.strength
        if let w = run.hero.weapon {
            let wdef = FHDCatalog.def(w.defID)
            p += wdef.power + w.upgrade * 2
        } else {
            p += 1 // fists
        }
        for r in equippedRings() {
            let d = FHDCatalog.def(r.defID)
            if d.ringEffect == FHDRingEffect.power.rawValue { p += 2 + r.upgrade }
        }
        if run.hero.warmth <= 0 { p = max(1, p - 3) } // frostbite weakens
        return p
    }

    func equippedRings() -> [FHDItem] {
        var rings: [FHDItem] = []
        if let a = run.hero.ringA { rings.append(a) }
        if let b = run.hero.ringB { rings.append(b) }
        return rings
    }

    func freeAdjacent(to p: FHDPoint) -> FHDPoint? {
        for d in FHDDir.allCases.shuffledStable(p) {
            let np = p + d.delta
            if inBounds(np) && run.tiles[np.y][np.x].type.isWalkable &&
                !run.enemies.contains(where: { $0.pos == np }) && run.hero.pos != np {
                return np
            }
        }
        return nil
    }

    // MARK: - Warmth / HP

    func changeWarmth(_ delta: Int, reason: String, tone: Int) {
        let cap = effectiveWarmthCap()
        if delta < 0 && run.hero.frostWard > 0 { return }
        if delta < 0 && run.hero.classID == .frostWitch && reason.contains("frost") { return }
        run.hero.warmth = max(0, min(cap, run.hero.warmth + delta))
        run.coldestWarmth = min(run.coldestWarmth, run.hero.warmth)
        if run.hero.warmth == 0 && delta < 0 {
            store?.unlockAchievement(.brinkOfFrost)
        }
    }

    func effectiveWarmthCap() -> Int {
        var cap = run.hero.warmthCap
        for r in equippedRings() {
            let d = FHDCatalog.def(r.defID)
            if d.ringEffect == FHDRingEffect.warmthCap.rawValue { cap += 15 + r.upgrade * 5 }
        }
        return cap
    }

    func damageHero(_ raw: Int, source: String) {
        var dmg = raw
        // armor + ward
        if let a = run.hero.armor {
            let adef = FHDCatalog.def(a.defID)
            dmg = max(1, dmg - (adef.power + a.upgrade) / 2)
        }
        if run.hero.ward > 0 { dmg = max(0, dmg - 4) }
        // evasion ring
        if let _ = equippedRings().first(where: { FHDCatalog.def($0.defID).ringEffect == FHDRingEffect.evasion.rawValue }) {
            if Int.random(in: 0..<100) < 20 { run.addLog("You dodge!", tone: 4); return }
        }
        run.hero.hp -= dmg
        spawnFloat("-\(dmg)", at: run.hero.pos, color: FHDTheme.danger)
        if run.hero.hp <= 0 {
            run.hero.hp = 0
            triggerDeath(cause: source)
        }
    }

    // MARK: - Turn resolution

    func endPlayerTurn() {
        run.turnCount += 1
        // crack thin ice the player just left
        if let last = run.lastThinIce, last != run.hero.pos {
            if inBounds(last) && run.tiles[last.y][last.x].type == .thinIce {
                run.tiles[last.y][last.x].type = .crackedIce
            }
            run.lastThinIce = nil
        }

        tickHero()
        if !run.alive { finishTurnVisuals(); return }
        runEnemyTurns()
        if !run.alive { finishTurnVisuals(); return }
        finishTurnVisuals()
        // periodic autosave handled by view lifecycle
    }

    func finishTurnVisuals() {
        recomputeFOV()
        lastTickStamp = Date()
        objectWillChange.send()
    }

    func tickHero() {
        // 1) Ambient biome warmth drain/restore (modified by insulation).
        var ambient = run.biome.ambientWarmth
        // warmth sources nearby (brazier/lava/heatVault) override drain with restore
        let nearWarm = nearbyWarmthSource()
        if nearWarm > 0 {
            ambient += nearWarm
        } else {
            // insulation reduces drain only
            if ambient < 0 {
                let insul = totalInsulation()
                ambient = min(0, ambient + insul / 4)
                if run.hero.classID == .pyreKnight { ambient = Int(Double(ambient) * 0.6) }
            }
        }
        // equipped warmth emitters
        ambient += equippedWarmthEmission()
        // frost-aura enemies nearby
        ambient -= frostAuraDrain()

        if run.hero.frostWard > 0 && ambient < 0 { ambient = 0 }
        if run.hero.classID == .frostWitch && ambient < 0 { ambient = max(ambient, -1) }

        if ambient != 0 {
            changeWarmth(ambient, reason: ambient < 0 ? "frost cold" : "warmth", tone: ambient < 0 ? 2 : 1)
        }

        // 2) Frostbite at zero warmth: escalating damage + slow.
        if run.hero.warmth <= 0 {
            run.hero.frostbiteCounter += 1
            let fb = 1 + run.hero.frostbiteCounter / 3
            damageHero(fb, source: "frostbite")
            if !run.alive { return }
            if run.hero.frostbiteCounter == 1 { run.addLog("Frostbite sets in. Find heat!", tone: 3) }
        } else {
            run.hero.frostbiteCounter = max(0, run.hero.frostbiteCounter - 1)
        }

        // 3) torch fuel burn
        if var torch = run.hero.torch {
            torch.fuel = max(0, torch.fuel - 1)
            run.hero.torch = torch.fuel > 0 ? torch : nil
            if torch.fuel == 0 { run.addLog("Your torch sputters out.", tone: 2) }
        }

        // 4) status timers
        tickStatuses()

        // 5) regen
        if run.hero.regenTurns > 0 && run.turnCount % 2 == 0 {
            run.hero.hp = min(run.hero.maxHP, run.hero.hp + 1)
        }
        for r in equippedRings() where FHDCatalog.def(r.defID).ringEffect == FHDRingEffect.regen.rawValue {
            if run.turnCount % 3 == 0 { run.hero.hp = min(run.hero.maxHP, run.hero.hp + 1) }
        }

        // 6) poison
        if run.hero.poison > 0 {
            damageHero(2, source: "poison")
            run.hero.poison -= 1
        }
    }

    func tickStatuses() {
        if run.hero.levitation > 0 { run.hero.levitation -= 1 }
        if run.hero.fireImmunity > 0 { run.hero.fireImmunity -= 1 }
        if run.hero.frostWard > 0 { run.hero.frostWard -= 1 }
        if run.hero.haste > 0 { run.hero.haste -= 1 }
        if run.hero.regenTurns > 0 { run.hero.regenTurns -= 1 }
        if run.hero.chill > 0 { run.hero.chill -= 1 }
        if run.hero.ward > 0 { run.hero.ward -= 1 }
    }

    func nearbyWarmthSource() -> Int {
        var best = 0
        for dy in -2...2 {
            for dx in -2...2 {
                let p = FHDPoint(x: run.hero.pos.x + dx, y: run.hero.pos.y + dy)
                if !inBounds(p) { continue }
                let dist = max(abs(dx), abs(dy))
                let t = run.tiles[p.y][p.x].type
                if t == .brazier { best = max(best, dist <= 1 ? 5 : 3) }
                if t == .lava { best = max(best, dist <= 1 ? 6 : 3) }
                if t == .heatVault { best = max(best, 6) }
            }
        }
        // adjacent fire enemies warm you
        for e in run.enemies where e.def.affinity == .fire {
            if e.pos.chebyshev(to: run.hero.pos) <= 1 { best = max(best, 2) }
        }
        return best
    }

    func frostAuraDrain() -> Int {
        var drain = 0
        for e in run.enemies {
            if e.def.warmthDrain > 0 {
                let d = e.pos.chebyshev(to: run.hero.pos)
                if e.def.ai == .frostDrainer && d <= 2 { drain += e.def.warmthDrain }
                else if d <= 1 { drain += e.def.warmthDrain }
            }
        }
        if run.hero.classID == .frostWitch { return 0 }
        return drain
    }

    func totalInsulation() -> Int {
        var ins = 0
        if let a = run.hero.armor { ins += FHDCatalog.def(a.defID).insulation + a.upgrade }
        for r in equippedRings() where FHDCatalog.def(r.defID).ringEffect == FHDRingEffect.insulation.rawValue {
            ins += 4 + r.upgrade * 2
        }
        return ins
    }

    func equippedWarmthEmission() -> Int {
        var w = 0
        if let weapon = run.hero.weapon { w += FHDCatalog.def(weapon.defID).emitsWarmth }
        if let armor = run.hero.armor { w += FHDCatalog.def(armor.defID).emitsWarmth }
        if run.hero.classID == .pyreKnight { w += 1 }
        return w
    }

    // MARK: - End states

    func triggerDeath(cause: String) {
        run.alive = false
        run.addLog("You have fallen to \(cause).", tone: 3)
        store?.finishRun(run, victory: false, cause: cause)
    }

    func triggerVictory() {
        run.alive = false
        run.victory = true
        run.addLog("You have ended the long winter. Victory!", tone: 4)
        store?.finishRun(run, victory: true, cause: "victory")
        store?.unlockAchievement(.victory)
    }

    func bossAchievement(floor: Int) -> FHDAchID {
        switch floor {
        case 5: return .boss1
        case 10: return .boss2
        case 15: return .boss3
        case 20: return .boss4
        case 25: return .boss5
        default: return .boss6
        }
    }

    // MARK: - Float text

    func spawnFloat(_ text: String, at p: FHDPoint, color: Color) {
        let ft = FHDFloatText(text: text, pos: p, color: color)
        floatTexts.append(ft)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
            self?.floatTexts.removeAll { $0.id == ft.id }
        }
    }
}

struct FHDFloatText: Identifiable {
    let id = UUID()
    var text: String
    var pos: FHDPoint
    var color: Color
}

// Stable-ish shuffle for AI variety without RNG state.
extension Array where Element == FHDDir {
    func shuffledStable(_ seed: FHDPoint) -> [FHDDir] {
        let s = (seed.x * 31 + seed.y * 17) % 4
        return Array(self[s...] + self[..<s])
    }
}

