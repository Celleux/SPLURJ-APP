import Foundation

// Bridges between UserProfile's raw storage and the Splurj enum types.
// Kept separate so UserProfile.swift doesn't need to know about UI enums.

extension UserProfile {
    var splurjVariant: SplurjVariant {
        get { SplurjVariant(rawValue: splurjVariantRaw ?? "") ?? .her }
        set { splurjVariantRaw = newValue.rawValue }
    }

    var splurjArchetype: SplurjArchetype {
        get { SplurjArchetype(rawValue: splurjArchetypeRaw ?? "") ?? .builder }
        set { splurjArchetypeRaw = newValue.rawValue }
    }

    var equippedCosmetics: Set<CosmeticID> {
        get { Set(equippedCosmeticIDs.compactMap { CosmeticID(rawValue: $0) }) }
        set { equippedCosmeticIDs = newValue.map(\.rawValue).sorted() }
    }
}
