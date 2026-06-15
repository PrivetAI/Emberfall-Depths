import Foundation
import SwiftUI

// MARK: - Biomes

enum FHDBiome: Int, Codable, CaseIterable {
    case frostgate      // 1-5
    case glacier        // 6-10
    case forge          // 11-15
    case crystal        // 16-20
    case whiteout       // 21-25
    case heart          // 26-30

    static func forFloor(_ f: Int) -> FHDBiome {
        switch f {
        case 1...5: return .frostgate
        case 6...10: return .glacier
        case 11...15: return .forge
        case 16...20: return .crystal
        case 21...25: return .whiteout
        default: return .heart
        }
    }

    var name: String {
        switch self {
        case .frostgate: return "Frostgate Halls"
        case .glacier: return "Glacier Cells"
        case .forge: return "Geothermal Forge"
        case .crystal: return "Crystal Abyss"
        case .whiteout: return "The Whiteout"
        case .heart: return "Heart of Winter"
        }
    }

    var subtitle: String {
        switch self {
        case .frostgate: return "Floors 1-5"
        case .glacier: return "Floors 6-10"
        case .forge: return "Floors 11-15"
        case .crystal: return "Floors 16-20"
        case .whiteout: return "Floors 21-25"
        case .heart: return "Floors 26-30"
        }
    }

    // Per-tick ambient warmth modifier applied each world step.
    // Negative drains, positive restores. Forge restores; Whiteout drains hard.
    var ambientWarmth: Int {
        switch self {
        case .frostgate: return -1
        case .glacier: return -2
        case .forge: return 1
        case .crystal: return -2
        case .whiteout: return -4
        case .heart: return -3
        }
    }

    // Hazards more common in some biomes.
    var thinIceChance: Double {
        switch self {
        case .frostgate: return 0.05
        case .glacier: return 0.18
        case .forge: return 0.0
        case .crystal: return 0.12
        case .whiteout: return 0.20
        case .heart: return 0.10
        }
    }
    var lavaChance: Double { self == .forge ? 0.10 : 0.0 }
    var sporeChance: Double {
        switch self { case .crystal: return 0.06; case .heart: return 0.05; default: return 0.0 }
    }
    var steamChance: Double { self == .forge ? 0.06 : 0.0 }
    var waterChance: Double {
        switch self { case .glacier: return 0.08; case .whiteout: return 0.05; default: return 0.03 }
    }
    var brazierChance: Double { self == .forge ? 0.5 : 0.28 }

    // Palette
    var wallColor: Color {
        switch self {
        case .frostgate: return Color(red: 0.16, green: 0.21, blue: 0.32)
        case .glacier: return Color(red: 0.18, green: 0.27, blue: 0.40)
        case .forge: return Color(red: 0.26, green: 0.16, blue: 0.13)
        case .crystal: return Color(red: 0.22, green: 0.28, blue: 0.44)
        case .whiteout: return Color(red: 0.28, green: 0.33, blue: 0.42)
        case .heart: return Color(red: 0.14, green: 0.18, blue: 0.30)
        }
    }
    var floorColor: Color {
        switch self {
        case .frostgate: return Color(red: 0.09, green: 0.12, blue: 0.19)
        case .glacier: return Color(red: 0.10, green: 0.16, blue: 0.25)
        case .forge: return Color(red: 0.15, green: 0.10, blue: 0.09)
        case .crystal: return Color(red: 0.11, green: 0.15, blue: 0.26)
        case .whiteout: return Color(red: 0.17, green: 0.21, blue: 0.27)
        case .heart: return Color(red: 0.07, green: 0.10, blue: 0.18)
        }
    }
    var accentColor: Color {
        switch self {
        case .frostgate: return FHDTheme.frost
        case .glacier: return FHDTheme.iceCyan
        case .forge: return FHDTheme.torch
        case .crystal: return Color(red: 0.66, green: 0.74, blue: 1.0)
        case .whiteout: return Color(red: 0.86, green: 0.92, blue: 1.0)
        case .heart: return Color(red: 0.55, green: 0.70, blue: 1.0)
        }
    }
}

// MARK: - Floor descriptor (intro flavor)

enum FHDFloorFlavor {
    static func intro(floor: Int) -> String {
        let b = FHDBiome.forFloor(floor)
        if FHDConst.bossFloors.contains(floor) {
            switch b {
            case .frostgate: return "The Warden of the Gate bars your descent."
            case .glacier: return "The Frozen Jailer stirs in its cell."
            case .forge: return "Forgemaster Ignis guards the molten core."
            case .crystal: return "The Prism Heart pulses in the abyss."
            case .whiteout: return "The Whiteout King rules the endless storm."
            case .heart: return "Hibernal, the Heart of Winter, awaits."
            }
        }
        if FHDConst.merchantFloors.contains(floor) {
            return "A merchant has set a fire here. Warm yourself and trade."
        }
        switch b {
        case .frostgate: return "Cold stone halls. Your breath fogs the air."
        case .glacier: return "Ice-walled cells. The chill seeps into your bones."
        case .forge: return "Heat at last — molten vents warm the dark."
        case .crystal: return "Crystals refract your torchlight into a thousand cold stars."
        case .whiteout: return "Wind howls through broken walls. Warmth flees fast here."
        case .heart: return "The deepest cold. Few have walked this far."
        }
    }
}
