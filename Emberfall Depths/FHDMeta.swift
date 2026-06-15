import Foundation
import SwiftUI

// MARK: - Achievements

enum FHDAchID: String, Codable, CaseIterable {
    case firstSteps, firstKill, descend5, descend10, descend15, descend20, descend25
    case boss1, boss2, boss3, boss4, boss5, boss6
    case victory, brinkOfFrost, heatVault, meetMerchant, tinkerBrazier
    case rich, packed, identifyAll, slay50, slay200
    case unlockPyre, unlockWitch, unlockTinker
    case dailyRun, codex25, survivor

    var title: String {
        switch self {
        case .firstSteps: return "First Steps"
        case .firstKill: return "Blooded"
        case .descend5: return "Beyond the Gate"
        case .descend10: return "Cell Breaker"
        case .descend15: return "Into the Forge"
        case .descend20: return "Crystal Depths"
        case .descend25: return "Through the Whiteout"
        case .boss1: return "Warden Slain"
        case .boss2: return "Jailer Slain"
        case .boss3: return "Forgemaster Slain"
        case .boss4: return "Prism Shattered"
        case .boss5: return "King Toppled"
        case .boss6: return "Winter Ended"
        case .victory: return "The Long Thaw"
        case .brinkOfFrost: return "Brink of Frost"
        case .heatVault: return "Vault of Heat"
        case .meetMerchant: return "Cold Coin"
        case .tinkerBrazier: return "Field Forge"
        case .rich: return "Hoarder"
        case .packed: return "Well-Stocked"
        case .identifyAll: return "Loremaster"
        case .slay50: return "Culler"
        case .slay200: return "Exterminator"
        case .unlockPyre: return "Embrace the Flame"
        case .unlockWitch: return "Cold Heart"
        case .unlockTinker: return "Master Builder"
        case .dailyRun: return "Daily Descent"
        case .codex25: return "Naturalist"
        case .survivor: return "Survivor"
        }
    }
    var detail: String {
        switch self {
        case .firstSteps: return "Take your first steps into the depths."
        case .firstKill: return "Defeat your first enemy."
        case .descend5: return "Reach floor 6."
        case .descend10: return "Reach floor 11."
        case .descend15: return "Reach floor 16."
        case .descend20: return "Reach floor 21."
        case .descend25: return "Reach floor 26."
        case .boss1: return "Defeat the Warden of the Gate."
        case .boss2: return "Defeat the Frozen Jailer."
        case .boss3: return "Defeat Forgemaster Ignis."
        case .boss4: return "Defeat the Prism Heart."
        case .boss5: return "Defeat the Whiteout King."
        case .boss6: return "Defeat Hibernal, Heart of Winter."
        case .victory: return "Complete a full 30-floor run."
        case .brinkOfFrost: return "Survive with Warmth at zero."
        case .heatVault: return "Discover a heat vault."
        case .meetMerchant: return "Reach a merchant."
        case .tinkerBrazier: return "Deploy a field brazier as the Tinker."
        case .rich: return "Carry 500 gold in one run."
        case .packed: return "Hold 16 items at once."
        case .identifyAll: return "Identify every potion in a run."
        case .slay50: return "Defeat 50 enemies total."
        case .slay200: return "Defeat 200 enemies total."
        case .unlockPyre: return "Unlock the Pyre-Knight."
        case .unlockWitch: return "Unlock the Frost-Witch."
        case .unlockTinker: return "Unlock the Tinker."
        case .dailyRun: return "Complete a daily seeded run."
        case .codex25: return "Discover 25 codex entries."
        case .survivor: return "Survive 500 turns in one run."
        }
    }
}

// MARK: - Meta unlock nodes

enum FHDUnlockID: String, Codable, CaseIterable {
    case classPyre, classWitch, classTinker
    case warmthCap1, warmthCap2
    case startHeal, startTorch, startArmor
    case insulation1, lightBoost
    case codexPage1, codexPage2

    var title: String {
        switch self {
        case .classPyre: return "Class: Pyre-Knight"
        case .classWitch: return "Class: Frost-Witch"
        case .classTinker: return "Class: Tinker"
        case .warmthCap1: return "Banked Fire I"
        case .warmthCap2: return "Banked Fire II"
        case .startHeal: return "Field Medic"
        case .startTorch: return "Extra Fuel"
        case .startArmor: return "Warm Layers"
        case .insulation1: return "Insulation Training"
        case .lightBoost: return "Keen Sight"
        case .codexPage1: return "Codex: Lore I"
        case .codexPage2: return "Codex: Lore II"
        }
    }
    var detail: String {
        switch self {
        case .classPyre: return "Unlock a living-ember warrior whose aura holds warmth."
        case .classWitch: return "Unlock a frost-immune caster who weaponizes the cold."
        case .classTinker: return "Unlock an engineer who deploys portable braziers."
        case .warmthCap1: return "+15 maximum Warmth on every run."
        case .warmthCap2: return "+15 more maximum Warmth (stacks)."
        case .startHeal: return "Begin each run with an extra Greater Healing potion."
        case .startTorch: return "Begin with extra torch fuel."
        case .startArmor: return "Begin with Insulated Mail."
        case .insulation1: return "Permanent +3 insulation against the cold."
        case .lightBoost: return "Permanent +1 light radius."
        case .codexPage1: return "Reveal lore pages in the codex."
        case .codexPage2: return "Reveal the final lore pages."
        }
    }
    var cost: Int {
        switch self {
        case .classPyre: return 30
        case .classWitch: return 60
        case .classTinker: return 90
        case .warmthCap1: return 20
        case .warmthCap2: return 45
        case .startHeal: return 25
        case .startTorch: return 15
        case .startArmor: return 35
        case .insulation1: return 30
        case .lightBoost: return 40
        case .codexPage1: return 10
        case .codexPage2: return 20
        }
    }
}

// MARK: - Run history record

struct FHDRunRecord: Codable, Identifiable {
    var id = UUID()
    var date: Date
    var classID: FHDClassID
    var floor: Int
    var victory: Bool
    var cause: String
    var kills: Int
    var gold: Int
    var turns: Int
    var isDaily: Bool
    var seed: UInt64
}

struct FHDDailyResult: Codable, Identifiable {
    var id = UUID()
    var dateKey: String
    var floor: Int
    var kills: Int
    var victory: Bool
}

// MARK: - Store (meta + persistence)

final class FHDStore: ObservableObject {
    @Published var shards: Int = 0
    @Published var unlocks: Set<FHDUnlockID> = []
    @Published var achievements: Set<FHDAchID> = []
    @Published var discoveredEnemies: Set<Int> = []
    @Published var identifiedItems: Set<Int> = []
    @Published var discoveredItems: Set<Int> = []
    @Published var history: [FHDRunRecord] = []
    @Published var dailyResults: [FHDDailyResult] = []
    @Published var biomesReached: Set<Int> = []

    // settings
    @Published var soundOn: Bool = true
    @Published var hapticsOn: Bool = true
    @Published var onboardingDone: Bool = false

    // global stats
    @Published var totalKills: Int = 0
    @Published var totalRuns: Int = 0
    @Published var totalWins: Int = 0
    @Published var totalGold: Int = 0
    @Published var bestFloor: Int = 0
    @Published var totalTurns: Int = 0

    // active run
    @Published var activeRun: FHDRunState? = nil

    private let d = UserDefaults.standard
    private let kPrefix = "fhd."

    init() { load() }

    // MARK: persistence

    func load() {
        shards = d.integer(forKey: kPrefix + "shards")
        unlocks = decodeCodable(kPrefix + "unlocks") ?? []
        achievements = decodeCodable(kPrefix + "achievements") ?? []
        discoveredEnemies = decodeCodable(kPrefix + "enemies") ?? []
        identifiedItems = decodeCodable(kPrefix + "idItems") ?? []
        discoveredItems = decodeCodable(kPrefix + "discItems") ?? []
        history = decodeCodable(kPrefix + "history") ?? []
        dailyResults = decodeCodable(kPrefix + "daily") ?? []
        biomesReached = decodeCodable(kPrefix + "biomes") ?? []
        soundOn = d.object(forKey: kPrefix + "sound") as? Bool ?? true
        hapticsOn = d.object(forKey: kPrefix + "haptics") as? Bool ?? true
        onboardingDone = d.bool(forKey: kPrefix + "onboard")
        totalKills = d.integer(forKey: kPrefix + "totalKills")
        totalRuns = d.integer(forKey: kPrefix + "totalRuns")
        totalWins = d.integer(forKey: kPrefix + "totalWins")
        totalGold = d.integer(forKey: kPrefix + "totalGold")
        bestFloor = d.integer(forKey: kPrefix + "bestFloor")
        totalTurns = d.integer(forKey: kPrefix + "totalTurns")
        activeRun = decodeCodable(kPrefix + "activeRun")
    }

    func saveMeta() {
        d.set(shards, forKey: kPrefix + "shards")
        encodeCodable(unlocks, kPrefix + "unlocks")
        encodeCodable(achievements, kPrefix + "achievements")
        encodeCodable(discoveredEnemies, kPrefix + "enemies")
        encodeCodable(identifiedItems, kPrefix + "idItems")
        encodeCodable(discoveredItems, kPrefix + "discItems")
        encodeCodable(history, kPrefix + "history")
        encodeCodable(dailyResults, kPrefix + "daily")
        encodeCodable(biomesReached, kPrefix + "biomes")
        d.set(soundOn, forKey: kPrefix + "sound")
        d.set(hapticsOn, forKey: kPrefix + "haptics")
        d.set(onboardingDone, forKey: kPrefix + "onboard")
        d.set(totalKills, forKey: kPrefix + "totalKills")
        d.set(totalRuns, forKey: kPrefix + "totalRuns")
        d.set(totalWins, forKey: kPrefix + "totalWins")
        d.set(totalGold, forKey: kPrefix + "totalGold")
        d.set(bestFloor, forKey: kPrefix + "bestFloor")
        d.set(totalTurns, forKey: kPrefix + "totalTurns")
    }

    func saveRun(_ run: FHDRunState) {
        encodeCodable(run, kPrefix + "activeRun")
    }

    func clearActiveRun() {
        d.removeObject(forKey: kPrefix + "activeRun")
        activeRun = nil
    }

    private func encodeCodable<T: Encodable>(_ v: T, _ key: String) {
        if let data = try? JSONEncoder().encode(v) { d.set(data, forKey: key) }
    }
    private func decodeCodable<T: Decodable>(_ key: String) -> T? {
        guard let data = d.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }
    // MARK: meta progression

    func canAfford(_ u: FHDUnlockID) -> Bool { shards >= u.cost && !unlocks.contains(u) }

    func buy(_ u: FHDUnlockID) {
        guard canAfford(u) else { return }
        shards -= u.cost
        unlocks.insert(u)
        switch u {
        case .classPyre: unlockAchievement(.unlockPyre)
        case .classWitch: unlockAchievement(.unlockWitch)
        case .classTinker: unlockAchievement(.unlockTinker)
        default: break
        }
        saveMeta()
    }

    func isClassUnlocked(_ c: FHDClassID) -> Bool {
        switch c {
        case .ranger: return true
        case .pyreKnight: return unlocks.contains(.classPyre)
        case .frostWitch: return unlocks.contains(.classWitch)
        case .tinker: return unlocks.contains(.classTinker)
        }
    }

    // Apply purchased meta bonuses to a new run.
    func applyMetaBonuses(to run: FHDRunState) {
        if unlocks.contains(.warmthCap1) { run.hero.warmthCap += 15 }
        if unlocks.contains(.warmthCap2) { run.hero.warmthCap += 15 }
        run.hero.warmth = run.hero.warmthCap
        if unlocks.contains(.startHeal) { run.inventory.append(FHDItem(defID: 311)) }
        if unlocks.contains(.startTorch) { run.inventory.append(FHDItem(defID: FHDCatalog.fuel.id, fuel: 80)) }
        if unlocks.contains(.startArmor) { run.inventory.append(FHDItem(defID: 204)) }
    }

    // MARK: achievements & codex recording

    func unlockAchievement(_ id: FHDAchID) {
        if achievements.contains(id) { return }
        achievements.insert(id)
        saveMeta()
    }

    func recordEnemyDefeated(_ id: Int, justSeen: Bool = false) {
        if !discoveredEnemies.contains(id) {
            discoveredEnemies.insert(id)
            if discoveredEnemies.count >= 25 { unlockAchievement(.codex25) }
            saveMeta()
        }
    }

    func recordItemDiscovered(_ id: Int, identified: Bool = false) {
        var changed = false
        if !discoveredItems.contains(id) { discoveredItems.insert(id); changed = true }
        if identified && !identifiedItems.contains(id) { identifiedItems.insert(id); changed = true }
        if changed { saveMeta() }
    }

    func recordBiomeReached(_ b: FHDBiome) {
        if !biomesReached.contains(b.rawValue) {
            biomesReached.insert(b.rawValue)
            saveMeta()
        }
    }

    // MARK: run lifecycle

    func startRun(classID: FHDClassID, daily: Bool) -> FHDRunState {
        let seed: UInt64
        if daily { seed = FHDStore.dailySeed() }
        else { seed = UInt64.random(in: 1...UInt64.max) }
        let run = FHDRunState(seed: seed, isDaily: daily, classID: classID)
        applyMetaBonuses(to: run)
        unlockAchievement(.firstSteps)
        activeRun = run
        return run
    }

    func finishRun(_ run: FHDRunState, victory: Bool, cause: String) {
        // award shards based on depth + kills
        let earned = run.deepestFloor * 3 + run.kills + (victory ? 50 : 0) + (run.isDaily ? 10 : 0)
        shards += earned
        totalRuns += 1
        totalKills += run.kills
        totalGold += run.goldCollected
        totalTurns += run.turnCount
        bestFloor = max(bestFloor, run.deepestFloor)
        if victory { totalWins += 1 }

        if run.goldCollected >= 500 { unlockAchievement(.rich) }
        if totalKills >= 50 { unlockAchievement(.slay50) }
        if totalKills >= 200 { unlockAchievement(.slay200) }
        if run.turnCount >= 500 { unlockAchievement(.survivor) }
        if run.deepestFloor >= 6 { unlockAchievement(.descend5) }
        if run.deepestFloor >= 11 { unlockAchievement(.descend10) }
        if run.deepestFloor >= 16 { unlockAchievement(.descend15) }
        if run.deepestFloor >= 21 { unlockAchievement(.descend20) }
        if run.deepestFloor >= 26 { unlockAchievement(.descend25) }
        if run.kills >= 1 { unlockAchievement(.firstKill) }
        if run.identifiedPotion.count >= FHDCatalog.potions.count { unlockAchievement(.identifyAll) }
        if run.isDaily { unlockAchievement(.dailyRun) }

        let rec = FHDRunRecord(date: Date(), classID: run.hero.classID, floor: run.deepestFloor,
                               victory: victory, cause: cause, kills: run.kills, gold: run.goldCollected,
                               turns: run.turnCount, isDaily: run.isDaily, seed: run.seed)
        history.insert(rec, at: 0)
        if history.count > 100 { history.removeLast(history.count - 100) }

        if run.isDaily {
            let key = FHDStore.dailyKey()
            dailyResults.removeAll { $0.dateKey == key }
            dailyResults.insert(FHDDailyResult(dateKey: key, floor: run.deepestFloor, kills: run.kills, victory: victory), at: 0)
            if dailyResults.count > 30 { dailyResults.removeLast(dailyResults.count - 30) }
        }

        clearActiveRun()
        saveMeta()
    }

    // MARK: stats

    func packedCheck(_ count: Int) { if count >= 16 { unlockAchievement(.packed) } }

    func resetAll() {
        shards = 0; unlocks = []; achievements = []; discoveredEnemies = []
        identifiedItems = []; discoveredItems = []; history = []; dailyResults = []
        biomesReached = []; totalKills = 0; totalRuns = 0; totalWins = 0
        totalGold = 0; bestFloor = 0; totalTurns = 0; onboardingDone = false
        clearActiveRun()
        saveMeta()
    }

    // MARK: daily seed

    static func dailyKey() -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = TimeZone(identifier: "UTC")
        return f.string(from: Date())
    }
    static func dailySeed() -> UInt64 {
        let key = dailyKey()
        var hash: UInt64 = 1469598103934665603
        for b in key.utf8 { hash = (hash ^ UInt64(b)) &* 1099511628211 }
        return hash
    }
    func dailyDoneToday() -> Bool {
        dailyResults.contains { $0.dateKey == FHDStore.dailyKey() }
    }
}
