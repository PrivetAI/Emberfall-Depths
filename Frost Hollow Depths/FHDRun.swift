import Foundation

// MARK: - Enemy entity (live instance)

struct FHDEnemy: Codable, Identifiable {
    var id = UUID()
    var defID: Int
    var pos: FHDPoint
    var hp: Int
    var aware = false           // has noticed the player
    var frozenTurns = 0         // frozen / stunned
    var burningTurns = 0        // takes fire damage
    var slowTick = false        // for slow speed enemies
    var fleeing = false         // shard thief
    var stolenGold = 0
    var phase = 1               // boss phase
    var splitCount = 0          // splitter cap
    var disguised = true        // mimic until triggered
    var polymorphed = false

    var def: FHDEnemyDef { FHDBestiary.def(defID) }
}

// MARK: - Hero

struct FHDHero: Codable {
    var pos: FHDPoint = .zero
    var hp: Int = 40
    var maxHP: Int = 40
    var warmth: Int = 100
    var warmthCap: Int = 100
    var strength: Int = 3
    var classID: FHDClassID = .ranger

    // status timers (in ticks)
    var levitation = 0
    var fireImmunity = 0
    var frostWard = 0
    var haste = 0
    var regenTurns = 0
    var poison = 0
    var chill = 0           // slows the player
    var ward = 0            // damage barrier
    var braziersLeft = 3    // tinker
    var frostbiteCounter = 0

    // equipment slots (indexes into inventory items by id, or nil)
    var weapon: FHDItem?
    var armor: FHDItem?
    var ringA: FHDItem?
    var ringB: FHDItem?
    var torch: FHDItem?     // current lit torch with fuel

    var gold: Int = 0
    var keys: Int = 0
    var xp: Int = 0
    var level: Int = 1
}

// MARK: - Run state (one descent)

final class FHDRunState: Codable {
    var seed: UInt64
    var isDaily: Bool
    var floor: Int = 1
    var hero = FHDHero()
    var tiles: [[FHDTile]] = []
    var enemies: [FHDEnemy] = []
    var ground: [FHDGroundItem] = []
    var inventory: [FHDItem] = []
    var rooms: [FHDRoomCodable] = []
    var biome: FHDBiome = .frostgate
    var log: [FHDLogEntry] = []
    var turnCount = 0
    var startPos: FHDPoint = .zero
    var downPos: FHDPoint = .zero
    var alive = true
    var victory = false

    // transient (not persisted) — last thin-ice tile to crack on move-off
    var lastThinIce: FHDPoint? = nil

    // per-run identification shuffles
    var potionAppearance: [Int: Int] = [:]   // potion defID -> color index
    var scrollAppearance: [Int: Int] = [:]   // scroll defID -> rune index
    var identifiedPotion: Set<Int> = []
    var identifiedScroll: Set<Int> = []
    var triedPotion: Set<Int> = []

    // run stats
    var kills = 0
    var stepsTaken = 0
    var goldCollected = 0
    var itemsUsed = 0
    var deepestFloor = 1
    var coldestWarmth = 100
    var encounteredEnemyIDs: Set<Int> = []
    var foundItemIDs: Set<Int> = []
    var lockedDoorsOnFloor = 0
    var hasSecretRoom = false
    var hasHeatVault = false
    var hasMerchant = false

    enum CodingKeys: String, CodingKey {
        case seed, isDaily, floor, hero, tiles, enemies, ground, inventory, rooms, biome, log,
             turnCount, startPos, downPos, alive, victory,
             potionAppearance, scrollAppearance, identifiedPotion, identifiedScroll, triedPotion,
             kills, stepsTaken, goldCollected, itemsUsed, deepestFloor, coldestWarmth,
             encounteredEnemyIDs, foundItemIDs, lockedDoorsOnFloor, hasSecretRoom, hasHeatVault, hasMerchant
    }

    init(seed: UInt64, isDaily: Bool, classID: FHDClassID) {
        self.seed = seed
        self.isDaily = isDaily
        self.hero.classID = classID
        setupClass()
        rollAppearances()
    }

    required init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        seed = try c.decode(UInt64.self, forKey: .seed)
        isDaily = try c.decode(Bool.self, forKey: .isDaily)
        floor = try c.decode(Int.self, forKey: .floor)
        hero = try c.decode(FHDHero.self, forKey: .hero)
        tiles = try c.decode([[FHDTile]].self, forKey: .tiles)
        enemies = try c.decode([FHDEnemy].self, forKey: .enemies)
        ground = try c.decode([FHDGroundItem].self, forKey: .ground)
        inventory = try c.decode([FHDItem].self, forKey: .inventory)
        rooms = (try? c.decode([FHDRoomCodable].self, forKey: .rooms)) ?? []
        biome = try c.decode(FHDBiome.self, forKey: .biome)
        log = try c.decode([FHDLogEntry].self, forKey: .log)
        turnCount = try c.decode(Int.self, forKey: .turnCount)
        startPos = try c.decode(FHDPoint.self, forKey: .startPos)
        downPos = try c.decode(FHDPoint.self, forKey: .downPos)
        alive = try c.decode(Bool.self, forKey: .alive)
        victory = try c.decode(Bool.self, forKey: .victory)
        potionAppearance = try c.decode([Int: Int].self, forKey: .potionAppearance)
        scrollAppearance = try c.decode([Int: Int].self, forKey: .scrollAppearance)
        identifiedPotion = try c.decode(Set<Int>.self, forKey: .identifiedPotion)
        identifiedScroll = try c.decode(Set<Int>.self, forKey: .identifiedScroll)
        triedPotion = (try? c.decode(Set<Int>.self, forKey: .triedPotion)) ?? []
        kills = try c.decode(Int.self, forKey: .kills)
        stepsTaken = try c.decode(Int.self, forKey: .stepsTaken)
        goldCollected = try c.decode(Int.self, forKey: .goldCollected)
        itemsUsed = try c.decode(Int.self, forKey: .itemsUsed)
        deepestFloor = try c.decode(Int.self, forKey: .deepestFloor)
        coldestWarmth = try c.decode(Int.self, forKey: .coldestWarmth)
        encounteredEnemyIDs = try c.decode(Set<Int>.self, forKey: .encounteredEnemyIDs)
        foundItemIDs = try c.decode(Set<Int>.self, forKey: .foundItemIDs)
        lockedDoorsOnFloor = (try? c.decode(Int.self, forKey: .lockedDoorsOnFloor)) ?? 0
        hasSecretRoom = (try? c.decode(Bool.self, forKey: .hasSecretRoom)) ?? false
        hasHeatVault = (try? c.decode(Bool.self, forKey: .hasHeatVault)) ?? false
        hasMerchant = (try? c.decode(Bool.self, forKey: .hasMerchant)) ?? false
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(seed, forKey: .seed)
        try c.encode(isDaily, forKey: .isDaily)
        try c.encode(floor, forKey: .floor)
        try c.encode(hero, forKey: .hero)
        try c.encode(tiles, forKey: .tiles)
        try c.encode(enemies, forKey: .enemies)
        try c.encode(ground, forKey: .ground)
        try c.encode(inventory, forKey: .inventory)
        try c.encode(rooms, forKey: .rooms)
        try c.encode(biome, forKey: .biome)
        try c.encode(log, forKey: .log)
        try c.encode(turnCount, forKey: .turnCount)
        try c.encode(startPos, forKey: .startPos)
        try c.encode(downPos, forKey: .downPos)
        try c.encode(alive, forKey: .alive)
        try c.encode(victory, forKey: .victory)
        try c.encode(potionAppearance, forKey: .potionAppearance)
        try c.encode(scrollAppearance, forKey: .scrollAppearance)
        try c.encode(identifiedPotion, forKey: .identifiedPotion)
        try c.encode(identifiedScroll, forKey: .identifiedScroll)
        try c.encode(triedPotion, forKey: .triedPotion)
        try c.encode(kills, forKey: .kills)
        try c.encode(stepsTaken, forKey: .stepsTaken)
        try c.encode(goldCollected, forKey: .goldCollected)
        try c.encode(itemsUsed, forKey: .itemsUsed)
        try c.encode(deepestFloor, forKey: .deepestFloor)
        try c.encode(coldestWarmth, forKey: .coldestWarmth)
        try c.encode(encounteredEnemyIDs, forKey: .encounteredEnemyIDs)
        try c.encode(foundItemIDs, forKey: .foundItemIDs)
        try c.encode(lockedDoorsOnFloor, forKey: .lockedDoorsOnFloor)
        try c.encode(hasSecretRoom, forKey: .hasSecretRoom)
        try c.encode(hasHeatVault, forKey: .hasHeatVault)
        try c.encode(hasMerchant, forKey: .hasMerchant)
    }

    func setupClass() {
        switch hero.classID {
        case .ranger:
            hero.maxHP = 40; hero.hp = 40; hero.strength = 3
            inventory.append(FHDItem(defID: 101, upgrade: 1))   // Hunter's Bow
            inventory.append(FHDItem(defID: 201))               // Padded Furs
        case .pyreKnight:
            hero.maxHP = 50; hero.hp = 50; hero.strength = 4
            inventory.append(FHDItem(defID: 103, upgrade: 1))   // Torch-Sword
            inventory.append(FHDItem(defID: 203))               // Chain Hauberk
        case .frostWitch:
            hero.maxHP = 34; hero.hp = 34; hero.strength = 2
            inventory.append(FHDItem(defID: 100, upgrade: 1))   // Worn Dagger
            inventory.append(FHDItem(defID: 601, chargesLeft: 6)) // Wand of Frostbolt
            inventory.append(FHDItem(defID: 202))               // Leather Jerkin
        case .tinker:
            hero.maxHP = 42; hero.hp = 42; hero.strength = 3
            inventory.append(FHDItem(defID: 102))               // Iron Shortsword
            inventory.append(FHDItem(defID: 204))               // Insulated Mail
            inventory.append(FHDItem(defID: 700, quantity: 2))  // Firebombs
        }
        // Everyone gets a torch + a healing potion + rations.
        inventory.append(FHDItem(defID: FHDCatalog.torch.id, fuel: 90))
        inventory.append(FHDItem(defID: 300))
        inventory.append(FHDItem(defID: 800, quantity: 2))
    }

    func rollAppearances() {
        var rng = FHDRandom(seed: seed ^ 0xABCDEF1234567)
        let colorIdx = rng.shuffled(Array(0..<FHDCatalog.potionColors.count))
        for (i, p) in FHDCatalog.potions.enumerated() {
            potionAppearance[p.id] = colorIdx[i % colorIdx.count]
        }
        let runeIdx = rng.shuffled(Array(0..<FHDCatalog.scrollRunes.count))
        for (i, s) in FHDCatalog.scrolls.enumerated() {
            scrollAppearance[s.id] = runeIdx[i % runeIdx.count]
        }
    }

    func addLog(_ text: String, tone: Int = 0) {
        log.append(FHDLogEntry(text: text, tone: tone))
        if log.count > 60 { log.removeFirst(log.count - 60) }
    }

    // Display name for an item (respects identification).
    func displayName(_ item: FHDItem) -> String {
        let def = FHDCatalog.def(item.defID)
        if def.category == .potion && !identifiedPotion.contains(def.id) {
            let ci = potionAppearance[def.id] ?? 0
            return "\(FHDCatalog.potionColors[ci % FHDCatalog.potionColors.count]) Potion"
        }
        if def.category == .scroll && !identifiedScroll.contains(def.id) {
            let ri = scrollAppearance[def.id] ?? 0
            return "Scroll '\(FHDCatalog.scrollRunes[ri % FHDCatalog.scrollRunes.count])'"
        }
        var n = def.name
        if item.upgrade > 0 { n += " +\(item.upgrade)" }
        return n
    }
}

// Codable mirror of FHDRoom (FHDRoom holds an enum case not directly persisted everywhere).
struct FHDRoomCodable: Codable {
    var x: Int, y: Int, w: Int, h: Int, kind: Int
    init(_ r: FHDRoom) {
        x = r.x; y = r.y; w = r.w; h = r.h
        switch r.kind {
        case .normal: kind = 0
        case .secret: kind = 1
        case .heatVault: kind = 2
        case .merchant: kind = 3
        case .boss: kind = 4
        case .entry: kind = 5
        }
    }
    var cx: Int { x + w/2 }
    var cy: Int { y + h/2 }
}
