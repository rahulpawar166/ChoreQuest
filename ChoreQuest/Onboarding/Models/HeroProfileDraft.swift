//
//  HeroProfileDraft.swift
//  ChoreQuest
//
//  Created by Rahul Pawar on 30/05/26.
//

import Foundation

struct HeroProfileDraft: Identifiable, Hashable {
    let id: UUID
    var name: String
    var avatar: AvatarOption
    var imageData: Data?
    var levelTitle: String

    init(
        id: UUID = UUID(),
        name: String = "",
        avatar: AvatarOption = AvatarOption.all.first ?? AvatarOption(id: "swift-hare", name: "Swift Hare", iconName: "hare.fill", colorHex: 0xf97316),
        imageData: Data? = nil,
        levelTitle: String = "Level 1 Scout"
    ) {
        self.id = id
        self.name = name
        self.avatar = avatar
        self.imageData = imageData
        self.levelTitle = levelTitle
    }
}
