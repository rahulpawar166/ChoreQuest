//
//  KidDashboardStore.swift
//  ChoreQuest
//
//  Created by Rahul Pawar on 30/05/26.
//

import Combine
import Foundation

@MainActor
final class KidDashboardStore: ObservableObject {
    @Published private(set) var quests: [FamilyQuest] = []
    @Published private(set) var isLoading = false
    @Published private(set) var isUpdatingQuest = false
    @Published var errorMessage: String?

    private let questService = ParentQuestService()

    func loadQuests(familyID: String, heroes: [HeroProfile]) async {
        isLoading = true
        defer { isLoading = false }

        do {
            quests = try await questService.loadQuests(familyID: familyID, heroes: heroes)
        } catch {
            quests = []
            errorMessage = "We couldn't load hero quests right now."
        }
    }

    func claimQuest(_ quest: FamilyQuest, hero: HeroProfile, familyID: String, heroes: [HeroProfile]) async {
        isUpdatingQuest = true
        defer { isUpdatingQuest = false }

        do {
            try await questService.claimQuest(familyID: familyID, questID: quest.id, heroID: hero.id)
            quests = try await questService.loadQuests(familyID: familyID, heroes: heroes)
        } catch {
            errorMessage = "We couldn't claim this quest right now."
        }
    }

    func rejectQuest(_ quest: FamilyQuest, familyID: String, heroes: [HeroProfile]) async {
        isUpdatingQuest = true
        defer { isUpdatingQuest = false }

        do {
            try await questService.unassignQuest(familyID: familyID, questID: quest.id)
            quests = try await questService.loadQuests(familyID: familyID, heroes: heroes)
        } catch {
            errorMessage = "We couldn't update this quest right now."
        }
    }
}
