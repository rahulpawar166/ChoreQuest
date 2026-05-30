//
//  KidDashboardModels.swift
//  ChoreQuest
//
//  Created by Rahul Pawar on 30/05/26.
//

import Foundation

struct KidDashboardSnapshot {
    let familyName: String
    let hero: HeroProfile
    let heroes: [HeroProfile]
    let assignedQuests: [FamilyQuest]
    let claimableQuests: [FamilyQuest]

    var displayFamilyName: String {
        let trimmed = familyName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Family Squad" : trimmed
    }

    var assignedQuestCount: Int {
        assignedQuests.count
    }

    var claimableQuestCount: Int {
        claimableQuests.count
    }

    static func resolve(from familyProfile: FamilyProfile, quests: [FamilyQuest], selectedHeroID: String?) -> KidDashboardSnapshot? {
        let hero = familyProfile.heroes.first(where: { $0.id == selectedHeroID }) ?? familyProfile.heroes.first
        guard let hero else {
            return nil
        }

        let assignedQuests = quests.filter { quest in
            switch quest.assignment {
            case .everyone:
                return true
            case .hero(let assignedHero):
                return assignedHero.id == hero.id
            case .unassigned:
                return false
            }
        }

        let claimableQuests = quests.filter {
            if case .unassigned = $0.assignment {
                return true
            }
            return false
        }

        return KidDashboardSnapshot(
            familyName: familyProfile.familyName,
            hero: hero,
            heroes: familyProfile.heroes,
            assignedQuests: assignedQuests,
            claimableQuests: claimableQuests
        )
    }
}
