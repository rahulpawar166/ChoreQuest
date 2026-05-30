//
//  FamilyProgressModels.swift
//  ChoreQuest
//
//  Created by Rahul Pawar on 30/05/26.
//

import Foundation

struct FamilyProgressSnapshot {
    let rewardProgress: FamilyRewardProgress
    let leaderboard: [FamilyLeaderboardEntry]
    let availableXPByHeroID: [String: Int]

    static let empty = FamilyProgressSnapshot(
        rewardProgress: FamilyRewardProgress(title: "Pizza Night", currentXP: 0, goalXP: 5000),
        leaderboard: [],
        availableXPByHeroID: [:]
    )

    static func resolve(familyProfile: FamilyProfile, submissions: [KidQuestSubmission], quests: [FamilyQuest] = [], claims: [RewardClaim] = []) -> FamilyProgressSnapshot {
        let approvedSubmissions = submissions.filter { $0.status == .approved }
        let questXPByID = Dictionary(uniqueKeysWithValues: quests.map { ($0.id, $0.xpValue) })
        let activeClaims = claims.filter { $0.status != .rejected }

        let xpByHeroID = approvedSubmissions.reduce(into: [String: Int]()) { partialResult, submission in
            partialResult[submission.heroID, default: 0] += submission.xpAwarded(fallbackXP: questXPByID[submission.questID] ?? 0)
        }
        let spentXPByHeroID = activeClaims.reduce(into: [String: Int]()) { partialResult, claim in
            partialResult[claim.heroID, default: 0] += claim.rewardCostXP
        }

        let approvedCountByHeroID = approvedSubmissions.reduce(into: [String: Int]()) { partialResult, submission in
            partialResult[submission.heroID, default: 0] += 1
        }
        let availableXPByHeroID = familyProfile.heroes.reduce(into: [String: Int]()) { partialResult, hero in
            partialResult[hero.id] = max(xpByHeroID[hero.id, default: 0] - spentXPByHeroID[hero.id, default: 0], 0)
        }

        let leaderboard = familyProfile.heroes.map { hero in
            FamilyLeaderboardEntry(
                id: hero.id,
                name: hero.name,
                levelTitle: hero.levelTitle,
                imageBase64: hero.imageBase64,
                avatarIconName: hero.avatarIconName,
                avatarColorHex: hero.avatarColorHex,
                totalXP: availableXPByHeroID[hero.id, default: 0],
                completedQuestCount: approvedCountByHeroID[hero.id, default: 0]
            )
        }
        .sorted {
            if $0.totalXP == $1.totalXP {
                if $0.completedQuestCount == $1.completedQuestCount {
                    return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
                }

                return $0.completedQuestCount > $1.completedQuestCount
            }

            return $0.totalXP > $1.totalXP
        }
        .enumerated()
        .map { index, entry in
            var updatedEntry = entry
            updatedEntry.rank = index + 1
            return updatedEntry
        }

        let familyXP = leaderboard.reduce(0) { $0 + $1.totalXP }

        return FamilyProgressSnapshot(
            rewardProgress: FamilyRewardProgress(title: "Pizza Night", currentXP: familyXP, goalXP: 5000),
            leaderboard: leaderboard,
            availableXPByHeroID: availableXPByHeroID
        )
    }
}

struct FamilyRewardProgress {
    let title: String
    let currentXP: Int
    let goalXP: Int

    var progress: Double {
        guard goalXP > 0 else { return 0 }
        return min(Double(currentXP) / Double(goalXP), 1)
    }

    var remainingXP: Int {
        max(goalXP - currentXP, 0)
    }
}

struct FamilyLeaderboardEntry: Identifiable, Hashable {
    let id: String
    let name: String
    let levelTitle: String
    let imageBase64: String?
    let avatarIconName: String
    let avatarColorHex: UInt
    let totalXP: Int
    let completedQuestCount: Int
    var rank: Int = 0
}

extension KidQuestSubmission {
    func xpAwarded(fallbackXP: Int = 0) -> Int {
        questXPValue ?? fallbackXP
    }
}
