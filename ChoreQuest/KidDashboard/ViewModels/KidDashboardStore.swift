//
//  KidDashboardStore.swift
//  ChoreQuest
//
//  Created by Rahul Pawar on 30/05/26.
//

import Combine
import FirebaseFirestore
import Foundation

@MainActor
final class KidDashboardStore: ObservableObject {
    @Published private(set) var quests: [FamilyQuest] = []
    @Published private(set) var submissions: [KidQuestSubmission] = []
    @Published private(set) var rewards: [FamilyReward] = []
    @Published private(set) var rewardClaims: [RewardClaim] = []
    @Published private(set) var isLoading = false
    @Published private(set) var isUpdatingQuest = false
    @Published private(set) var isSubmittingProof = false
    @Published private(set) var isClaimingReward = false
    @Published var errorMessage: String?

    private let questService = ParentQuestService()
    private let submissionService = KidQuestSubmissionService()
    private let progressService = FamilyProgressService()
    private let rewardService = RewardService()
    private var submissionListener: ListenerRegistration?
    private var rewardClaimListener: ListenerRegistration?
    private var activeFamilyID: String?

    deinit {
        submissionListener?.remove()
        rewardClaimListener?.remove()
    }

    func loadDashboard(familyID: String, heroID: String, heroes: [HeroProfile]) async {
        isLoading = true
        defer { isLoading = false }

        startRealtimeListenersIfNeeded(familyID: familyID)

        do {
            async let questLoad = questService.loadQuests(familyID: familyID, heroes: heroes)
            async let rewardLoad = rewardService.loadRewards(familyID: familyID)
            quests = try await questLoad
            rewards = try await rewardLoad
        } catch {
            quests = []
            rewards = []
            errorMessage = "We couldn't load hero quests right now."
        }
    }

    func claimQuest(_ quest: FamilyQuest, hero: HeroProfile, familyID: String, heroes: [HeroProfile]) async {
        isUpdatingQuest = true
        defer { isUpdatingQuest = false }

        do {
            try await questService.claimQuest(familyID: familyID, questID: quest.id, heroID: hero.id)
            await loadDashboard(familyID: familyID, heroID: hero.id, heroes: heroes)
        } catch {
            errorMessage = "We couldn't claim this quest right now."
        }
    }

    func rejectQuest(_ quest: FamilyQuest, heroID: String, familyID: String, heroes: [HeroProfile]) async {
        isUpdatingQuest = true
        defer { isUpdatingQuest = false }

        do {
            try await questService.unassignQuest(familyID: familyID, questID: quest.id)
            await loadDashboard(familyID: familyID, heroID: heroID, heroes: heroes)
        } catch {
            errorMessage = "We couldn't update this quest right now."
        }
    }

    func submitProof(for quest: FamilyQuest, hero: HeroProfile, proofImageData: Data, familyID: String, heroes: [HeroProfile]) async -> Bool {
        isSubmittingProof = true
        defer { isSubmittingProof = false }

        do {
            try await submissionService.submitProof(
                CreateKidQuestSubmissionInput(
                    familyID: familyID,
                    quest: quest,
                    hero: hero,
                    proofImageData: proofImageData
                )
            )
            return true
        } catch {
            errorMessage = "We couldn't send your proof right now."
            return false
        }
    }

    func claimReward(_ reward: FamilyReward, hero: HeroProfile, availableXP: Int, familyID: String) async -> Bool {
        guard availableXP >= reward.costXP else {
            errorMessage = "Not enough XP to claim this reward yet."
            return false
        }

        isClaimingReward = true
        defer { isClaimingReward = false }

        do {
            try await rewardService.claimReward(familyID: familyID, reward: reward, hero: hero)
            return true
        } catch {
            errorMessage = "We couldn't claim this reward right now."
            return false
        }
    }

    private func startRealtimeListenersIfNeeded(familyID: String) {
        guard activeFamilyID != familyID else { return }
        submissionListener?.remove()
        rewardClaimListener?.remove()
        activeFamilyID = familyID
        submissionListener = progressService.startSubmissionsListener(familyID: familyID) { [weak self] result in
            guard let self else { return }

            Task { @MainActor in
                switch result {
                case .success(let submissions):
                    self.submissions = submissions
                case .failure:
                    self.errorMessage = "We couldn't load hero rewards right now."
                }
            }
        }

        rewardClaimListener = rewardService.startClaimsListener(familyID: familyID) { [weak self] result in
            guard let self else { return }

            Task { @MainActor in
                switch result {
                case .success(let claims):
                    self.rewardClaims = claims
                case .failure:
                    self.errorMessage = "We couldn't load reward claims right now."
                }
            }
        }
    }
}
