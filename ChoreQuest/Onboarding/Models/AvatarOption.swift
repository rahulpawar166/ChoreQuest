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
        AvatarOption(id: "swift-hare", name: "Swift Hare", iconName: "hare.fill", colorHex: 0xf97316),
        AvatarOption(id: "steady-tortoise", name: "Steady Tortoise", iconName: "tortoise.fill", colorHex: 0x0f766e),
        AvatarOption(id: "lucky-ladybug", name: "Lucky Ladybug", iconName: "ladybug.fill", colorHex: 0xdc2626),
        AvatarOption(id: "playful-paw", name: "Playful Paw", iconName: "pawprint.fill", colorHex: 0x7c3aed),
        AvatarOption(id: "brave-ant", name: "Brave Ant", iconName: "ant.fill", colorHex: 0x1f2937),
        AvatarOption(id: "wave-fish", name: "Wave Fish", iconName: "fish.fill", colorHex: 0x2563eb)
    ]

    static func avatar(for id: String) -> AvatarOption {
        all.first(where: { $0.id == id }) ?? all[0]
    }
}
