import Foundation

// A generated floor: tiles, entities, items on ground, start/down positions.
struct FHDFloorData {
    var tiles: [[FHDTile]]
    var width: Int
    var height: Int
    var startPos: FHDPoint
    var downPos: FHDPoint
    var enemies: [FHDEnemy]
    var groundItems: [FHDGroundItem]
    var rooms: [FHDRoom]
    var biome: FHDBiome
    var floor: Int
    var hasSecretRoom: Bool
    var hasHeatVault: Bool
    var hasMerchant: Bool
    var lockedDoors: Int
}

struct FHDRoom {
    var x: Int, y: Int, w: Int, h: Int
    var kind: Kind
    enum Kind { case normal, secret, heatVault, merchant, boss, entry }
    var cx: Int { x + w / 2 }
    var cy: Int { y + h / 2 }
    var center: FHDPoint { FHDPoint(x: cx, y: cy) }
    func contains(_ p: FHDPoint) -> Bool { p.x >= x && p.x < x + w && p.y >= y && p.y < y + h }
}

struct FHDGroundItem: Codable, Identifiable {
    var id = UUID()
    var item: FHDItem
    var pos: FHDPoint
}

// MARK: - Generator

enum FHDGenerator {

    // Deterministically build a floor from a seed.
    static func generate(floor: Int, seed: UInt64) -> FHDFloorData {
        let biome = FHDBiome.forFloor(floor)
        var rng = FHDRandom(seed: seed)
        let w = FHDConst.mapW, h = FHDConst.mapH

        // Up to a few attempts to ensure connectivity. With corridor carving
        // between consecutive rooms, connectivity is guaranteed, but we still
        // BFS-validate as a safety net.
        for _ in 0..<6 {
            var tiles = Array(repeating: Array(repeating: FHDTile(type: .wall), count: w), count: h)
            var rooms: [FHDRoom] = []

            let isBoss = FHDConst.bossFloors.contains(floor)
            let isMerchant = FHDConst.merchantFloors.contains(floor)

            // Place rooms.
            let targetRooms = isBoss ? 6 : rng.int(8...12)
            var attempts = 0
            while rooms.count < targetRooms && attempts < 200 {
                attempts += 1
                let rw = rng.int(5...9)
                let rh = rng.int(4...7)
                let rx = rng.int(1..<(w - rw - 1))
                let ry = rng.int(1..<(h - rh - 1))
                let cand = FHDRoom(x: rx, y: ry, w: rw, h: rh, kind: .normal)
                // No overlap with 1-tile margin.
                var overlap = false
                for r in rooms {
                    if rx < r.x + r.w + 1 && rx + rw + 1 > r.x &&
                       ry < r.y + r.h + 1 && ry + rh + 1 > r.y { overlap = true; break }
                }
                if overlap { continue }
                rooms.append(cand)
            }
            if rooms.count < 3 { continue }

            // Carve rooms.
            for r in rooms {
                for yy in r.y..<(r.y + r.h) {
                    for xx in r.x..<(r.x + r.w) {
                        tiles[yy][xx].type = .floor
                    }
                }
            }

            // Connect consecutive rooms with L-corridors (guarantees a spanning path).
            for i in 1..<rooms.count {
                carveCorridor(&tiles, from: rooms[i - 1].center, to: rooms[i].center, rng: &rng)
            }
            // A couple of extra loops for variety.
            let extra = rng.int(1...3)
            for _ in 0..<extra {
                let a = rng.int(0..<rooms.count)
                let b = rng.int(0..<rooms.count)
                if a != b { carveCorridor(&tiles, from: rooms[a].center, to: rooms[b].center, rng: &rng) }
            }

            // Assign special rooms.
            var entryRoom = 0
            var downRoom = rooms.count - 1
            // Make sure entry and down are reasonably far apart.
            if rooms.count >= 2 {
                entryRoom = 0
                downRoom = farthestRoomIndex(from: rooms[entryRoom].center, rooms: rooms)
            }
            rooms[entryRoom].kind = .entry
            if isBoss { rooms[downRoom].kind = .boss }

            let startPos = rooms[entryRoom].center
            let downPos = rooms[downRoom].center
            tiles[downPos.y][downPos.x].type = .stairsDown
            tiles[startPos.y][startPos.x].type = .stairsUp

            // Heat vault (warmth refill room) — sometimes.
            var hasHeatVault = false
            if !isBoss && rng.chance(0.5) {
                if let vi = pickRoom(rooms, exclude: [entryRoom, downRoom], rng: &rng) {
                    rooms[vi].kind = .heatVault
                    hasHeatVault = true
                    let c = rooms[vi].center
                    tiles[c.y][c.x].type = .heatVault
                    // a ring of braziers
                    for d in FHDDir.allCases {
                        let p = c + d.delta
                        if inBounds(p, w, h) && tiles[p.y][p.x].type == .floor {
                            tiles[p.y][p.x].type = .brazier
                        }
                    }
                }
            }

            // Merchant room.
            var hasMerchant = false
            if isMerchant {
                if let mi = pickRoom(rooms, exclude: [entryRoom, downRoom], rng: &rng) {
                    rooms[mi].kind = .merchant
                    hasMerchant = true
                    let c = rooms[mi].center
                    tiles[c.y][c.x].type = .merchantPad
                }
            }

            // Secret room — carved off a normal room, hidden behind a secretWall.
            var hasSecretRoom = false
            if !isBoss && rng.chance(0.55) {
                if let si = pickRoom(rooms, exclude: [entryRoom, downRoom], rng: &rng) {
                    if let secret = attachSecretRoom(&tiles, near: rooms[si], w: w, h: h, rng: &rng) {
                        rooms.append(secret)
                        hasSecretRoom = true
                    }
                }
            }

            // Hazards by biome.
            scatterHazards(&tiles, rooms: rooms, biome: biome,
                           entry: entryRoom, down: downRoom, rng: &rng)

            // Locked doors + keys (revert if unplaceable).
            var lockedDoors = 0
            if !isBoss && rng.chance(0.45) {
                lockedDoors = placeLockedDoorsAndKeys(&tiles, rooms: rooms,
                                                      entry: rooms[entryRoom].center,
                                                      down: downPos, w: w, h: h, rng: &rng)
            }

            // BFS connectivity validation: start must reach down.
            if !bfsReachable(tiles: tiles, from: startPos, to: downPos, w: w, h: h) {
                continue // regenerate
            }

            // Place enemies & items.
            var enemies: [FHDEnemy] = []
            var ground: [FHDGroundItem] = []
            populate(&enemies, &ground, tiles: tiles, rooms: rooms,
                     entryRoom: entryRoom, downRoom: downRoom,
                     floor: floor, biome: biome, isBoss: isBoss,
                     hasHeatVault: hasHeatVault, rng: &rng)

            return FHDFloorData(tiles: tiles, width: w, height: h, startPos: startPos,
                                downPos: downPos, enemies: enemies, groundItems: ground,
                                rooms: rooms, biome: biome, floor: floor,
                                hasSecretRoom: hasSecretRoom, hasHeatVault: hasHeatVault,
                                hasMerchant: hasMerchant, lockedDoors: lockedDoors)
        }

        // Fallback: a guaranteed-simple two-room floor (should essentially never happen).
        return fallbackFloor(floor: floor, biome: biome, seed: seed)
    }

    // MARK: helpers

    static func inBounds(_ p: FHDPoint, _ w: Int, _ h: Int) -> Bool {
        p.x >= 0 && p.x < w && p.y >= 0 && p.y < h
    }

    static func carveCorridor(_ tiles: inout [[FHDTile]], from a: FHDPoint, to b: FHDPoint, rng: inout FHDRandom) {
        var x = a.x, y = a.y
        let horizFirst = rng.chance(0.5)
        func carve(_ px: Int, _ py: Int) {
            if py >= 0 && py < tiles.count && px >= 0 && px < tiles[0].count {
                if tiles[py][px].type == .wall { tiles[py][px].type = .floor }
            }
        }
        if horizFirst {
            while x != b.x { x += x < b.x ? 1 : -1; carve(x, y) }
            while y != b.y { y += y < b.y ? 1 : -1; carve(x, y) }
        } else {
            while y != b.y { y += y < b.y ? 1 : -1; carve(x, y) }
            while x != b.x { x += x < b.x ? 1 : -1; carve(x, y) }
        }
    }

    static func farthestRoomIndex(from p: FHDPoint, rooms: [FHDRoom]) -> Int {
        var best = 0; var bestD = -1
        for (i, r) in rooms.enumerated() {
            let d = p.manhattan(to: r.center)
            if d > bestD { bestD = d; best = i }
        }
        return best
    }

    static func pickRoom(_ rooms: [FHDRoom], exclude: [Int], rng: inout FHDRandom) -> Int? {
        let candidates = (0..<rooms.count).filter { !exclude.contains($0) && rooms[$0].kind == .normal }
        if candidates.isEmpty { return nil }
        return candidates[rng.int(0..<candidates.count)]
    }

    static func attachSecretRoom(_ tiles: inout [[FHDTile]], near room: FHDRoom, w: Int, h: Int, rng: inout FHDRandom) -> FHDRoom? {
        // Try to place a small room adjacent and connect via secretWall.
        let sw = 4, sh = 4
        let candidates: [(FHDRoom, FHDPoint)] = [
            (FHDRoom(x: room.x + room.w + 1, y: room.y, w: sw, h: sh, kind: .secret), FHDPoint(x: room.x + room.w, y: room.y + 1)),
            (FHDRoom(x: room.x - sw - 1, y: room.y, w: sw, h: sh, kind: .secret), FHDPoint(x: room.x - 1, y: room.y + 1)),
            (FHDRoom(x: room.x, y: room.y + room.h + 1, w: sw, h: sh, kind: .secret), FHDPoint(x: room.x + 1, y: room.y + room.h)),
            (FHDRoom(x: room.x, y: room.y - sh - 1, w: sw, h: sh, kind: .secret), FHDPoint(x: room.x + 1, y: room.y - 1)),
        ]
        for (sr, wallPt) in rng.shuffled(candidates) {
            if sr.x < 1 || sr.y < 1 || sr.x + sr.w >= w - 1 || sr.y + sr.h >= h - 1 { continue }
            // ensure space is currently wall
            var clear = true
            for yy in (sr.y - 1)...(sr.y + sr.h) {
                for xx in (sr.x - 1)...(sr.x + sr.w) {
                    if yy < 0 || xx < 0 || yy >= h || xx >= w { clear = false; break }
                    if tiles[yy][xx].type != .wall { clear = false; break }
                }
                if !clear { break }
            }
            if !clear { continue }
            for yy in sr.y..<(sr.y + sr.h) {
                for xx in sr.x..<(sr.x + sr.w) { tiles[yy][xx].type = .floor }
            }
            if inBounds(wallPt, w, h) { tiles[wallPt.y][wallPt.x].type = .secretWall }
            // reward in the secret room: a brazier
            let c = FHDPoint(x: sr.x + sr.w/2, y: sr.y + sr.h/2)
            tiles[c.y][c.x].type = .brazier
            return sr
        }
        return nil
    }

    static func scatterHazards(_ tiles: inout [[FHDTile]], rooms: [FHDRoom], biome: FHDBiome,
                               entry: Int, down: Int, rng: inout FHDRandom) {
        for (i, r) in rooms.enumerated() {
            if r.kind != .normal { continue }
            if i == entry { continue }
            for yy in r.y..<(r.y + r.h) {
                for xx in r.x..<(r.x + r.w) {
                    if tiles[yy][xx].type != .floor { continue }
                    let roll = rng.double()
                    var acc = 0.0
                    acc += biome.thinIceChance
                    if roll < acc { tiles[yy][xx].type = .thinIce; continue }
                    acc += biome.lavaChance
                    if roll < acc { tiles[yy][xx].type = .lava; continue }
                    acc += biome.sporeChance
                    if roll < acc { tiles[yy][xx].type = .frostSpore; continue }
                    acc += biome.steamChance
                    if roll < acc { tiles[yy][xx].type = .steamJet; continue }
                    acc += biome.waterChance
                    if roll < acc { tiles[yy][xx].type = .water; continue }
                }
            }
            // A brazier in some rooms for warmth.
            if rng.chance(biome.brazierChance) {
                let bx = rng.int(r.x..<(r.x + r.w))
                let by = rng.int(r.y..<(r.y + r.h))
                if tiles[by][bx].type == .floor { tiles[by][bx].type = .brazier }
            }
            // Meltwater pools in forge.
            if biome == .forge && rng.chance(0.3) {
                let bx = rng.int(r.x..<(r.x + r.w))
                let by = rng.int(r.y..<(r.y + r.h))
                if tiles[by][bx].type == .floor { tiles[by][bx].type = .meltwater }
            }
        }
    }

    static func placeLockedDoorsAndKeys(_ tiles: inout [[FHDTile]], rooms: [FHDRoom],
                                        entry: FHDPoint, down: FHDPoint, w: Int, h: Int,
                                        rng: inout FHDRandom) -> Int {
        // Find a corridor tile to lock; place a key in an already-reachable room.
        // We snapshot, try to lock, then BFS-check key->door reachability; revert if unplaceable.
        var placed = 0
        let maxDoors = 2
        for _ in 0..<maxDoors {
            // candidate door tiles: floor tiles with exactly 2 opposite walkable neighbors (a pinch point)
            var candidates: [FHDPoint] = []
            for y in 1..<(h - 1) {
                for x in 1..<(w - 1) {
                    if tiles[y][x].type != .floor { continue }
                    let p = FHDPoint(x: x, y: y)
                    if p == entry || p == down { continue }
                    let up = tiles[y-1][x].type.isWalkable
                    let dn = tiles[y+1][x].type.isWalkable
                    let lf = tiles[y][x-1].type.isWalkable
                    let rt = tiles[y][x+1].type.isWalkable
                    let isVPinch = up && dn && !lf && !rt
                    let isHPinch = lf && rt && !up && !dn
                    if isVPinch || isHPinch { candidates.append(p) }
                }
            }
            if candidates.isEmpty { break }
            let door = candidates[rng.int(0..<candidates.count)]
            let original = tiles[door.y][door.x].type
            tiles[door.y][door.x].type = .lockedDoor
            // Door must not fully block entry->down (otherwise the key would be behind it
            // unreachable). Place the key on the entry side.
            if !bfsReachable(tiles: tiles, from: entry, to: down, w: w, h: h) {
                // Door is the only path. Keep it (intended), and ensure key is on entry side.
                // Find a floor tile reachable from entry WITHOUT crossing the door.
                let reachable = bfsRegion(tiles: tiles, from: entry, w: w, h: h)
                let keySpots = reachable.filter { $0 != entry && tiles[$0.y][$0.x].type == .floor }
                if keySpots.isEmpty {
                    tiles[door.y][door.x].type = original // revert: unplaceable
                    continue
                }
                let keyPt = keySpots[rng.int(0..<keySpots.count)]
                tiles[keyPt.y][keyPt.x] = FHDTile(type: tiles[keyPt.y][keyPt.x].type)
                // store key location via a marker tile we don't have; instead place key item later.
                lockedKeySpots.append(keyPt)
                placed += 1
            } else {
                // Door is optional (loop exists). Place a key reachable anywhere.
                let reachable = bfsRegion(tiles: tiles, from: entry, w: w, h: h)
                let keySpots = reachable.filter { $0 != entry && $0 != down && tiles[$0.y][$0.x].type == .floor }
                if keySpots.isEmpty { tiles[door.y][door.x].type = original; continue }
                lockedKeySpots.append(keySpots[rng.int(0..<keySpots.count)])
                placed += 1
            }
        }
        return placed
    }

    // Key spots collected during locked-door placement (consumed in populate).
    static var lockedKeySpots: [FHDPoint] = []

    static func populate(_ enemies: inout [FHDEnemy], _ ground: inout [FHDGroundItem],
                         tiles: [[FHDTile]], rooms: [FHDRoom],
                         entryRoom: Int, downRoom: Int,
                         floor: Int, biome: FHDBiome, isBoss: Bool,
                         hasHeatVault: Bool, rng: inout FHDRandom) {
        let w = tiles[0].count, h = tiles.count

        func freeFloor(in r: FHDRoom) -> FHDPoint? {
            var spots: [FHDPoint] = []
            for yy in r.y..<(r.y + r.h) {
                for xx in r.x..<(r.x + r.w) {
                    if tiles[yy][xx].type == .floor { spots.append(FHDPoint(x: xx, y: yy)) }
                }
            }
            if spots.isEmpty { return nil }
            return spots[rng.int(0..<spots.count)]
        }

        // Keys from locked doors.
        for kp in lockedKeySpots {
            ground.append(FHDGroundItem(item: FHDItem(defID: FHDCatalog.key.id), pos: kp))
        }
        lockedKeySpots.removeAll()

        if isBoss {
            // Boss in the boss/down room.
            let bossID = FHDBestiary.bossForFloor[floor] ?? 100
            let bdef = FHDBestiary.def(bossID)
            let bossRoom = rooms.first(where: { $0.kind == .boss }) ?? rooms[downRoom]
            if let bp = freeFloor(in: bossRoom) {
                enemies.append(FHDEnemy(defID: bossID, pos: bp, hp: bdef.maxHP))
            }
            // a healing potion guaranteed before boss
            if let pp = freeFloor(in: rooms[entryRoom]) {
                ground.append(FHDGroundItem(item: FHDItem(defID: 311), pos: pp))
            }
        } else {
            // Enemies scale with floor.
            let roster = FHDBestiary.roster(forFloor: floor)
            let count = 4 + floor / 2 + rng.int(0...3)
            for _ in 0..<count {
                let ri = rng.int(0..<rooms.count)
                if ri == entryRoom { continue }
                if rooms[ri].kind == .merchant || rooms[ri].kind == .secret { continue }
                guard let p = freeFloor(in: rooms[ri]) else { continue }
                if tiles[p.y][p.x].type != .floor { continue }
                let eid = roster[rng.int(0..<roster.count)]
                let edef = FHDBestiary.def(eid)
                enemies.append(FHDEnemy(defID: eid, pos: p, hp: edef.maxHP))
            }
        }

        // Loot: weapons/armor/potions/scrolls/etc by floor depth.
        let lootCount = 4 + floor / 3 + rng.int(0...2)
        for _ in 0..<lootCount {
            let ri = rng.int(0..<rooms.count)
            if rooms[ri].kind == .entry { continue }
            guard let p = freeFloor(in: rooms[ri]) else { continue }
            if tiles[p.y][p.x].type != .floor { continue }
            let item = rollLoot(floor: floor, rng: &rng)
            ground.append(FHDGroundItem(item: item, pos: p))
        }

        // Heat vault reward: a torch + fuel.
        if hasHeatVault, let vault = rooms.first(where: { $0.kind == .heatVault }), let p = freeFloor(in: vault) {
            ground.append(FHDGroundItem(item: FHDItem(defID: FHDCatalog.fuel.id, fuel: 60), pos: p))
        }

        // Some gold piles.
        for _ in 0..<(2 + floor / 4) {
            let ri = rng.int(0..<rooms.count)
            guard let p = freeFloor(in: rooms[ri]) else { continue }
            if tiles[p.y][p.x].type != .floor { continue }
            let amt = rng.int(5...(15 + floor * 3))
            ground.append(FHDGroundItem(item: FHDItem(defID: FHDCatalog.gold.id, quantity: amt), pos: p))
        }
        _ = w; _ = h
    }

    static func rollLoot(floor: Int, rng: inout FHDRandom) -> FHDItem {
        let roll = rng.double()
        if roll < 0.26 {
            // potion
            let d = FHDCatalog.potions[rng.int(0..<FHDCatalog.potions.count)]
            return FHDItem(defID: d.id)
        } else if roll < 0.48 {
            let d = FHDCatalog.scrolls[rng.int(0..<FHDCatalog.scrolls.count)]
            return FHDItem(defID: d.id)
        } else if roll < 0.62 {
            // weapon appropriate to depth
            let tier = min(FHDCatalog.weapons.count - 1, max(0, floor / 3 + rng.int(0...2)))
            let d = FHDCatalog.weapons[tier]
            return FHDItem(defID: d.id, upgrade: rng.int(0...min(2, d.maxUpgrade)))
        } else if roll < 0.74 {
            let tier = min(FHDCatalog.armors.count - 1, max(0, floor / 4 + rng.int(0...2)))
            let d = FHDCatalog.armors[tier]
            return FHDItem(defID: d.id, upgrade: rng.int(0...min(2, d.maxUpgrade)))
        } else if roll < 0.82 {
            let d = FHDCatalog.rings[rng.int(0..<FHDCatalog.rings.count)]
            return FHDItem(defID: d.id, upgrade: rng.int(0...1))
        } else if roll < 0.90 {
            let d = FHDCatalog.wands[rng.int(0..<FHDCatalog.wands.count)]
            return FHDItem(defID: d.id, chargesLeft: d.charges)
        } else if roll < 0.96 {
            let d = FHDCatalog.throwables[rng.int(0..<FHDCatalog.throwables.count)]
            return FHDItem(defID: d.id, quantity: rng.int(1...3))
        } else {
            let d = FHDCatalog.foods[rng.int(0..<FHDCatalog.foods.count)]
            return FHDItem(defID: d.id, quantity: rng.int(1...2))
        }
    }

    // MARK: BFS

    static func bfsReachable(tiles: [[FHDTile]], from: FHDPoint, to: FHDPoint, w: Int, h: Int) -> Bool {
        if from == to { return true }
        var visited = Array(repeating: Array(repeating: false, count: w), count: h)
        var queue = [from]
        visited[from.y][from.x] = true
        var head = 0
        while head < queue.count {
            let cur = queue[head]; head += 1
            for d in FHDDir.allCases {
                let np = cur + d.delta
                if !inBounds(np, w, h) || visited[np.y][np.x] { continue }
                if !tiles[np.y][np.x].type.isWalkable { continue }
                if np == to { return true }
                visited[np.y][np.x] = true
                queue.append(np)
            }
        }
        return false
    }

    static func bfsRegion(tiles: [[FHDTile]], from: FHDPoint, w: Int, h: Int) -> [FHDPoint] {
        var visited = Array(repeating: Array(repeating: false, count: w), count: h)
        var queue = [from]; var out = [from]
        visited[from.y][from.x] = true
        var head = 0
        while head < queue.count {
            let cur = queue[head]; head += 1
            for d in FHDDir.allCases {
                let np = cur + d.delta
                if !inBounds(np, w, h) || visited[np.y][np.x] { continue }
                if !tiles[np.y][np.x].type.isWalkable { continue }
                visited[np.y][np.x] = true
                queue.append(np); out.append(np)
            }
        }
        return out
    }

    static func fallbackFloor(floor: Int, biome: FHDBiome, seed: UInt64) -> FHDFloorData {
        let w = FHDConst.mapW, h = FHDConst.mapH
        var tiles = Array(repeating: Array(repeating: FHDTile(type: .wall), count: w), count: h)
        // big open room
        for y in 2..<(h - 2) { for x in 2..<(w - 2) { tiles[y][x].type = .floor } }
        let start = FHDPoint(x: 4, y: h / 2)
        let down = FHDPoint(x: w - 5, y: h / 2)
        tiles[start.y][start.x].type = .stairsUp
        tiles[down.y][down.x].type = .stairsDown
        let rooms = [FHDRoom(x: 2, y: 2, w: w - 4, h: h - 4, kind: .entry)]
        var enemies: [FHDEnemy] = []
        if FHDConst.bossFloors.contains(floor) {
            let bid = FHDBestiary.bossForFloor[floor] ?? 100
            enemies.append(FHDEnemy(defID: bid, pos: FHDPoint(x: w / 2, y: h / 2), hp: FHDBestiary.def(bid).maxHP))
        }
        return FHDFloorData(tiles: tiles, width: w, height: h, startPos: start, downPos: down,
                            enemies: enemies, groundItems: [], rooms: rooms, biome: biome,
                            floor: floor, hasSecretRoom: false, hasHeatVault: false,
                            hasMerchant: false, lockedDoors: 0)
    }
}
