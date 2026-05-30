//
//  HeroHistoryModels.swift
//  ChoreQuest
//
//  Created by Rahul Pawar on 30/05/26.
//

import Foundation

struct HeroHistorySnapshot: Identifiable, Hashable {
    let id: String
    let hero: HeroProfile
    let familyName: String
    let currentAssignedQuests: [FamilyQuest]
    let questHistory: [HeroQuestHistoryItem]
    let rewardHistory: [HeroRewardHistoryItem]

    static func resolve(
        familyProfile: FamilyProfile,
        heroID: String,
        quests: [FamilyQuest],
        submissions: [KidQuestSubmission],
        claims: [RewardClaim]
    ) -> HeroHistorySnapshot? {
        guard let hero = familyProfile.heroes.first(where: { $0.id == heroID }) else {
            return nil
        }

        let currentAssignedQuests = quests.filter { quest in
            switch quest.assignment {
            case .everyone:
                return true
            case .hero(let assignedHero):
                return assignedHero.id == heroID
            case .unassigned:
                return false
            }
        }

        let questXPByID = Dictionary(uniqueKeysWithValues: quests.map { ($0.id, $0.xpValue) })

        let questHistory = submissions
            .filter { $0.heroID == heroID }
            .sorted { ($0.createdAt ?? .distantPast) > ($1.createdAt ?? .distantPast) }
            .map { submission in
                HeroQuestHistoryItem(
                    id: submission.id,
                    questTitle: submission.questTitle,
                    xpValue: submission.xpAwarded(fallbackXP: questXPByID[submission.questID] ?? 0),
                    status: submission.status,
                    proofImageBase64: submission.proofImageBase64,
                    parentComment: submission.parentComment,
                    submittedAt: submission.createdAt,
                    reviewedAt: submission.updatedAt
                )
            }

        let rewardHistory = claims
            .filter { $0.heroID == heroID }
            .sorted { ($0.createdAt ?? .distantPast) > ($1.createdAt ?? .distantPast) }
            .map { claim in
                HeroRewardHistoryItem(
                    id: claim.id,
                    rewardTitle: claim.rewardTitle,
                    rewardIconName: claim.rewardIconName,
                    costXP: claim.rewardCostXP,
                    status: claim.status,
                    parentComment: claim.parentComment,
                    claimedAt: claim.createdAt,
                    updatedAt: claim.updatedAt
                )
            }

        return HeroHistorySnapshot(
            id: hero.id,
            hero: hero,
            familyName: familyProfile.familyName,
            currentAssignedQuests: currentAssignedQuests,
            questHistory: questHistory,
            rewardHistory: rewardHistory
        )
    }

    var displayFamilyName: String {
        let trimmed = familyName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Family Squad" : trimmed
    }
}

struct HeroQuestHistoryItem: Identifiable, Hashable {
    let id: String
    let questTitle: String
    let xpValue: Int
    let status: KidQuestSubmissionStatus
    let proofImageBase64: String
    let parentComment: String?
    let submittedAt: Date?
    let reviewedAt: Date?
}

struct HeroRewardHistoryItem: Identifiable, Hashable {
    let id: String
    let rewardTitle: String
    let rewardIconName: String
    let costXP: Int
    let status: RewardClaimStatus
    let parentComment: String?
    let claimedAt: Date?
    let updatedAt: Date?
}
