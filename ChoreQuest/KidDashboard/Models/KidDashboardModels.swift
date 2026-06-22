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
    let latestSubmissionByQuestID: [String: KidQuestSubmission]
    let familyProgress: FamilyProgressSnapshot
    let rewards: [FamilyReward]
    let rewardClaims: [RewardClaim]
    let heroXP: Int
    let heroApprovedQuestCount: Int
    let recentApprovedRewards: [KidQuestSubmission]

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

    static func resolve(from familyProfile: FamilyProfile, quests: [FamilyQuest], submissions: [KidQuestSubmission], rewards: [FamilyReward], claims: [RewardClaim], contributions: [FamilyXPContribution], selectedHeroID: String?) -> KidDashboardSnapshot? {
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

        let latestSubmissionByQuestID = submissions
            .filter { $0.heroID == hero.id }
            .sorted { ($0.createdAt ?? .distantPast) > ($1.createdAt ?? .distantPast) }
            .reduce(into: [String: KidQuestSubmission]()) { partialResult, submission in
                if partialResult[submission.questID] == nil {
                    partialResult[submission.questID] = submission
                }
            }

        let familyProgress = FamilyProgressSnapshot.resolve(
            familyProfile: familyProfile,
            submissions: submissions,
            quests: quests,
            claims: claims,
            contributions: contributions
        )

        let heroEntry = familyProgress.leaderboard.first(where: { $0.id == hero.id })
        let recentApprovedRewards = submissions
            .filter {
                $0.heroID == hero.id &&
                $0.status == .approved &&
                $0.xpAwarded() > 0
            }
            .sorted { ($0.updatedAt ?? .distantPast) > ($1.updatedAt ?? .distantPast) }
            .prefix(3)
            .map { $0 }

        return KidDashboardSnapshot(
            familyName: familyProfile.familyName,
            hero: hero,
            heroes: familyProfile.heroes,
            assignedQuests: assignedQuests,
            claimableQuests: claimableQuests,
            latestSubmissionByQuestID: latestSubmissionByQuestID,
            familyProgress: familyProgress,
            rewards: rewards.filter(\.isActive),
            rewardClaims: claims.filter { $0.heroID == hero.id }.sorted { ($0.createdAt ?? .distantPast) > ($1.createdAt ?? .distantPast) },
            heroXP: familyProgress.availableXPByHeroID[hero.id, default: 0],
            heroApprovedQuestCount: heroEntry?.completedQuestCount ?? 0,
            recentApprovedRewards: recentApprovedRewards
        )
    }
}
