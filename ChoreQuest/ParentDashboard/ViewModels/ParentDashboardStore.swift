//
//  ParentDashboardStore.swift
//  ChoreQuest
//
//  Created by Rahul Pawar on 30/05/26.
//

import Combine
import Foundation

@MainActor
final class ParentDashboardStore: ObservableObject {
    @Published private(set) var quests: [FamilyQuest] = []
    @Published private(set) var isLoadingQuests = false
    @Published private(set) var isSavingQuest = false
    @Published var isPresentingCreateQuest = false
    @Published var errorMessage: String?

    private let questService = ParentQuestService()

    func loadQuests(familyID: String, heroes: [HeroProfile]) async {
        isLoadingQuests = true
        defer { isLoadingQuests = false }

        do {
            quests = try await questService.loadQuests(familyID: familyID, heroes: heroes)
        } catch {
            quests = []
            errorMessage = "We couldn't load quests from Firestore right now."
        }
    }

    func createQuest(_ input: CreateQuestInput, heroes: [HeroProfile]) async -> Bool {
        isSavingQuest = true
        errorMessage = nil
        defer { isSavingQuest = false }

        do {
            try await questService.createQuest(input)
            quests = try await questService.loadQuests(familyID: input.familyID, heroes: heroes)
            return true
        } catch {
            errorMessage = "We couldn't save this quest right now."
            return false
        }
    }
}
