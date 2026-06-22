//
//  ParentDashboardModels.swift
//  ChoreQuest
//
//  Created by Rahul Pawar on 30/05/26.
//

import Foundation

enum ParentDashboardTab: String, CaseIterable, Identifiable {
    case quests
    case approvals
    case heroes
    case settings

    var id: String { rawValue }

    var navigationTitle: String {
        switch self {
        case .quests: return "Chore Quest"
        case .approvals: return "Approvals"
        case .heroes: return "Heroes"
        case .settings: return "Settings"
        }
    }
}

struct ParentDashboardSnapshot {
    let familyName: String
    let crestName: String
    let parentImageBase64: String?
    let statCards: [ParentDashboardStat]
    let activeQuests: [FamilyQuest]
    let pendingApprovals: [ParentApproval]
    let pendingRewardClaims: [RewardClaim]
    let availableRewards: [FamilyReward]
    let awaitingApprovalQuestIDs: Set<String>
    let familyProgress: FamilyProgressSnapshot
    let heroes: [ParentHeroSummary]
    let familyStats: ParentFamilyStats

    init(familyProfile: FamilyProfile, quests: [FamilyQuest], pendingApprovals: [ParentApproval] = [], pendingRewardClaims: [RewardClaim] = [], availableRewards: [FamilyReward] = [], familyProgress: FamilyProgressSnapshot = .empty) {
        familyName = familyProfile.familyName
        crestName = familyProfile.crestName
        parentImageBase64 = familyProfile.parentImageBase64

        heroes = familyProfile.heroes.map { hero in
            ParentHeroSummary(
                id: hero.id,
                name: hero.name,
                heroTitle: hero.heroTitle,
                avatarIconName: hero.avatarIconName,
                avatarColorHex: hero.avatarColorHex,
                imageBase64: hero.imageBase64
            )
        }

        activeQuests = quests
        self.pendingApprovals = pendingApprovals
        self.pendingRewardClaims = pendingRewardClaims
        self.availableRewards = availableRewards
        awaitingApprovalQuestIDs = Set(pendingApprovals.map(\.questID))
        self.familyProgress = familyProgress
        let notificationCount = pendingApprovals.count + pendingRewardClaims.count

        statCards = [
            ParentDashboardStat(
                title: "Active Quests",
                subtitle: "Live quest records loaded from Firestore.",
                value: "\(quests.count)",
                iconName: "checklist",
                accentHex: 0x630ed4,
                badgeText: nil
            ),
            ParentDashboardStat(
                title: "Pending Review",
                subtitle: "Proofs and reward claims waiting for your decision.",
                value: "\(notificationCount)",
                iconName: "bell.badge.fill",
                accentHex: 0xffc329,
                badgeText: notificationCount == 0 ? nil : "\(notificationCount) New"
            )
        ]

        familyStats = ParentFamilyStats(
            heroCount: heroes.count,
            crestName: crestName,
            familyName: familyName
        )
    }

    var displayFamilyName: String {
        let trimmed = familyName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Your Family Squad" : trimmed
    }

}

struct ParentDashboardStat: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let value: String
    let iconName: String
    let accentHex: UInt
    let badgeText: String?
}

enum ParentQuestStatus {
    case assigned
    case inProgress
    case awaitingProof
    case open

    var title: String {
        switch self {
        case .assigned:
            return "Assigned"
        case .inProgress:
            return "In Progress"
        case .awaitingProof:
            return "Awaiting Review"
        case .open:
            return "Unassigned"
        }
    }
}

struct ParentApproval: Identifiable {
    let id: String
    let questID: String
    let hero: ParentAssignee
    let heroTitle: String
    let choreTitle: String
    let proofLabel: String
    let xp: Int
    let iconName: String
    let accentHex: UInt
    let proofImageBase64: String
    let submittedAt: Date?
}

struct ParentAssignee {
    let name: String
    let imageBase64: String?
    let avatarIconName: String
    let avatarColorHex: UInt
}

struct ParentHeroSummary: Identifiable {
    let id: String
    let name: String
    let heroTitle: String
    let avatarIconName: String
    let avatarColorHex: UInt
    let imageBase64: String?
}

struct ParentFamilyStats {
    let heroCount: Int
    let crestName: String
    let familyName: String
}
