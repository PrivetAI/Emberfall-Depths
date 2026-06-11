import Foundation

// MARK: - AI behavior kinds

enum FHDAIKind: Int, Codable {
    case chase          // walk toward player, melee
    case rangedKiter    // shoot from range, back away when close
    case ambushIce      // hides on ice tiles, lunges when adjacent
    case packHunter     // bolder when allies near
    case frostDrainer   // drains warmth in a radius
    case iceMimic       // disguised as a chest until approached
    case shardThief     // steals gold then flees
    case wendigo        // speeds up when player is cold
    case sentry         // immobile until player in sight, then ranged
    case erratic        // moves randomly, dangerous melee
    case healer         // heals nearby allies, avoids player
    case splitter       // splits into two when hit (capped)
    case bossPattern    // driven by boss script
}

struct FHDEnemyDef: Codable {
    var id: Int
    var name: String
    var glyph: FHDGlyphKind
    var maxHP: Int
    var damage: Int
    var defense: Int
    var ai: FHDAIKind
    var affinity: FHDAffinity
    var sight: Int
    var speed: Int          // ticks per move: 1 normal, 2 = moves every other tick (slow)
    var xp: Int
    var warmthDrain: Int    // per-tick drain if frost aura / adjacency
    var rangedRange: Int
    var desc: String
    var isBoss: Bool = false
}

enum FHDBestiary {
    static let list: [FHDEnemyDef] = [
        // --- Frostgate Halls (1-5) ---
        FHDEnemyDef(id: 1, name: "Frost Rat", glyph: .skull, maxHP: 6, damage: 3, defense: 0,
                    ai: .erratic, affinity: .frost, sight: 5, speed: 1, xp: 2, warmthDrain: 0, rangedRange: 0,
                    desc: "Vermin of the upper halls. Skitters unpredictably."),
        FHDEnemyDef(id: 2, name: "Hollow Husk", glyph: .skull, maxHP: 10, damage: 4, defense: 1,
                    ai: .chase, affinity: .frost, sight: 6, speed: 1, xp: 3, warmthDrain: 0, rangedRange: 0,
                    desc: "A frozen corpse that shambles toward warmth — yours."),
        FHDEnemyDef(id: 3, name: "Icile Bat", glyph: .snow, maxHP: 7, damage: 3, defense: 0,
                    ai: .erratic, affinity: .frost, sight: 7, speed: 1, xp: 3, warmthDrain: 0, rangedRange: 0,
                    desc: "Darts erratically through the cold air."),
        FHDEnemyDef(id: 4, name: "Gate Sentinel", glyph: .shield, maxHP: 14, damage: 5, defense: 3,
                    ai: .sentry, affinity: .neutral, sight: 7, speed: 1, xp: 5, warmthDrain: 0, rangedRange: 5,
                    desc: "Stands watch, hurling ice shards at intruders."),
        FHDEnemyDef(id: 5, name: "Chillhound", glyph: .skull, maxHP: 12, damage: 6, defense: 1,
                    ai: .packHunter, affinity: .frost, sight: 8, speed: 1, xp: 4, warmthDrain: 0, rangedRange: 0,
                    desc: "Hunts in packs; bolder when its kin are near."),

        // --- Glacier Cells (6-10) ---
        FHDEnemyDef(id: 6, name: "Cell Wraith", glyph: .skull, maxHP: 16, damage: 7, defense: 2,
                    ai: .chase, affinity: .frost, sight: 7, speed: 1, xp: 6, warmthDrain: 1, rangedRange: 0,
                    desc: "A prisoner's ghost. Cold radiates from it."),
        FHDEnemyDef(id: 7, name: "Frost Drinker", glyph: .snow, maxHP: 18, damage: 4, defense: 2,
                    ai: .frostDrainer, affinity: .frost, sight: 6, speed: 1, xp: 8, warmthDrain: 3, rangedRange: 0,
                    desc: "Saps the warmth from everything around it."),
        FHDEnemyDef(id: 8, name: "Ice Mimic", glyph: .chest, maxHP: 20, damage: 9, defense: 3,
                    ai: .iceMimic, affinity: .frost, sight: 4, speed: 1, xp: 9, warmthDrain: 0, rangedRange: 0,
                    desc: "Masquerades as a frozen chest until you reach for it."),
        FHDEnemyDef(id: 9, name: "Shard Thief", glyph: .star, maxHP: 13, damage: 4, defense: 1,
                    ai: .shardThief, affinity: .neutral, sight: 8, speed: 1, xp: 7, warmthDrain: 0, rangedRange: 0,
                    desc: "Snatches your gold and bolts for the dark."),
        FHDEnemyDef(id: 10, name: "Glacier Crawler", glyph: .skull, maxHP: 22, damage: 8, defense: 4,
                    ai: .ambushIce, affinity: .frost, sight: 5, speed: 1, xp: 9, warmthDrain: 0, rangedRange: 0,
                    desc: "Lurks beneath thin ice; lunges when you draw close."),

        // --- Geothermal Forge (11-15) — fire enemies warm you but hit hard ---
        FHDEnemyDef(id: 11, name: "Ember Imp", glyph: .flame, maxHP: 16, damage: 9, defense: 1,
                    ai: .erratic, affinity: .fire, sight: 7, speed: 1, xp: 8, warmthDrain: -2, rangedRange: 0,
                    desc: "A spark of malice. Its heat warms you as it claws."),
        FHDEnemyDef(id: 12, name: "Magma Hound", glyph: .flame, maxHP: 24, damage: 11, defense: 3,
                    ai: .packHunter, affinity: .fire, sight: 8, speed: 1, xp: 11, warmthDrain: -2, rangedRange: 0,
                    desc: "Molten beast of the forge. Burns hot, bites hard."),
        FHDEnemyDef(id: 13, name: "Forge Sentry", glyph: .gear, maxHP: 26, damage: 8, defense: 6,
                    ai: .sentry, affinity: .fire, sight: 8, speed: 1, xp: 12, warmthDrain: -1, rangedRange: 6,
                    desc: "A clockwork guardian spitting gouts of flame."),
        FHDEnemyDef(id: 14, name: "Cinder Wisp", glyph: .flame, maxHP: 14, damage: 7, defense: 0,
                    ai: .rangedKiter, affinity: .fire, sight: 8, speed: 1, xp: 9, warmthDrain: -1, rangedRange: 5,
                    desc: "Floating ember that pelts you with sparks, then drifts away."),
        FHDEnemyDef(id: 15, name: "Slag Golem", glyph: .skull, maxHP: 34, damage: 13, defense: 7,
                    ai: .chase, affinity: .fire, sight: 6, speed: 2, xp: 15, warmthDrain: -1, rangedRange: 0,
                    desc: "Slow, immense, made of cooling rock."),

        // --- Crystal Abyss (16-20) ---
        FHDEnemyDef(id: 16, name: "Crystal Lurker", glyph: .snow, maxHP: 26, damage: 10, defense: 5,
                    ai: .ambushIce, affinity: .frost, sight: 5, speed: 1, xp: 13, warmthDrain: 1, rangedRange: 0,
                    desc: "Translucent stalker that blends into crystal walls."),
        FHDEnemyDef(id: 17, name: "Prism Shade", glyph: .skull, maxHP: 22, damage: 9, defense: 3,
                    ai: .rangedKiter, affinity: .frost, sight: 9, speed: 1, xp: 13, warmthDrain: 1, rangedRange: 6,
                    desc: "Refracts light into freezing lances."),
        FHDEnemyDef(id: 18, name: "Frost Mage", glyph: .wand, maxHP: 20, damage: 12, defense: 2,
                    ai: .rangedKiter, affinity: .frost, sight: 9, speed: 1, xp: 15, warmthDrain: 2, rangedRange: 7,
                    desc: "Hurls bolts of deep cold and drains the air."),
        FHDEnemyDef(id: 19, name: "Shardling", glyph: .snow, maxHP: 18, damage: 6, defense: 2,
                    ai: .splitter, affinity: .frost, sight: 6, speed: 1, xp: 10, warmthDrain: 0, rangedRange: 0,
                    desc: "Splinters into smaller shards when struck."),
        FHDEnemyDef(id: 20, name: "Abyss Warden", glyph: .shield, maxHP: 38, damage: 14, defense: 8,
                    ai: .chase, affinity: .frost, sight: 7, speed: 1, xp: 18, warmthDrain: 2, rangedRange: 0,
                    desc: "Keeper of the crystal depths. Implacable."),

        // --- The Whiteout (21-25) — warmth drains hard ---
        FHDEnemyDef(id: 21, name: "Wendigo", glyph: .skull, maxHP: 30, damage: 13, defense: 3,
                    ai: .wendigo, affinity: .frost, sight: 9, speed: 1, xp: 18, warmthDrain: 2, rangedRange: 0,
                    desc: "Starving horror that quickens when you grow cold."),
        FHDEnemyDef(id: 22, name: "Whiteout Phantom", glyph: .skull, maxHP: 24, damage: 11, defense: 4,
                    ai: .ambushIce, affinity: .frost, sight: 6, speed: 1, xp: 16, warmthDrain: 2, rangedRange: 0,
                    desc: "Lost in the blizzard, it finds you by your heat."),
        FHDEnemyDef(id: 23, name: "Hoarfrost Drinker", glyph: .snow, maxHP: 32, damage: 8, defense: 3,
                    ai: .frostDrainer, affinity: .frost, sight: 7, speed: 1, xp: 17, warmthDrain: 5, rangedRange: 0,
                    desc: "A void of warmth. Stay clear of its aura."),
        FHDEnemyDef(id: 24, name: "Blizzard Caller", glyph: .wand, maxHP: 28, damage: 13, defense: 3,
                    ai: .rangedKiter, affinity: .frost, sight: 10, speed: 1, xp: 19, warmthDrain: 3, rangedRange: 8,
                    desc: "Summons cutting winds from afar."),
        FHDEnemyDef(id: 25, name: "Pale Stalker", glyph: .skull, maxHP: 26, damage: 12, defense: 5,
                    ai: .packHunter, affinity: .frost, sight: 9, speed: 1, xp: 17, warmthDrain: 1, rangedRange: 0,
                    desc: "Hunts the half-frozen in coordinated packs."),

        // --- Heart of Winter (26-30) ---
        FHDEnemyDef(id: 26, name: "Winter Revenant", glyph: .skull, maxHP: 40, damage: 16, defense: 6,
                    ai: .chase, affinity: .frost, sight: 8, speed: 1, xp: 24, warmthDrain: 3, rangedRange: 0,
                    desc: "An old king's guard, frozen in eternal vigil."),
        FHDEnemyDef(id: 27, name: "Glacial Tyrant", glyph: .shield, maxHP: 48, damage: 17, defense: 9,
                    ai: .chase, affinity: .frost, sight: 8, speed: 1, xp: 28, warmthDrain: 3, rangedRange: 0,
                    desc: "Colossus of living ice from the frozen heart."),
        FHDEnemyDef(id: 28, name: "Soulfrost Mage", glyph: .wand, maxHP: 34, damage: 18, defense: 4,
                    ai: .rangedKiter, affinity: .frost, sight: 10, speed: 1, xp: 26, warmthDrain: 4, rangedRange: 8,
                    desc: "Channels the killing cold of the deepest depths."),
        FHDEnemyDef(id: 29, name: "Hollow Healer", glyph: .ring, maxHP: 30, damage: 6, defense: 4,
                    ai: .healer, affinity: .frost, sight: 8, speed: 1, xp: 20, warmthDrain: 2, rangedRange: 0,
                    desc: "Mends its frozen kin; cut it down first."),
        FHDEnemyDef(id: 30, name: "Frostbound Knight", glyph: .sword, maxHP: 44, damage: 19, defense: 8,
                    ai: .chase, affinity: .frost, sight: 8, speed: 1, xp: 30, warmthDrain: 2, rangedRange: 0,
                    desc: "A fallen champion bound to the long winter."),

        // --- BOSSES (6) ---
        FHDEnemyDef(id: 100, name: "Warden of the Gate", glyph: .shield, maxHP: 120, damage: 14, defense: 6,
                    ai: .bossPattern, affinity: .neutral, sight: 9, speed: 1, xp: 60, warmthDrain: 0, rangedRange: 4,
                    desc: "The first jailer. Phase two: summons sentinels.", isBoss: true),
        FHDEnemyDef(id: 101, name: "The Frozen Jailer", glyph: .skull, maxHP: 170, damage: 17, defense: 7,
                    ai: .bossPattern, affinity: .frost, sight: 9, speed: 1, xp: 90, warmthDrain: 3, rangedRange: 0,
                    desc: "Master of the Glacier Cells. Phase two: aura of bitter cold.", isBoss: true),
        FHDEnemyDef(id: 102, name: "Forgemaster Ignis", glyph: .flame, maxHP: 220, damage: 20, defense: 8,
                    ai: .bossPattern, affinity: .fire, sight: 9, speed: 1, xp: 120, warmthDrain: -3, rangedRange: 6,
                    desc: "Lord of the geothermal fires. Phase two: rains lava.", isBoss: true),
        FHDEnemyDef(id: 103, name: "The Prism Heart", glyph: .snow, maxHP: 280, damage: 22, defense: 9,
                    ai: .bossPattern, affinity: .frost, sight: 10, speed: 1, xp: 160, warmthDrain: 3, rangedRange: 7,
                    desc: "Crystalline horror of the abyss. Phase two: splits into shards.", isBoss: true),
        FHDEnemyDef(id: 104, name: "The Whiteout King", glyph: .skull, maxHP: 340, damage: 25, defense: 10,
                    ai: .bossPattern, affinity: .frost, sight: 11, speed: 1, xp: 220, warmthDrain: 5, rangedRange: 0,
                    desc: "Ruler of the endless blizzard. Phase two: blinding storm.", isBoss: true),
        FHDEnemyDef(id: 105, name: "Hibernal, Heart of Winter", glyph: .heart, maxHP: 460, damage: 28, defense: 12,
                    ai: .bossPattern, affinity: .frost, sight: 12, speed: 1, xp: 400, warmthDrain: 6, rangedRange: 8,
                    desc: "The eternal cold given form. End the long winter.", isBoss: true),
    ]

    static let byID: [Int: FHDEnemyDef] = {
        var d: [Int: FHDEnemyDef] = [:]
        for e in list { d[e.id] = e }
        return d
    }()

    static func def(_ id: Int) -> FHDEnemyDef { byID[id] ?? list[0] }

    static let bossForFloor: [Int: Int] = [5: 100, 10: 101, 15: 102, 20: 103, 25: 104, 30: 105]

    // Non-boss enemy ids available per biome (by floor band).
    static func roster(forFloor floor: Int) -> [Int] {
        switch floor {
        case 1...5: return [1, 2, 3, 4, 5]
        case 6...10: return [5, 6, 7, 8, 9, 10]
        case 11...15: return [11, 12, 13, 14, 15]
        case 16...20: return [15, 16, 17, 18, 19, 20]
        case 21...25: return [20, 21, 22, 23, 24, 25]
        default: return [25, 26, 27, 28, 29, 30]
        }
    }
}
