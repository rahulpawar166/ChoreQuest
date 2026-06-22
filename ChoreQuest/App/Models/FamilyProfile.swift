//
//  FamilyProfile.swift
//  ChoreQuest
//
//  Created by Rahul Pawar on 30/05/26.
//

struct FamilyProfile {
    let id: String
    let familyName: String
    let crestName: String
    let parentImageBase64: String?
    let familyReward: FamilyGoalReward?
    let heroes: [HeroProfile]
}

struct FamilyGoalReward: Hashable {
    let id: String
    let title: String
    let goalXP: Int
}

struct HeroProfile: Identifiable, Hashable {
    let id: String
    let name: String
    let avatarID: String
    let avatarName: String
    let avatarIconName: String
    let avatarColorHex: UInt
    let imageBase64: String?
    let levelTitle: String
}
