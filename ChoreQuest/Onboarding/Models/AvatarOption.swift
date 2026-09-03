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
    let imageName: String?

    init(
        id: String,
        name: String,
        iconName: String,
        colorHex: UInt,
        imageName: String? = nil
    ) {
        self.id = id
        self.name = name
        self.iconName = iconName
        self.colorHex = colorHex
        self.imageName = imageName
    }

    static let all: [AvatarOption] = [
        AvatarOption(id: "kid-spark-scout", name: "Spark Scout", iconName: "sparkles", colorHex: 0x22c55e, imageName: "KidSparkScout"),
        AvatarOption(id: "kid-bubble-bot", name: "Bubble Bot", iconName: "cpu.fill", colorHex: 0x06b6d4, imageName: "KidBubbleBot"),
        AvatarOption(id: "kid-clay-champ", name: "Clay Champ", iconName: "face.smiling.fill", colorHex: 0xf97316, imageName: "KidClayChamp"),
        AvatarOption(id: "kid-critter-captain", name: "Critter Captain", iconName: "star.fill", colorHex: 0x84cc16, imageName: "KidCritterCaptain"),
        AvatarOption(id: "kid-cutout-comet", name: "Cutout Comet", iconName: "paperplane.fill", colorHex: 0xec4899, imageName: "KidCutoutComet"),
        AvatarOption(id: "kid-doodle-dash", name: "Doodle Dash", iconName: "scribble.variable", colorHex: 0xa855f7, imageName: "KidDoodleDash"),
        AvatarOption(id: "kid-sprout-sprite", name: "Sprout Sprite", iconName: "leaf.fill", colorHex: 0x10b981, imageName: "KidSproutSprite"),
        AvatarOption(id: "kid-sprout-spark", name: "Sprout Spark", iconName: "leaf.circle.fill", colorHex: 0x14b8a6, imageName: "KidSproutSpark"),
        AvatarOption(id: "kid-sprout-star", name: "Sprout Star", iconName: "star.circle.fill", colorHex: 0x65a30d, imageName: "KidSproutStar"),
        AvatarOption(id: "kid-voxel-voyager", name: "Voxel Voyager", iconName: "cube.fill", colorHex: 0x6366f1, imageName: "KidVoxelVoyager"),
        AvatarOption(id: "kid-voxel-champ", name: "Voxel Champ", iconName: "cube.transparent.fill", colorHex: 0x3b82f6, imageName: "KidVoxelChamp"),
        AvatarOption(id: "kid-voxel-rocket", name: "Voxel Rocket", iconName: "rocket.fill", colorHex: 0xef4444, imageName: "KidVoxelRocket"),
        AvatarOption(id: "kid-voxel-ranger", name: "Voxel Ranger", iconName: "flag.fill", colorHex: 0xf59e0b, imageName: "KidVoxelRanger"),
        AvatarOption(id: "kid-voxel-rebel", name: "Voxel Rebel", iconName: "bolt.fill", colorHex: 0x8b5cf6, imageName: "KidVoxelRebel")
    ]

    static func avatar(for id: String) -> AvatarOption {
        all.first(where: { $0.id == id }) ?? all[0]
    }
}

struct LocalAvatarOption: Identifiable, Hashable {
    let id: String
    let name: String
    let imageName: String
    let colorHex: UInt

    static let parents: [LocalAvatarOption] = [
        LocalAvatarOption(id: "parent-quest-captain", name: "Quest Captain", imageName: "ParentQuestCaptain", colorHex: 0x2563eb),
        LocalAvatarOption(id: "parent-star-commander", name: "Star Commander", imageName: "ParentStarCommander", colorHex: 0xf59e0b),
        LocalAvatarOption(id: "parent-home-hero", name: "Home Hero", imageName: "ParentHomeHero", colorHex: 0x16a34a),
        LocalAvatarOption(id: "parent-crest-keeper", name: "Crest Keeper", imageName: "ParentCrestKeeper", colorHex: 0x7c3aed),
        LocalAvatarOption(id: "parent-reward-ranger", name: "Reward Ranger", imageName: "ParentRewardRanger", colorHex: 0xdc2626),
        LocalAvatarOption(id: "parent-task-titan", name: "Task Titan", imageName: "ParentTaskTitan", colorHex: 0x0f766e),
        LocalAvatarOption(id: "parent-rally-captain", name: "Rally Captain", imageName: "ParentRallyCaptain", colorHex: 0xea580c),
        LocalAvatarOption(id: "parent-quest-mentor", name: "Quest Mentor", imageName: "ParentQuestMentor", colorHex: 0x0891b2),
        LocalAvatarOption(id: "parent-progress-pilot", name: "Progress Pilot", imageName: "ParentProgressPilot", colorHex: 0x4f46e5),
        LocalAvatarOption(id: "parent-hearth-guardian", name: "Hearth Guardian", imageName: "ParentHearthGuardian", colorHex: 0xbe123c),
        LocalAvatarOption(id: "parent-nova-guide", name: "Nova Guide", imageName: "ParentNovaGuide", colorHex: 0x9333ea),
        LocalAvatarOption(id: "parent-kindred-chief", name: "Kindred Chief", imageName: "ParentKindredChief", colorHex: 0x15803d),
        LocalAvatarOption(id: "parent-badge-boss", name: "Badge Boss", imageName: "ParentBadgeBoss", colorHex: 0xd97706),
        LocalAvatarOption(id: "parent-pixel-patron", name: "Pixel Patron", imageName: "ParentPixelPatron", colorHex: 0x475569),
        LocalAvatarOption(id: "parent-arcade-anchor", name: "Arcade Anchor", imageName: "ParentArcadeAnchor", colorHex: 0x0d9488)
    ]
}
