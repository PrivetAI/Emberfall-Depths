import Foundation

extension FHDEngine {

    // Run all enemies' turns after the player acts.
    func runEnemyTurns() {
        // Snapshot order; mutate run.enemies as we go.
        var i = 0
        while i < run.enemies.count {
            if !run.alive { return }
            if i >= run.enemies.count { break }
            var e = run.enemies[i]

            // frozen — skip but tick down
            if e.frozenTurns > 0 {
                e.frozenTurns -= 1
                run.enemies[i] = e
                i += 1
                continue
            }
            // burning damage
            if e.burningTurns > 0 {
                e.burningTurns -= 1
                e.hp -= 3
                if e.hp <= 0 {
                    run.enemies.remove(at: i)
                    run.kills += 1
                    continue
                }
            }
            // slow speed: act every other tick
            if e.def.speed >= 2 {
                e.slowTick.toggle()
                if e.slowTick { run.enemies[i] = e; i += 1; continue }
            }
            // polymorphed enemies are harmless and wander
            if e.polymorphed {
                wander(&e)
                run.enemies[i] = e; i += 1; continue
            }

            // awareness
            let distToPlayer = e.pos.chebyshev(to: run.hero.pos)
            if !e.aware {
                if e.def.ai == .iceMimic && e.disguised { run.enemies[i] = e; i += 1; continue }
                if distToPlayer <= e.def.sight && hasLOS(e.pos, run.hero.pos) {
                    e.aware = true
                    run.encounteredEnemyIDs.insert(e.def.id)
                    store?.recordEnemyDefeated(e.def.id, justSeen: true)
                }
            }

            if e.aware {
                act(&e, index: i)
            }
            // write back if still present at i
            if i < run.enemies.count && run.enemies[i].id == e.id {
                run.enemies[i] = e
            }
            i += 1
        }
    }

    func hasLOS(_ a: FHDPoint, _ b: FHDPoint) -> Bool { lineOfSight(from: a, to: b) }

    private func act(_ e: inout FHDEnemy, index: Int) {
        switch e.def.ai {
        case .chase, .erratic, .iceMimic, .splitter, .ambushIce:
            meleeBehavior(&e)
        case .packHunter, .wendigo, .sentry:
            meleeBehavior(&e, kind: e.def.ai)
        case .rangedKiter:
            rangedBehavior(&e)
        case .frostDrainer:
            drainerBehavior(&e)
        case .shardThief:
            thiefBehavior(&e)
        case .healer:
            healerBehavior(&e)
        case .bossPattern:
            bossBehavior(&e, index: index)
        }
    }

    // MARK: Behaviors

    private func meleeBehavior(_ e: inout FHDEnemy, kind: FHDAIKind = .chase) {
        let d = e.pos.chebyshev(to: run.hero.pos)
        if d <= 1 {
            attackPlayer(from: e)
            return
        }
        // wendigo: faster (double-step) when player cold
        var steps = 1
        if kind == .wendigo && run.hero.warmth < run.hero.warmthCap / 3 { steps = 2 }
        // pack hunter: only advances if allies nearby OR already close
        if kind == .packHunter {
            let allies = run.enemies.filter { $0.def.id == e.def.id && $0.pos.chebyshev(to: e.pos) <= 4 }.count
            if allies < 2 && d > 4 { wander(&e); return }
        }
        for _ in 0..<steps {
            stepToward(&e, target: run.hero.pos)
            if e.pos.chebyshev(to: run.hero.pos) <= 1 { attackPlayer(from: e); break }
        }
    }

    private func rangedBehavior(_ e: inout FHDEnemy) {
        let d = e.pos.manhattan(to: run.hero.pos)
        let range = e.def.rangedRange
        if d <= range && hasLOS(e.pos, run.hero.pos) {
            // kite: if player too close, step away; else shoot
            if e.pos.chebyshev(to: run.hero.pos) <= 1 {
                stepAway(&e, from: run.hero.pos)
            } else {
                shootPlayer(from: e)
            }
        } else {
            stepToward(&e, target: run.hero.pos)
        }
    }

    private func drainerBehavior(_ e: inout FHDEnemy) {
        // approaches but mostly drains via aura (handled in tickHero); occasionally melee
        let d = e.pos.chebyshev(to: run.hero.pos)
        if d <= 1 { attackPlayer(from: e) }
        else { stepToward(&e, target: run.hero.pos) }
    }

    private func thiefBehavior(_ e: inout FHDEnemy) {
        if e.fleeing {
            stepAway(&e, from: run.hero.pos)
            return
        }
        let d = e.pos.chebyshev(to: run.hero.pos)
        if d <= 1 {
            // steal gold
            let steal = min(run.hero.gold, 10 + run.floor * 2)
            if steal > 0 {
                run.hero.gold -= steal
                e.stolenGold += steal
                e.fleeing = true
                run.addLog("The Shard Thief snatches \(steal) gold and flees!", tone: 3)
            } else {
                attackPlayer(from: e)
            }
        } else {
            stepToward(&e, target: run.hero.pos)
        }
    }

    private func healerBehavior(_ e: inout FHDEnemy) {
        // heal a wounded ally in range; otherwise keep distance from player
        if let idx = run.enemies.firstIndex(where: { $0.id != e.id && $0.hp < $0.def.maxHP && $0.pos.chebyshev(to: e.pos) <= 3 }) {
            run.enemies[idx].hp = min(run.enemies[idx].def.maxHP, run.enemies[idx].hp + 5)
            spawnFloat("+5", at: run.enemies[idx].pos, color: FHDTheme.poison)
            return
        }
        if e.pos.chebyshev(to: run.hero.pos) < 3 { stepAway(&e, from: run.hero.pos) }
        else { wander(&e) }
    }

    private func bossBehavior(_ e: inout FHDEnemy, index: Int) {
        // two-phase: switch at half HP
        if e.phase == 1 && e.hp <= e.def.maxHP / 2 {
            e.phase = 2
            run.addLog("The \(e.def.name) enters a furious second phase!", tone: 3)
            bossPhaseTwoOnset(&e)
        }
        let d = e.pos.chebyshev(to: run.hero.pos)
        // ranged bosses pelt; melee bosses close
        if e.def.rangedRange > 0 && e.pos.manhattan(to: run.hero.pos) <= e.def.rangedRange && hasLOS(e.pos, run.hero.pos) {
            if d <= 1 { attackPlayer(from: e) } else { shootPlayer(from: e) }
        } else if d <= 1 {
            attackPlayer(from: e)
        } else {
            stepToward(&e, target: run.hero.pos)
        }
        // phase-two summon for some bosses
        if e.phase == 2 && run.turnCount % 6 == 0 {
            bossSummon(e)
        }
    }

    private func bossPhaseTwoOnset(_ e: inout FHDEnemy) {
        switch e.def.id {
        case 102: // Forgemaster — rains lava near player
            for d in FHDDir.allCases {
                let p = run.hero.pos + d.delta
                if inBounds(p) && run.tiles[p.y][p.x].type == .floor { run.tiles[p.y][p.x].type = .lava }
            }
        case 104: // Whiteout King — dims light (chills hard)
            changeWarmth(-20, reason: "frost storm", tone: 3)
        default: break
        }
    }

    private func bossSummon(_ e: FHDEnemy) {
        let roster = FHDBestiary.roster(forFloor: run.floor)
        guard let summonID = roster.first else { return }
        if run.enemies.count > 14 { return }
        if let np = freeAdjacent(to: e.pos) {
            var minion = FHDEnemy(defID: summonID, pos: np, hp: FHDBestiary.def(summonID).maxHP)
            minion.aware = true
            run.enemies.append(minion)
        }
    }

    // MARK: Movement primitives

    private func stepToward(_ e: inout FHDEnemy, target: FHDPoint) {
        let best = bestStep(from: e.pos, toward: target, away: false)
        if let np = best { e.pos = np }
    }
    private func stepAway(_ e: inout FHDEnemy, from: FHDPoint) {
        let best = bestStep(from: e.pos, toward: from, away: true)
        if let np = best { e.pos = np }
    }
    private func wander(_ e: inout FHDEnemy) {
        let dirs = FHDDir.allCases.shuffledStable(e.pos)
        for d in dirs {
            let np = e.pos + d.delta
            if canEnemyEnter(np) { e.pos = np; return }
        }
    }

    private func bestStep(from: FHDPoint, toward target: FHDPoint, away: Bool) -> FHDPoint? {
        var best: FHDPoint? = nil
        var bestScore = away ? Int.min : Int.max
        for d in FHDDir.allCases {
            let np = from + d.delta
            if !canEnemyEnter(np) { continue }
            let dist = np.manhattan(to: target)
            if away {
                if dist > bestScore { bestScore = dist; best = np }
            } else {
                if dist < bestScore { bestScore = dist; best = np }
            }
        }
        return best
    }

    private func canEnemyEnter(_ p: FHDPoint) -> Bool {
        if !inBounds(p) { return false }
        let t = run.tiles[p.y][p.x].type
        if !t.isWalkable { return false }
        if t == .lockedDoor { return false }
        if p == run.hero.pos { return false }
        if run.enemies.contains(where: { $0.pos == p }) { return false }
        return true
    }

    // MARK: Enemy attacks

    private func attackPlayer(from e: FHDEnemy) {
        let dmg = e.def.damage + run.floor / 4
        // chill on hit from frost enemies
        if e.def.affinity == .frost {
            run.hero.chill = max(run.hero.chill, 2)
            if Bool.random() { changeWarmth(-2, reason: "frost touch", tone: 2) }
        }
        damageHero(dmg, source: "the \(e.def.name)")
        run.addLog("The \(e.def.name) strikes you.", tone: 3)
    }

    private func shootPlayer(from e: FHDEnemy) {
        let dmg = e.def.damage + run.floor / 5
        if e.def.affinity == .frost { changeWarmth(-2, reason: "frost bolt", tone: 2) }
        damageHero(dmg, source: "the \(e.def.name)")
        run.addLog("The \(e.def.name) strikes from afar.", tone: 3)
    }
}
