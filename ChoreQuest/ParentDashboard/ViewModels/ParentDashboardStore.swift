//
//  ParentDashboardStore.swift
//  ChoreQuest
//
//  Created by Rahul Pawar on 30/05/26.
//

import Combine
import FirebaseFirestore
import Foundation

@MainActor
final class ParentDashboardStore: ObservableObject {
    @Published private(set) var quests: [FamilyQuest] = []
    @Published private(set) var submissions: [KidQuestSubmission] = []
    @Published private(set) var rewards: [FamilyReward] = []
    @Published private(set) var rewardClaims: [RewardClaim] = []
    @Published private(set) var pendingApprovals: [ParentApproval] = []
    @Published private(set) var isLoadingQuests = false
    @Published private(set) var isSavingQuest = false
    @Published private(set) var isUpdatingApproval = false
    @Published private(set) var isSavingReward = false
    @Published private(set) var isUpdatingClaim = false
    @Published var isPresentingCreateQuest = false
    @Published var isPresentingCreateReward = false
    @Published var errorMessage: String?

    private let questService = ParentQuestService()
    private let approvalService = ParentApprovalService()
    private let progressService = FamilyProgressService()
    private let rewardService = RewardService()
    private var submissionListener: ListenerRegistration?
    private var rewardClaimListener: ListenerRegistration?
    private var currentFamilyID: String?
    private var currentHeroes: [HeroProfile] = []

    deinit {
        submissionListener?.remove()
        rewardClaimListener?.remove()
    }

    func loadQuests(familyID: String, heroes: [HeroProfile]) async {
        isLoadingQuests = true
        defer { isLoadingQuests = false }

        startSubmissionsListenerIfNeeded(familyID: familyID, heroes: heroes)

        do {
            async let questLoad = questService.loadQuests(familyID: familyID, heroes: heroes)
            async let rewardLoad = rewardService.loadRewards(familyID: familyID)
            quests = try await questLoad
            rewards = try await rewardLoad
            rebuildApprovals()
        } catch {
            quests = []
            rewards = []
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
            rebuildApprovals()
            return true
        } catch {
            errorMessage = "We couldn't save this quest right now."
            return false
        }
    }

    func createReward(_ input: CreateRewardInput) async -> Bool {
        isSavingReward = true
        errorMessage = nil
        defer { isSavingReward = false }

        do {
            try await rewardService.createReward(input)
            rewards = try await rewardService.loadRewards(familyID: input.familyID)
            return true
        } catch {
            errorMessage = "We couldn't save this reward right now."
            return false
        }
    }

    func approve(_ approval: ParentApproval) async {
        await updateApproval(approval, status: .approved)
    }

    func reject(_ approval: ParentApproval) async {
        await updateApproval(approval, status: .rejected)
    }

    func fulfill(_ claim: RewardClaim) async {
        await updateClaim(claim, status: .fulfilled)
    }

    func reject(_ claim: RewardClaim) async {
        await updateClaim(claim, status: .rejected)
    }

    private func startSubmissionsListenerIfNeeded(familyID: String, heroes: [HeroProfile]) {
        guard let activeFamilyID = currentFamilyID else {
            currentFamilyID = familyID
            currentHeroes = heroes
            attachSubmissionsListener(familyID: familyID)
            attachRewardClaimsListener(familyID: familyID)
            return
        }

        currentHeroes = heroes

        guard activeFamilyID != familyID else {
            rebuildApprovals()
            return
        }
        submissionListener?.remove()
        rewardClaimListener?.remove()
        currentFamilyID = familyID
        attachSubmissionsListener(familyID: familyID)
        attachRewardClaimsListener(familyID: familyID)
    }

    private func attachSubmissionsListener(familyID: String) {
        submissionListener = progressService.startSubmissionsListener(familyID: familyID) { [weak self] result in
            guard let self else { return }

            Task { @MainActor in
                switch result {
                case .success(let submissions):
                    self.submissions = submissions
                    self.rebuildApprovals()
                case .failure:
                    self.errorMessage = "We couldn't load pending approvals right now."
                }
            }
        }
    }

    private func rebuildApprovals() {
        pendingApprovals = submissions
            .filter { $0.status == .pending }
            .compactMap { submission in
            guard
                let hero = currentHeroes.first(where: { $0.id == submission.heroID }),
                let quest = quests.first(where: { $0.id == submission.questID })
            else {
                return nil
            }

            return ParentApproval(
                id: submission.id,
                questID: submission.questID,
                hero: ParentAssignee(
                    name: hero.name,
                    imageBase64: hero.imageBase64,
                    avatarIconName: hero.avatarIconName,
                    avatarColorHex: hero.avatarColorHex
                ),
                heroLevelTitle: hero.levelTitle,
                choreTitle: quest.title,
                proofLabel: "Awaiting Review",
                xp: quest.xpValue,
                iconName: quest.category.iconName,
                accentHex: hero.avatarColorHex,
                proofImageBase64: submission.proofImageBase64,
                submittedAt: submission.createdAt
            )
        }
    }

    private func attachRewardClaimsListener(familyID: String) {
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

    private func updateApproval(_ approval: ParentApproval, status: KidQuestSubmissionStatus) async {
        guard let familyID = currentFamilyID else { return }

        isUpdatingApproval = true
        defer { isUpdatingApproval = false }

        do {
            try await approvalService.updateSubmissionStatus(
                familyID: familyID,
                submissionID: approval.id,
                status: status
            )
        } catch {
            errorMessage = status == .approved
                ? "We couldn't approve this proof right now."
                : "We couldn't reject this proof right now."
        }
    }

    private func updateClaim(_ claim: RewardClaim, status: RewardClaimStatus) async {
        guard let familyID = currentFamilyID else { return }
        isUpdatingClaim = true
        defer { isUpdatingClaim = false }

        do {
            try await rewardService.updateClaimStatus(familyID: familyID, claimID: claim.id, status: status)
        } catch {
            errorMessage = status == .fulfilled
                ? "We couldn't mark this reward as granted right now."
                : "We couldn't reject this reward claim right now."
        }
    }
}
