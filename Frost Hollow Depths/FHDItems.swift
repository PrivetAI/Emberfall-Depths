import Foundation

// MARK: - Item taxonomy

enum FHDItemCategory: Int, Codable {
    case weapon, armor, potion, scroll, ring, wand, throwable, food, torch, fuel, gold, key, shard
}

enum FHDGlyphKind: Int, Codable {
    case sword, shield, potion, scroll, ring, wand, flame, key, heart, boot, gear, chest, bag, snow, star, skull
}

// A blueprint for an item type (catalog entry).
struct FHDItemDef: Codable {
    var id: Int
    var name: String
    var category: FHDItemCategory
    var glyph: FHDGlyphKind
    var desc: String
    // weapon/armor
    var power: Int = 0          // weapon damage or armor defense
    var insulation: Int = 0     // armor: reduces warmth drain
    var emitsWarmth: Int = 0    // torch-sword etc.: passive warmth per tick if equipped
    var affinity: FHDAffinity = .neutral
    var maxUpgrade: Int = 0
    // potion/scroll kind (effect id)
    var effect: Int = 0
    // wand
    var charges: Int = 0
    var wandRange: Int = 0
    // ring
    var ringEffect: Int = 0
    // throwable
    var throwDamage: Int = 0
    var throwEffect: Int = 0
    // food warmth/heal
    var foodWarmth: Int = 0
    var foodHeal: Int = 0
    // identification group: 0 none, 1 potion-shuffle, 2 scroll-shuffle
    var identifyGroup: Int = 0
}

// A concrete item instance in the world / inventory.
struct FHDItem: Codable, Identifiable {
    var id = UUID()
    var defID: Int
    var upgrade: Int = 0
    var quantity: Int = 1
    var chargesLeft: Int = 0
    var fuel: Int = 0           // torch fuel for the equipped torch
}

// MARK: - Effect ids

enum FHDPotionEffect: Int { case heal, warmth, strength, antidote, levitation, fireImmunity, frostWard, mightHaste, blink, regen, clarity, fullHeal }
enum FHDScrollEffect: Int { case identify, enchant, mapReveal, teleport, ignite, freezeRoom, ward, recharge, summonBrazier, vanishEnemies, removeCurse, knowledge }
enum FHDRingEffect: Int { case warmthCap, insulation, light, power, regen, evasion, greed, scholar }
enum FHDWandEffect: Int { case firebolt, frostbolt, drain, push, ember, polymorph }
enum FHDThrowEffect: Int { case firebomb, frostbomb, oilflask, smoke }

// MARK: - Catalog

enum FHDCatalog {
    // ----- WEAPONS (12) with upgrade levels -----
    static let weapons: [FHDItemDef] = [
        FHDItemDef(id: 100, name: "Worn Dagger", category: .weapon, glyph: .sword,
                   desc: "A pitted blade. Fast but weak.", power: 4, maxUpgrade: 5),
        FHDItemDef(id: 101, name: "Hunter's Bow", category: .weapon, glyph: .sword,
                   desc: "Ranged. Strikes foes from 4 tiles.", power: 5, maxUpgrade: 5, wandRange: 4),
        FHDItemDef(id: 102, name: "Iron Shortsword", category: .weapon, glyph: .sword,
                   desc: "A dependable cold-iron blade.", power: 7, maxUpgrade: 6),
        FHDItemDef(id: 103, name: "Torch-Sword", category: .weapon, glyph: .flame,
                   desc: "Its blade burns. Radiates warmth while held.", power: 8,
                   emitsWarmth: 2, affinity: .fire, maxUpgrade: 6),
        FHDItemDef(id: 104, name: "Frost Cleaver", category: .weapon, glyph: .sword,
                   desc: "Chills on hit but bites your own warmth.", power: 10,
                   affinity: .frost, maxUpgrade: 6),
        FHDItemDef(id: 105, name: "War Maul", category: .weapon, glyph: .sword,
                   desc: "Heavy. Crushing two-handed blows.", power: 13, maxUpgrade: 7),
        FHDItemDef(id: 106, name: "Ember Spear", category: .weapon, glyph: .flame,
                   desc: "Reaches 2 tiles; smolders with heat.", power: 11,
                   emitsWarmth: 1, affinity: .fire, maxUpgrade: 7),
        FHDItemDef(id: 107, name: "Glacier Pick", category: .weapon, glyph: .sword,
                   desc: "Shatters icy foes. Bonus vs frost enemies.", power: 12, maxUpgrade: 7),
        FHDItemDef(id: 108, name: "Pyre Glaive", category: .weapon, glyph: .flame,
                   desc: "A blazing polearm of the forge.", power: 15,
                   emitsWarmth: 3, affinity: .fire, maxUpgrade: 8),
        FHDItemDef(id: 109, name: "Rimewarden Axe", category: .weapon, glyph: .sword,
                   desc: "Ancient axe of the cell wardens.", power: 17, maxUpgrade: 8),
        FHDItemDef(id: 110, name: "Sunforge Blade", category: .weapon, glyph: .flame,
                   desc: "Forged in geothermal fire. Never goes cold.", power: 19,
                   emitsWarmth: 4, affinity: .fire, maxUpgrade: 9),
        FHDItemDef(id: 111, name: "Heartcleaver", category: .weapon, glyph: .sword,
                   desc: "The relic blade said to end the long winter.", power: 22, maxUpgrade: 9),
    ]

    // ----- ARMORS (8) insulation vs warmth drain -----
    static let armors: [FHDItemDef] = [
        FHDItemDef(id: 200, name: "Tattered Cloak", category: .armor, glyph: .shield,
                   desc: "Barely turns a blade. Slight warmth.", power: 1, insulation: 2, maxUpgrade: 5),
        FHDItemDef(id: 201, name: "Padded Furs", category: .armor, glyph: .shield,
                   desc: "Thick pelts trap body heat.", power: 2, insulation: 6, maxUpgrade: 5),
        FHDItemDef(id: 202, name: "Leather Jerkin", category: .armor, glyph: .shield,
                   desc: "Light and quiet.", power: 4, insulation: 3, maxUpgrade: 6),
        FHDItemDef(id: 203, name: "Chain Hauberk", category: .armor, glyph: .shield,
                   desc: "Cold metal, strong guard.", power: 7, insulation: 1, maxUpgrade: 6),
        FHDItemDef(id: 204, name: "Insulated Mail", category: .armor, glyph: .shield,
                   desc: "Quilted mail that holds warmth.", power: 8, insulation: 7, maxUpgrade: 7),
        FHDItemDef(id: 205, name: "Forgeplate", category: .armor, glyph: .shield,
                   desc: "Runs warm to the touch.", power: 11, insulation: 9,
                   emitsWarmth: 1, maxUpgrade: 7),
        FHDItemDef(id: 206, name: "Rimeguard Plate", category: .armor, glyph: .shield,
                   desc: "Warden plate of the deep cells.", power: 14, insulation: 5, maxUpgrade: 8),
        FHDItemDef(id: 207, name: "Aurora Carapace", category: .armor, glyph: .shield,
                   desc: "Glows softly; immune to frost drain.", power: 16, insulation: 14,
                   emitsWarmth: 2, maxUpgrade: 9),
    ]

    // ----- POTIONS (12) — per-run color shuffle -----
    static let potions: [FHDItemDef] = [
        FHDItemDef(id: 300, name: "Potion of Healing", category: .potion, glyph: .potion,
                   desc: "Restores a chunk of health.", effect: FHDPotionEffect.heal.rawValue, identifyGroup: 1),
        FHDItemDef(id: 301, name: "Potion of Warmth", category: .potion, glyph: .potion,
                   desc: "Floods the body with heat.", effect: FHDPotionEffect.warmth.rawValue, identifyGroup: 1),
        FHDItemDef(id: 302, name: "Potion of Strength", category: .potion, glyph: .potion,
                   desc: "Permanently raises might.", effect: FHDPotionEffect.strength.rawValue, identifyGroup: 1),
        FHDItemDef(id: 303, name: "Antidote", category: .potion, glyph: .potion,
                   desc: "Cures poison and chill.", effect: FHDPotionEffect.antidote.rawValue, identifyGroup: 1),
        FHDItemDef(id: 304, name: "Potion of Levitation", category: .potion, glyph: .potion,
                   desc: "Drift over ice and water unharmed.", effect: FHDPotionEffect.levitation.rawValue, identifyGroup: 1),
        FHDItemDef(id: 305, name: "Fire Immunity", category: .potion, glyph: .potion,
                   desc: "Walk through lava and flame.", effect: FHDPotionEffect.fireImmunity.rawValue, identifyGroup: 1),
        FHDItemDef(id: 306, name: "Frost Ward", category: .potion, glyph: .potion,
                   desc: "Stop all warmth drain for a time.", effect: FHDPotionEffect.frostWard.rawValue, identifyGroup: 1),
        FHDItemDef(id: 307, name: "Draught of Haste", category: .potion, glyph: .potion,
                   desc: "Move twice per world tick briefly.", effect: FHDPotionEffect.mightHaste.rawValue, identifyGroup: 1),
        FHDItemDef(id: 308, name: "Potion of Blink", category: .potion, glyph: .potion,
                   desc: "Teleport a short distance.", effect: FHDPotionEffect.blink.rawValue, identifyGroup: 1),
        FHDItemDef(id: 309, name: "Regeneration", category: .potion, glyph: .potion,
                   desc: "Slowly knits wounds over many turns.", effect: FHDPotionEffect.regen.rawValue, identifyGroup: 1),
        FHDItemDef(id: 310, name: "Clarity", category: .potion, glyph: .potion,
                   desc: "Reveals the floor layout.", effect: FHDPotionEffect.clarity.rawValue, identifyGroup: 1),
        FHDItemDef(id: 311, name: "Greater Healing", category: .potion, glyph: .potion,
                   desc: "Fully restores health.", effect: FHDPotionEffect.fullHeal.rawValue, identifyGroup: 1),
    ]

    // ----- SCROLLS (12) — per-run rune shuffle -----
    static let scrolls: [FHDItemDef] = [
        FHDItemDef(id: 400, name: "Scroll of Identify", category: .scroll, glyph: .scroll,
                   desc: "Reveal one unknown item.", effect: FHDScrollEffect.identify.rawValue, identifyGroup: 2),
        FHDItemDef(id: 401, name: "Scroll of Enchant", category: .scroll, glyph: .scroll,
                   desc: "Upgrade equipped weapon or armor.", effect: FHDScrollEffect.enchant.rawValue, identifyGroup: 2),
        FHDItemDef(id: 402, name: "Scroll of Mapping", category: .scroll, glyph: .scroll,
                   desc: "Chart the entire floor.", effect: FHDScrollEffect.mapReveal.rawValue, identifyGroup: 2),
        FHDItemDef(id: 403, name: "Scroll of Teleport", category: .scroll, glyph: .scroll,
                   desc: "Whisk away to a random room.", effect: FHDScrollEffect.teleport.rawValue, identifyGroup: 2),
        FHDItemDef(id: 404, name: "Scroll of Ignite", category: .scroll, glyph: .scroll,
                   desc: "Set nearby tiles and foes ablaze.", effect: FHDScrollEffect.ignite.rawValue, identifyGroup: 2),
        FHDItemDef(id: 405, name: "Scroll of Freezing", category: .scroll, glyph: .scroll,
                   desc: "Freeze every enemy in the room.", effect: FHDScrollEffect.freezeRoom.rawValue, identifyGroup: 2),
        FHDItemDef(id: 406, name: "Scroll of Warding", category: .scroll, glyph: .scroll,
                   desc: "Raise a protective barrier.", effect: FHDScrollEffect.ward.rawValue, identifyGroup: 2),
        FHDItemDef(id: 407, name: "Scroll of Recharge", category: .scroll, glyph: .scroll,
                   desc: "Restore charges to a wand.", effect: FHDScrollEffect.recharge.rawValue, identifyGroup: 2),
        FHDItemDef(id: 408, name: "Scroll of the Brazier", category: .scroll, glyph: .scroll,
                   desc: "Conjure a brazier beneath you.", effect: FHDScrollEffect.summonBrazier.rawValue, identifyGroup: 2),
        FHDItemDef(id: 409, name: "Scroll of Banishment", category: .scroll, glyph: .scroll,
                   desc: "Remove weak enemies from the floor.", effect: FHDScrollEffect.vanishEnemies.rawValue, identifyGroup: 2),
        FHDItemDef(id: 410, name: "Scroll of Cleansing", category: .scroll, glyph: .scroll,
                   desc: "Remove a curse from your gear.", effect: FHDScrollEffect.removeCurse.rawValue, identifyGroup: 2),
        FHDItemDef(id: 411, name: "Scroll of Knowledge", category: .scroll, glyph: .scroll,
                   desc: "Identify all carried items at once.", effect: FHDScrollEffect.knowledge.rawValue, identifyGroup: 2),
    ]

    // ----- RINGS (8) -----
    static let rings: [FHDItemDef] = [
        FHDItemDef(id: 500, name: "Ring of Banked Fire", category: .ring, glyph: .ring,
                   desc: "Raises your maximum Warmth.", maxUpgrade: 4, ringEffect: FHDRingEffect.warmthCap.rawValue),
        FHDItemDef(id: 501, name: "Ring of Insulation", category: .ring, glyph: .ring,
                   desc: "Slows warmth drain.", maxUpgrade: 4, ringEffect: FHDRingEffect.insulation.rawValue),
        FHDItemDef(id: 502, name: "Ring of the Lantern", category: .ring, glyph: .ring,
                   desc: "Extends your light radius.", maxUpgrade: 3, ringEffect: FHDRingEffect.light.rawValue),
        FHDItemDef(id: 503, name: "Ring of Might", category: .ring, glyph: .ring,
                   desc: "Increases damage dealt.", maxUpgrade: 4, ringEffect: FHDRingEffect.power.rawValue),
        FHDItemDef(id: 504, name: "Ring of Mending", category: .ring, glyph: .ring,
                   desc: "Slowly regenerates health.", maxUpgrade: 3, ringEffect: FHDRingEffect.regen.rawValue),
        FHDItemDef(id: 505, name: "Ring of Evasion", category: .ring, glyph: .ring,
                   desc: "Chance to dodge attacks.", maxUpgrade: 3, ringEffect: FHDRingEffect.evasion.rawValue),
        FHDItemDef(id: 506, name: "Ring of Greed", category: .ring, glyph: .ring,
                   desc: "More gold from every find.", maxUpgrade: 3, ringEffect: FHDRingEffect.greed.rawValue),
        FHDItemDef(id: 507, name: "Ring of the Scholar", category: .ring, glyph: .ring,
                   desc: "Auto-identifies items faster.", maxUpgrade: 2, ringEffect: FHDRingEffect.scholar.rawValue),
    ]

    // ----- WANDS (6) charges -----
    static let wands: [FHDItemDef] = [
        FHDItemDef(id: 600, name: "Wand of Firebolt", category: .wand, glyph: .wand,
                   desc: "Hurls a bolt of flame.", affinity: .fire,
                   effect: FHDWandEffect.firebolt.rawValue, charges: 6, wandRange: 6),
        FHDItemDef(id: 601, name: "Wand of Frostbolt", category: .wand, glyph: .wand,
                   desc: "Freezes and slows a target.", affinity: .frost,
                   effect: FHDWandEffect.frostbolt.rawValue, charges: 6, wandRange: 6),
        FHDItemDef(id: 602, name: "Wand of Draining", category: .wand, glyph: .wand,
                   desc: "Steals warmth from a foe to you.", affinity: .fire,
                   effect: FHDWandEffect.drain.rawValue, charges: 5, wandRange: 5),
        FHDItemDef(id: 603, name: "Wand of Force", category: .wand, glyph: .wand,
                   desc: "Shoves an enemy backward.", effect: FHDWandEffect.push.rawValue, charges: 7, wandRange: 5),
        FHDItemDef(id: 604, name: "Wand of Embers", category: .wand, glyph: .wand,
                   desc: "Scatters warm coals around you.", affinity: .fire,
                   effect: FHDWandEffect.ember.rawValue, charges: 4, wandRange: 3),
        FHDItemDef(id: 605, name: "Wand of Polymorph", category: .wand, glyph: .wand,
                   desc: "Turns a foe into something harmless.", effect: FHDWandEffect.polymorph.rawValue, charges: 3, wandRange: 5),
    ]

    // ----- THROWABLES (4) -----
    static let throwables: [FHDItemDef] = [
        FHDItemDef(id: 700, name: "Firebomb", category: .throwable, glyph: .flame,
                   desc: "Ignites ice and oil. Burns foes.", throwDamage: 14, throwEffect: FHDThrowEffect.firebomb.rawValue),
        FHDItemDef(id: 701, name: "Frost Bomb", category: .throwable, glyph: .snow,
                   desc: "Freezes a cluster of enemies.", throwDamage: 6, throwEffect: FHDThrowEffect.frostbomb.rawValue),
        FHDItemDef(id: 702, name: "Oil Flask", category: .throwable, glyph: .potion,
                   desc: "Spreads slick oil; ignite it later.", throwDamage: 2, throwEffect: FHDThrowEffect.oilflask.rawValue),
        FHDItemDef(id: 703, name: "Smoke Pod", category: .throwable, glyph: .potion,
                   desc: "Blinds nearby foes so you can flee.", throwDamage: 0, throwEffect: FHDThrowEffect.smoke.rawValue),
    ]

    // ----- FOOD (3) -----
    static let foods: [FHDItemDef] = [
        FHDItemDef(id: 800, name: "Dried Rations", category: .food, glyph: .heart,
                   desc: "Restores a little health and warmth.", foodWarmth: 12, foodHeal: 6),
        FHDItemDef(id: 801, name: "Spiced Stew", category: .food, glyph: .heart,
                   desc: "A warm meal. Big warmth boost.", foodWarmth: 30, foodHeal: 10),
        FHDItemDef(id: 802, name: "Frostberries", category: .food, glyph: .heart,
                   desc: "Tart fruit. Heals but slightly chills.", foodWarmth: -4, foodHeal: 14),
    ]

    // ----- UTILITY (torch, fuel, key) -----
    static let torch = FHDItemDef(id: 900, name: "Torch", category: .torch, glyph: .flame,
                                  desc: "Lights the dark and holds back the cold.", emitsWarmth: 1)
    static let fuel = FHDItemDef(id: 901, name: "Torch Fuel", category: .fuel, glyph: .flame,
                                 desc: "Refills a torch's burn time.")
    static let key = FHDItemDef(id: 902, name: "Iron Key", category: .key, glyph: .key,
                                desc: "Opens a locked door on this floor.")
    static let gold = FHDItemDef(id: 903, name: "Gold", category: .gold, glyph: .star,
                                 desc: "Spend at merchants.")
    static let shard = FHDItemDef(id: 904, name: "Frost Shard", category: .shard, glyph: .snow,
                                  desc: "Permanent meta currency.")

    // Lookup table
    static let all: [FHDItemDef] = weapons + armors + potions + scrolls + rings + wands + throwables + foods + [torch, fuel, key, gold, shard]
    static let byID: [Int: FHDItemDef] = {
        var d: [Int: FHDItemDef] = [:]
        for def in all { d[def.id] = def }
        return d
    }()

    static func def(_ id: Int) -> FHDItemDef { byID[id] ?? gold }

    // Per-run unidentified appearances.
    static let potionColors = ["Crimson", "Azure", "Murky", "Glowing", "Foaming", "Smoking",
                               "Cloudy", "Silver", "Emerald", "Violet", "Amber", "Pale"]
    static let scrollRunes = ["KEX-VAR", "OMA-THUL", "ZIR-NEH", "FEL-DUN", "WYR-LOC", "TAS-MIR",
                              "QUO-BEX", "NEL-VOTH", "GRA-SUN", "HEM-OLK", "VRA-SETH", "PYX-DAR"]
}
