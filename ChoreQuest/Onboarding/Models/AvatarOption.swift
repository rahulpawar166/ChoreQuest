//
//  AvatarOption.swift
//  ChoreQuest
//
//  Created by Rahul Pawar on 30/05/26.
//

import Foundation

struct AvatarOption: Identifiable, Hashable {
    let id: String
    let name: String
    let iconName: String
    let colorHex: UInt

    static let all: [AvatarOption] = [
        AvatarOption(id: "fire-fox", name: "Fire Fox", iconName: "flame.fill", colorHex: 0xf97316),
        AvatarOption(id: "chill-panda", name: "Chill Panda", iconName: "moon.stars.fill", colorHex: 0x111827),
        AvatarOption(id: "brave-leo", name: "Brave Leo", iconName: "sun.max.fill", colorHex: 0xf59e0b),
        AvatarOption(id: "zen-koala", name: "Zen Koala", iconName: "cloud.fill", colorHex: 0x94a3b8),
        AvatarOption(id: "dino-dash", name: "Dino Dash", iconName: "bolt.fill", colorHex: 0x10b981),
        AvatarOption(id: "star-horn", name: "Star Horn", iconName: "sparkles", colorHex: 0xec4899),
        AvatarOption(id: "tigey", name: "Tigey", iconName: "star.fill", colorHex: 0xf97316),
        AvatarOption(id: "hop-scout", name: "Hop Scout", iconName: "leaf.fill", colorHex: 0x8b5cf6)
    ]
}
