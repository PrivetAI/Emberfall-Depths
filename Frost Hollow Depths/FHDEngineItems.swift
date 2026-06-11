import Foundation
import SwiftUI

extension FHDEngine {

    // MARK: - Equip

    func equip(_ item: FHDItem) {
        let def = FHDCatalog.def(item.defID)
        switch def.category {
        case .weapon:
            if let cur = run.hero.weapon { run.inventory.append(cur) }
            run.hero.weapon = item
            removeOneFromInventory(item)
            run.addLog("Equipped \(run.displayName(item)).", tone: 0)
        case .armor:
            if let cur = run.hero.armor { run.inventory.append(cur) }
            run.hero.armor = item
            removeOneFromInventory(item)
            run.addLog("Donned \(run.displayName(item)).", tone: 0)
        case .ring:
            if run.hero.ringA == nil { run.hero.ringA = item }
            else if run.hero.ringB == nil { run.hero.ringB = item }
            else { if let cur = run.hero.ringA { run.inventory.append(cur) }; run.hero.ringA = item }
            removeOneFromInventory(item)
            run.addLog("Slipped on \(run.displayName(item)).", tone: 0)
        case .torch:
            if let cur = run.hero.torch { run.inventory.append(cur) }
            run.hero.torch = item
            removeOneFromInventory(item)
            run.addLog("You light the torch.", tone: 1)
        default:
            break
        }
        recomputeFOV()
        endPlayerTurn()
    }

    func unequip(slot: Int) {
        switch slot {
        case 0: if let w = run.hero.weapon { run.inventory.append(w); run.hero.weapon = nil }
        case 1: if let a = run.hero.armor { run.inventory.append(a); run.hero.armor = nil }
        case 2: if let r = run.hero.ringA { run.inventory.append(r); run.hero.ringA = nil }
        case 3: if let r = run.hero.ringB { run.inventory.append(r); run.hero.ringB = nil }
        case 4: if let t = run.hero.torch { run.inventory.append(t); run.hero.torch = nil }
        default: break
        }
        recomputeFOV()
        objectWillChange.send()
    }

    func removeOneFromInventory(_ item: FHDItem) {
        if let idx = run.inventory.firstIndex(where: { $0.id == item.id }) {
            if run.inventory[idx].quantity > 1 { run.inventory[idx].quantity -= 1 }
            else { run.inventory.remove(at: idx) }
        }
    }

    func drop(_ item: FHDItem) {
        var dropped = item
        dropped.quantity = 1
        run.ground.append(FHDGroundItem(item: dropped, pos: run.hero.pos))
        removeOneFromInventory(item)
        run.addLog("Dropped \(run.displayName(item)).", tone: 0)
        objectWillChange.send()
    }

    func upgrade(_ item: FHDItem) {
        let def = FHDCatalog.def(item.defID)
        guard def.maxUpgrade > 0 else { return }
        // requires a scroll of enchant OR gold at merchant; here used by enchant scroll.
        applyUpgrade(to: item)
    }

    func applyUpgrade(to item: FHDItem) {
        let def = FHDCatalog.def(item.defID)
        // upgrade equipped match or inventory match
        if let w = run.hero.weapon, w.id == item.id {
            if w.upgrade < def.maxUpgrade { run.hero.weapon?.upgrade += 1; run.addLog("\(def.name) glows — now +\(run.hero.weapon!.upgrade)!", tone: 4) }
        } else if let a = run.hero.armor, a.id == item.id {
            if a.upgrade < def.maxUpgrade { run.hero.armor?.upgrade += 1; run.addLog("\(def.name) hardens — now +\(run.hero.armor!.upgrade)!", tone: 4) }
        } else if let idx = run.inventory.firstIndex(where: { $0.id == item.id }) {
            if run.inventory[idx].upgrade < def.maxUpgrade { run.inventory[idx].upgrade += 1; run.addLog("\(def.name) is enchanted to +\(run.inventory[idx].upgrade)!", tone: 4) }
        }
    }

    // MARK: - Consume / use

    func useItem(_ item: FHDItem) {
        let def = FHDCatalog.def(item.defID)
        switch def.category {
        case .potion: drinkPotion(item, def: def)
        case .scroll: readScroll(item, def: def)
        case .food: eatFood(item, def: def)
        case .fuel: refuelTorch(item)
        case .weapon, .armor, .ring, .torch: equip(item); return
        case .throwable: return // throwing handled separately
        case .wand: return
        default: return
        }
        run.itemsUsed += 1
        endPlayerTurn()
    }

    func drinkPotion(_ item: FHDItem, def: FHDItemDef) {
        // identify on use
        run.identifiedPotion.insert(def.id)
        run.triedPotion.insert(def.id)
        store?.recordItemDiscovered(def.id, identified: true)
        removeOneFromInventory(item)
        guard let eff = FHDPotionEffect(rawValue: def.effect) else { return }
        switch eff {
        case .heal:
            let amt = 18 + run.floor
            run.hero.hp = min(run.hero.maxHP, run.hero.hp + amt)
            spawnFloat("+\(amt)", at: run.hero.pos, color: FHDTheme.poison)
            run.addLog("You feel restored.", tone: 4)
        case .fullHeal:
            run.hero.hp = run.hero.maxHP
            run.addLog("Wounds close completely.", tone: 4)
        case .warmth:
            changeWarmth(60, reason: "warmth potion", tone: 1)
            run.addLog("Heat surges through you.", tone: 1)
        case .strength:
            run.hero.strength += 1
            run.addLog("You feel mightier.", tone: 4)
        case .antidote:
            run.hero.poison = 0; run.hero.chill = 0
            run.addLog("Toxins and chill wash away.", tone: 4)
        case .levitation:
            run.hero.levitation = 18; run.addLog("Your feet leave the ground.", tone: 0)
        case .fireImmunity:
            run.hero.fireImmunity = 16; run.addLog("Flame cannot touch you.", tone: 1)
        case .frostWard:
            run.hero.frostWard = 20; run.addLog("Cold no longer drains you.", tone: 1)
        case .mightHaste:
            run.hero.haste = 12; run.addLog("Time seems to slow.", tone: 0)
        case .blink:
            blink(); run.addLog("Reality folds around you.", tone: 0)
        case .regen:
            run.hero.regenTurns = 30; run.addLog("Your body begins to mend.", tone: 4)
        case .clarity:
            revealMap(); run.addLog("The floor lays bare in your mind.", tone: 0)
        }
    }

    func readScroll(_ item: FHDItem, def: FHDItemDef) {
        run.identifiedScroll.insert(def.id)
        store?.recordItemDiscovered(def.id, identified: true)
        removeOneFromInventory(item)
        guard let eff = FHDScrollEffect(rawValue: def.effect) else { return }
        switch eff {
        case .identify:
            if let unId = run.inventory.first(where: { isUnidentified($0) }) {
                identifyItem(unId)
                run.addLog("You identify the \(run.displayName(unId)).", tone: 4)
            } else { run.addLog("Nothing left to identify.", tone: 0) }
        case .enchant:
            if let w = run.hero.weapon { applyUpgrade(to: w) }
            else if let a = run.hero.armor { applyUpgrade(to: a) }
            else { run.addLog("You have nothing equipped to enchant.", tone: 0) }
        case .mapReveal:
            revealMap(); run.addLog("The whole floor is revealed.", tone: 4)
        case .teleport:
            teleportToRandomRoom(); run.addLog("You vanish and reappear elsewhere.", tone: 0)
        case .ignite:
            igniteAround(); run.addLog("Flames erupt around you!", tone: 1)
        case .freezeRoom:
            for i in run.enemies.indices where run.enemies[i].pos.chebyshev(to: run.hero.pos) <= 6 {
                run.enemies[i].frozenTurns = max(run.enemies[i].frozenTurns, 4)
            }
            run.addLog("Every nearby foe freezes solid.", tone: 4)
        case .ward:
            run.hero.ward = 20; run.addLog("A protective ward surrounds you.", tone: 4)
        case .recharge:
            if let idx = run.inventory.firstIndex(where: { FHDCatalog.def($0.defID).category == .wand }) {
                run.inventory[idx].chargesLeft = FHDCatalog.def(run.inventory[idx].defID).charges
                run.addLog("Your wand hums with new charges.", tone: 4)
            } else { run.addLog("You carry no wand to recharge.", tone: 0) }
        case .summonBrazier:
            if run.tiles[run.hero.pos.y][run.hero.pos.x].type == .floor {
                placeBrazierAdjacent()
                run.addLog("A brazier roars to life nearby.", tone: 1)
            }
        case .vanishEnemies:
            run.enemies.removeAll { $0.def.maxHP <= 14 && !$0.def.isBoss }
            run.addLog("The weakest foes are banished.", tone: 4)
        case .removeCurse:
            run.addLog("A faint curse lifts from your gear.", tone: 4)
        case .knowledge:
            for it in run.inventory { identifyItem(it) }
            run.addLog("All your items are revealed.", tone: 4)
        }
        recomputeFOV()
    }

    func eatFood(_ item: FHDItem, def: FHDItemDef) {
        removeOneFromInventory(item)
        changeWarmth(def.foodWarmth, reason: def.foodWarmth >= 0 ? "warm food" : "cold food",
                     tone: def.foodWarmth >= 0 ? 1 : 2)
        run.hero.hp = min(run.hero.maxHP, run.hero.hp + def.foodHeal)
        run.addLog("You eat the \(def.name).", tone: 0)
    }

    func refuelTorch(_ item: FHDItem) {
        removeOneFromInventory(item)
        if var torch = run.hero.torch {
            torch.fuel = min(150, torch.fuel + (item.fuel > 0 ? item.fuel : 60))
            run.hero.torch = torch
        } else {
            var t = FHDItem(defID: FHDCatalog.torch.id)
            t.fuel = item.fuel > 0 ? item.fuel : 60
            run.hero.torch = t
        }
        run.addLog("You refuel your torch.", tone: 1)
        recomputeFOV()
    }

    // MARK: - Throwables & wands (targeted at nearest enemy)

    func throwItem(_ item: FHDItem) {
        let def = FHDCatalog.def(item.defID)
        guard let target = nearestEnemy() else { run.addLog("No target in sight.", tone: 0); return }
        removeOneFromInventory(item)
        run.itemsUsed += 1
        guard let eff = FHDThrowEffect(rawValue: def.throwEffect) else { endPlayerTurn(); return }
        switch eff {
        case .firebomb:
            areaDamage(center: target.pos, radius: 1, amount: def.throwDamage, burn: true)
            // ignite ice/oil tiles
            for dy in -1...1 { for dx in -1...1 {
                let p = FHDPoint(x: target.pos.x+dx, y: target.pos.y+dy)
                if inBounds(p) && (run.tiles[p.y][p.x].type == .thinIce || run.tiles[p.y][p.x].type == .crackedIce) {
                    run.tiles[p.y][p.x].type = .water
                }
            }}
            run.addLog("The firebomb bursts into flame!", tone: 1)
        case .frostbomb:
            for i in run.enemies.indices where run.enemies[i].pos.chebyshev(to: target.pos) <= 1 {
                run.enemies[i].frozenTurns = max(run.enemies[i].frozenTurns, 3)
                run.enemies[i].hp -= def.throwDamage
            }
            run.enemies.removeAll { $0.hp <= 0 }
            run.addLog("Ice locks your foes in place.", tone: 4)
        case .oilflask:
            run.addLog("Oil spreads across the floor.", tone: 0)
        case .smoke:
            for i in run.enemies.indices where run.enemies[i].pos.chebyshev(to: target.pos) <= 2 {
                run.enemies[i].aware = false
            }
            run.addLog("Smoke billows; foes lose sight of you.", tone: 4)
        }
        endPlayerTurn()
    }

    func zapWand(_ item: FHDItem) {
        let def = FHDCatalog.def(item.defID)
        guard item.chargesLeft > 0 else { run.addLog("The wand is spent.", tone: 0); return }
        guard let target = nearestEnemy(maxRange: def.wandRange) else { run.addLog("No target in range.", tone: 0); return }
        if let idx = run.inventory.firstIndex(where: { $0.id == item.id }) {
            run.inventory[idx].chargesLeft -= 1
        }
        run.itemsUsed += 1
        guard let eff = FHDWandEffect(rawValue: def.effect) else { endPlayerTurn(); return }
        guard let ei = run.enemies.firstIndex(where: { $0.id == target.id }) else { endPlayerTurn(); return }
        switch eff {
        case .firebolt:
            run.enemies[ei].hp -= 16; run.enemies[ei].burningTurns = 3
            spawnFloat("-16", at: target.pos, color: FHDTheme.torch)
        case .frostbolt:
            run.enemies[ei].hp -= 8; run.enemies[ei].frozenTurns = 3
            spawnFloat("-8", at: target.pos, color: FHDTheme.iceCyan)
        case .drain:
            run.enemies[ei].hp -= 10
            changeWarmth(15, reason: "warmth drain", tone: 1)
            spawnFloat("-10", at: target.pos, color: FHDTheme.ember)
        case .push:
            let dir = pushDirection(from: run.hero.pos, to: target.pos)
            var np = target.pos
            for _ in 0..<3 { let cand = np + dir; if canPushInto(cand) { np = cand } else { break } }
            run.enemies[ei].pos = np
            run.enemies[ei].hp -= 4
        case .ember:
            placeBrazierAdjacent()
            run.addLog("Warm coals scatter around you.", tone: 1)
        case .polymorph:
            run.enemies[ei].polymorphed = true
            run.enemies[ei].hp = min(run.enemies[ei].hp, 6)
            run.addLog("The \(target.def.name) is transformed!", tone: 4)
        }
        if ei < run.enemies.count && run.enemies[ei].hp <= 0 {
            killEnemy(at: ei, edef: run.enemies[ei].def)
        }
        endPlayerTurn()
    }

    // MARK: - Helpers

    func isUnidentified(_ item: FHDItem) -> Bool {
        let def = FHDCatalog.def(item.defID)
        if def.category == .potion { return !run.identifiedPotion.contains(def.id) }
        if def.category == .scroll { return !run.identifiedScroll.contains(def.id) }
        return false
    }

    func identifyItem(_ item: FHDItem) {
        let def = FHDCatalog.def(item.defID)
        if def.category == .potion { run.identifiedPotion.insert(def.id) }
        if def.category == .scroll { run.identifiedScroll.insert(def.id) }
        store?.recordItemDiscovered(def.id, identified: true)
    }

    func nearestEnemy(maxRange: Int = 99) -> FHDEnemy? {
        var best: FHDEnemy? = nil
        var bestD = maxRange + 1
        for e in run.enemies {
            if e.disguised && e.def.ai == .iceMimic { continue }
            let d = e.pos.manhattan(to: run.hero.pos)
            if d <= maxRange && d < bestD && hasLOS(run.hero.pos, e.pos) {
                bestD = d; best = e
            }
        }
        return best
    }

    func areaDamage(center: FHDPoint, radius: Int, amount: Int, burn: Bool) {
        for i in run.enemies.indices {
            if run.enemies[i].pos.chebyshev(to: center) <= radius {
                run.enemies[i].hp -= amount
                if burn { run.enemies[i].burningTurns = 3 }
                spawnFloat("-\(amount)", at: run.enemies[i].pos, color: FHDTheme.torch)
            }
        }
        // resolve deaths
        var i = 0
        while i < run.enemies.count {
            if run.enemies[i].hp <= 0 { killEnemy(at: i, edef: run.enemies[i].def) }
            else { i += 1 }
        }
    }

    func blink() {
        // teleport up to 5 tiles in a random valid direction
        for _ in 0..<20 {
            let dx = Int.random(in: -5...5), dy = Int.random(in: -5...5)
            let p = FHDPoint(x: run.hero.pos.x + dx, y: run.hero.pos.y + dy)
            if inBounds(p) && run.tiles[p.y][p.x].type.isWalkable && !run.enemies.contains(where: { $0.pos == p }) {
                run.hero.pos = p; recomputeFOV(); return
            }
        }
    }

    func teleportToRandomRoom() {
        guard !run.rooms.isEmpty else { return }
        let r = run.rooms[Int.random(in: 0..<run.rooms.count)]
        let p = FHDPoint(x: r.cx, y: r.cy)
        if inBounds(p) && run.tiles[p.y][p.x].type.isWalkable { run.hero.pos = p; recomputeFOV() }
    }

    func revealMap() {
        for y in 0..<run.tiles.count { for x in 0..<run.tiles[0].count { run.tiles[y][x].discovered = true } }
    }

    func igniteAround() {
        for i in run.enemies.indices where run.enemies[i].pos.chebyshev(to: run.hero.pos) <= 2 {
            run.enemies[i].burningTurns = 4
            run.enemies[i].hp -= 6
        }
        var i = 0
        while i < run.enemies.count {
            if run.enemies[i].hp <= 0 { killEnemy(at: i, edef: run.enemies[i].def) } else { i += 1 }
        }
        changeWarmth(20, reason: "ignite warmth", tone: 1)
    }

    func placeBrazierAdjacent() {
        if let p = freeAdjacent(to: run.hero.pos) {
            run.tiles[p.y][p.x].type = .brazier
        } else if run.tiles[run.hero.pos.y][run.hero.pos.x].type == .floor {
            // place on a neighbor floor anyway
        }
    }

    func deployBrazier() {
        // Tinker class perk
        guard run.hero.classID == .tinker, run.hero.braziersLeft > 0 else {
            run.addLog("No braziers left to deploy.", tone: 0); return
        }
        run.hero.braziersLeft -= 1
        run.tiles[run.hero.pos.y][run.hero.pos.x].type = .brazier
        run.addLog("You build a field brazier. (\(run.hero.braziersLeft) left)", tone: 1)
        store?.unlockAchievement(.tinkerBrazier)
        endPlayerTurn()
    }

    func pushDirection(from a: FHDPoint, to b: FHDPoint) -> FHDPoint {
        let dx = b.x - a.x, dy = b.y - a.y
        if abs(dx) >= abs(dy) { return FHDPoint(x: dx == 0 ? 0 : (dx > 0 ? 1 : -1), y: 0) }
        return FHDPoint(x: 0, y: dy == 0 ? 0 : (dy > 0 ? 1 : -1))
    }

    func canPushInto(_ p: FHDPoint) -> Bool {
        inBounds(p) && run.tiles[p.y][p.x].type.isWalkable && !run.enemies.contains(where: { $0.pos == p }) && p != run.hero.pos
    }

    // Player ranged shot (bow) — fired at nearest enemy in line.
    func fireBow() {
        guard let w = run.hero.weapon, FHDCatalog.def(w.defID).wandRange > 0 else {
            run.addLog("You have no ranged weapon.", tone: 0); return
        }
        let range = FHDCatalog.def(w.defID).wandRange
        guard let target = nearestEnemy(maxRange: range) else { run.addLog("No target in range.", tone: 0); return }
        guard let ei = run.enemies.firstIndex(where: { $0.id == target.id }) else { return }
        let dmg = max(1, playerAttackPower() - target.def.defense)
        run.enemies[ei].hp -= dmg
        run.enemies[ei].aware = true
        spawnFloat("-\(dmg)", at: target.pos, color: FHDTheme.blood)
        run.addLog("Your arrow strikes the \(target.def.name) for \(dmg).", tone: 0)
        if run.enemies[ei].hp <= 0 { killEnemy(at: ei, edef: target.def) }
        endPlayerTurn()
    }
}
