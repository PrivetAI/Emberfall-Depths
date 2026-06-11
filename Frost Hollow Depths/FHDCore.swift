import Foundation

// MARK: - Geometry

struct FHDPoint: Hashable, Codable {
    var x: Int
    var y: Int
    static let zero = FHDPoint(x: 0, y: 0)
    func manhattan(to o: FHDPoint) -> Int { abs(x - o.x) + abs(y - o.y) }
    func chebyshev(to o: FHDPoint) -> Int { max(abs(x - o.x), abs(y - o.y)) }
    static func + (a: FHDPoint, b: FHDPoint) -> FHDPoint { FHDPoint(x: a.x + b.x, y: a.y + b.y) }
}

enum FHDDir: Int, CaseIterable, Codable {
    case up, down, left, right
    var delta: FHDPoint {
        switch self {
        case .up: return FHDPoint(x: 0, y: -1)
        case .down: return FHDPoint(x: 0, y: 1)
        case .left: return FHDPoint(x: -1, y: 0)
        case .right: return FHDPoint(x: 1, y: 0)
        }
    }
}

// MARK: - Seeded RNG (deterministic — a seed reproduces the floor)

struct FHDRandom: Codable {
    private var state: UInt64
    init(seed: UInt64) { self.state = seed == 0 ? 0x9E3779B97F4A7C15 : seed }

    mutating func next() -> UInt64 {
        // SplitMix64
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }

    mutating func int(_ range: Range<Int>) -> Int {
        let span = UInt64(range.upperBound - range.lowerBound)
        if span == 0 { return range.lowerBound }
        return range.lowerBound + Int(next() % span)
    }
    mutating func int(_ range: ClosedRange<Int>) -> Int {
        int(range.lowerBound..<(range.upperBound + 1))
    }
    mutating func double() -> Double { Double(next() >> 11) * (1.0 / 9007199254740992.0) }
    mutating func chance(_ p: Double) -> Bool { double() < p }
    mutating func element<T>(_ arr: [T]) -> T { arr[int(0..<arr.count)] }
    mutating func shuffled<T>(_ arr: [T]) -> [T] {
        var a = arr
        if a.count < 2 { return a }
        for i in stride(from: a.count - 1, to: 0, by: -1) {
            let j = int(0...i)
            a.swapAt(i, j)
        }
        return a
    }
}

// MARK: - Tiles

enum FHDTileType: Int, Codable {
    case wall
    case floor
    case door
    case lockedDoor
    case stairsDown
    case stairsUp
    case thinIce      // cracks after stepping
    case crackedIce   // broken — becomes water hazard
    case water        // drains warmth
    case lava         // restores warmth, damages
    case brazier      // warmth source
    case frostSpore   // drains warmth + slows
    case steamJet     // periodic burst
    case meltwater    // slows
    case heatVault    // big warmth refill (floor variant)
    case secretWall   // looks like wall, reveals on adjacency
    case merchantPad

    var blocksMove: Bool { self == .wall || self == .secretWall || self == .lockedDoor }
    var blocksSight: Bool { self == .wall || self == .secretWall }
    var isWalkable: Bool { !blocksMove }
}

struct FHDTile: Codable {
    var type: FHDTileType
    var discovered: Bool = false
    var visible: Bool = false
}

// MARK: - Affinity

enum FHDAffinity: Int, Codable {
    case neutral
    case fire   // warms you when adjacent, hits hard
    case frost  // drains warmth
}

// MARK: - Class

enum FHDClassID: Int, Codable, CaseIterable {
    case ranger
    case pyreKnight
    case frostWitch
    case tinker

    var name: String {
        switch self {
        case .ranger: return "Ranger"
        case .pyreKnight: return "Pyre-Knight"
        case .frostWitch: return "Frost-Witch"
        case .tinker: return "Tinker"
        }
    }
    var tagline: String {
        switch self {
        case .ranger: return "Balanced survivor. Reliable bow, steady warmth."
        case .pyreKnight: return "A living ember. Aura keeps warmth from falling."
        case .frostWitch: return "Weaponizes the cold. Immune to frost drain."
        case .tinker: return "Builds portable braziers and salvages scrap."
        }
    }
    var perk: String {
        switch self {
        case .ranger: return "Eagle Eye: +1 light radius, ranged shots cost no extra tick."
        case .pyreKnight: return "Ember Aura: warmth drains 40% slower; adjacent enemies singe."
        case .frostWitch: return "Cold Blood: frost tiles & auras don't drain you; chill enemies on hit."
        case .tinker: return "Field Forge: deploy a brazier (3/run) that radiates warmth."
        }
    }
}

// MARK: - Message log entry

struct FHDLogEntry: Codable, Identifiable {
    var id = UUID()
    var text: String
    var tone: Int // 0 neutral,1 warm,2 cold,3 danger,4 good
}

// MARK: - Constants

enum FHDConst {
    static let mapW = 48
    static let mapH = 40
    static let baseWarmthCap = 100
    static let baseLight = 5
    static let totalFloors = 30
    static let bossFloors: Set<Int> = [5, 10, 15, 20, 25, 30]
    static let merchantFloors: Set<Int> = [4, 10, 16, 22, 28]
}
